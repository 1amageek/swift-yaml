/// Tokenizer that converts a YAML string into a stream of tokens.
struct Scanner {
    private let source: [Unicode.Scalar]
    private var pos: Int
    private var line: Int
    private var column: Int

    /// Stack of indentation levels for block contexts.
    private var indents: [Int]

    /// Flow nesting depth (0 = block context).
    private var flowLevel: Int

    /// Buffer of tokens ready to be returned.
    private var tokenQueue: [Token]

    /// Whether `streamStart` has been emitted.
    private var streamStarted: Bool

    /// Whether `streamEnd` has been emitted.
    private var streamEnded: Bool

    /// Tag directive handles -> prefix mapping.
    private var tagDirectives: [String: String]

    /// Whether a %YAML directive has been seen for the current document.
    private var yamlDirectiveSeen: Bool

    /// Whether we are past the directive section (after first document content or ---).
    private var documentStarted: Bool

    /// Whether a flow explicit key (?) was just emitted, suppressing implicit key detection.
    private var flowKeyPending: Bool

    /// Indent of the first node property (tag/anchor) in the current block node.
    private var pendingNodeIndent: Int?

    /// Whether the next ':' in block context should emit just value (after flow collection key).
    private var expectValueAfterFlowKey: Bool

    /// Whether adjacent ':' is allowed as value indicator in flow context
    /// (set after flow collection end or quoted scalar).
    private var adjacentValueAllowed: Bool


    init(source: String) {
        self.source = Array(source.unicodeScalars)
        self.pos = 0
        self.line = 1
        self.column = 1
        self.indents = [-1]
        self.flowLevel = 0
        self.tokenQueue = []
        self.streamStarted = false
        self.streamEnded = false
        self.tagDirectives = ["!!": "tag:yaml.org,2002:"]
        self.yamlDirectiveSeen = false
        self.documentStarted = false
        self.flowKeyPending = false
        self.pendingNodeIndent = nil
        self.expectValueAfterFlowKey = false
        self.adjacentValueAllowed = false

        // Skip BOM at start
        if self.pos < self.source.count && self.source[self.pos] == Unicode.Scalar(0xFEFF) {
            self.pos += 1
        }
    }

    // MARK: - Public interface

    var mark: Mark { Mark(line: line, column: column) }

    mutating func nextToken() throws -> Token {
        if !tokenQueue.isEmpty {
            return tokenQueue.removeFirst()
        }
        return try fetchNextToken()
    }

    // MARK: - Token fetching

    private mutating func fetchNextToken() throws -> Token {
        if !streamStarted {
            streamStarted = true
            return .streamStart
        }

        if flowLevel == 0 {
            try skipBlockWhitespaceAndComments()
        } else {
            skipWhitespaceAndComments()
        }

        if isAtEnd {
            if flowLevel > 0 {
                throw YAMLError.unexpectedEndOfInput(mark: mark)
            }
            return emitStreamEnd()
        }

        // Handle directives (% at start of line)
        if peek() == "%" && column == 1 && flowLevel == 0 && !documentStarted {
            return try fetchDirective()
        }

        if flowLevel > 0 {
            return try fetchFlowToken()
        }

        return try fetchBlockToken()
    }

    // MARK: - Directives

    private mutating func fetchDirective() throws -> Token {
        advance() // skip %
        let name = scanDirectiveName()

        switch name {
        case "YAML":
            if yamlDirectiveSeen {
                throw YAMLError.scanner(message: "duplicate %YAML directive", mark: mark)
            }
            yamlDirectiveSeen = true
            // Skip version (we accept any YAML version)
            skipToEndOfLine()
            return try fetchNextToken()

        case "TAG":
            skipSpaces()
            let handle = scanTagHandle()
            skipSpaces()
            let prefix = scanTagPrefix()
            // Duplicate check: error if handle was already declared (non-default)
            let existing = tagDirectives[handle]
            let isDefault = (handle == "!" && existing == "!") ||
                            (handle == "!!" && existing == "tag:yaml.org,2002:")
            if existing != nil && !isDefault {
                throw YAMLError.scanner(message: "duplicate %TAG directive for handle '\(handle)'", mark: mark)
            }
            tagDirectives[handle] = prefix
            skipToEndOfLine()
            return try fetchNextToken()

        default:
            // Reserved directive — ignore with warning
            skipToEndOfLine()
            return try fetchNextToken()
        }
    }

    private mutating func scanDirectiveName() -> String {
        var result: [Unicode.Scalar] = []
        while !isAtEnd, let ch = peek(), ch != " " && ch != "\t" && ch != "\n" && ch != "\r" {
            result.append(ch)
            advance()
        }
        return makeString(result)
    }

    private mutating func scanTagHandle() -> String {
        var result: [Unicode.Scalar] = []
        guard let ch = peek(), ch == "!" else { return "!" }
        result.append(ch)
        advance()

        while !isAtEnd, let c = peek() {
            if c == "!" {
                result.append(c)
                advance()
                break
            }
            if c == " " || c == "\t" || c == "\n" || c == "\r" { break }
            result.append(c)
            advance()
        }
        return makeString(result)
    }

    private mutating func scanTagPrefix() -> String {
        var result: [Unicode.Scalar] = []
        while !isAtEnd, let ch = peek(), ch != " " && ch != "\t" && ch != "\n" && ch != "\r" {
            result.append(ch)
            advance()
        }
        return makeString(result)
    }

    private mutating func skipToEndOfLine() {
        while !isAtEnd, let ch = peek(), ch != "\n" && ch != "\r" {
            advance()
        }
        if !isAtEnd { advanceNewline() }
    }

    // MARK: - Block context

    private mutating func fetchBlockToken() throws -> Token {
        try skipBlockWhitespaceAndComments()

        if isAtEnd {
            return emitStreamEnd()
        }

        let indent = column - 1
        let ch = peek()!

        // BOM inside document is an error
        if ch == Unicode.Scalar(0xFEFF) {
            throw YAMLError.scanner(message: "BOM must not appear inside a document", mark: mark)
        }

        // Document markers (--- and ...) at column 1
        if column == 1 && ch == "-" && peekAt(offset: 1) == "-" && peekAt(offset: 2) == "-" {
            let after = peekAt(offset: 3)
            if after == nil || after == " " || after == "\t" || after == "\n" || after == "\r" {
                return try fetchDocumentStart()
            }
        }

        if column == 1 && ch == "." && peekAt(offset: 1) == "." && peekAt(offset: 2) == "." {
            let after = peekAt(offset: 3)
            if after == nil || after == " " || after == "\t" || after == "\n" || after == "\r" {
                return fetchDocumentEnd()
            }
        }

        // Unwind blocks that are deeper than current indentation
        while indents.count > 1 && indent < indents.last! {
            indents.removeLast()
            tokenQueue.append(.blockEnd)
        }

        if !tokenQueue.isEmpty {
            return tokenQueue.removeFirst()
        }

        // Block sequence entry
        if ch == "-" {
            let after = peekAt(offset: 1)
            if after == nil || after == " " || after == "\n" || after == "\r" || after == "\t" {
                return try fetchBlockEntry(indent: indent)
            }
        }

        // Explicit mapping key
        if ch == "?" {
            let after = peekAt(offset: 1)
            if after == nil || after == " " || after == "\n" || after == "\r" || after == "\t" {
                return try fetchExplicitKey(indent: indent)
            }
        }

        // Value indicator (':' at block level)
        if ch == ":" {
            let after = peekAt(offset: 1)
            if after == nil || after == " " || after == "\t" || after == "\n" || after == "\r" {
                if expectValueAfterFlowKey {
                    // After flow collection key, just emit value
                    expectValueAfterFlowKey = false
                    advance() // skip :
                    skipSpaces()
                    return .value
                }
                if indent > indents.last! {
                    indents.append(indent)
                    advance() // skip :
                    skipSpaces()
                    tokenQueue.append(.value)
                    return .blockMappingStart
                }
                advance() // skip :
                skipSpaces()
                return .value
            }
        }

        // Flow collection start (may be an implicit mapping key)
        if ch == "[" || ch == "{" {
            let startToken: Token = ch == "[" ? .flowSequenceStart : .flowMappingStart
            if isFlowCollectionKey() {
                documentStarted = true
                expectValueAfterFlowKey = true
                if indent > indents.last! {
                    indents.append(indent)
                }
                tokenQueue.append(.key)
                tokenQueue.append(fetchFlowCollectionStart(startToken))
                return .blockMappingStart
            }
            return fetchFlowCollectionStart(startToken)
        }

        // Block scalar indicators
        if ch == "|" || ch == ">" {
            if isBlockScalarHeader() {
                documentStarted = true
                let content = try scanBlockScalar(literal: ch == "|")
                return .scalar(content, .plain)
            }
        }

        // Tag
        if ch == "!" {
            if pendingNodeIndent == nil { pendingNodeIndent = indent }
            documentStarted = true
            return try scanTag()
        }

        // Anchor
        if ch == "&" {
            if pendingNodeIndent == nil { pendingNodeIndent = indent }
            documentStarted = true
            return try scanAnchor()
        }

        // Alias
        if ch == "*" {
            pendingNodeIndent = nil
            documentStarted = true
            return try scanAlias()
        }

        // Reserved indicators
        if ch == "@" || ch == "`" {
            throw YAMLError.scanner(message: "reserved indicator '\(ch)' cannot start a plain scalar", mark: mark)
        }

        // Quoted scalar (may be a mapping key)
        if ch == "\"" || ch == "'" {
            documentStarted = true
            return try fetchQuotedScalarOrKey(indent: indent)
        }

        // Plain scalar (may be a mapping key)
        documentStarted = true
        return try fetchPlainScalarOrKey(indent: indent)
    }

    // MARK: - Document markers

    private mutating func fetchDocumentStart() throws -> Token {
        // Unwind all blocks
        while indents.count > 1 {
            indents.removeLast()
            tokenQueue.append(.blockEnd)
        }

        advance() // -
        advance() // -
        advance() // -
        skipSpaces()
        documentStarted = true
        // Reset directive state for new document
        yamlDirectiveSeen = false

        tokenQueue.append(.documentStart)
        if !tokenQueue.isEmpty {
            return tokenQueue.removeFirst()
        }
        return .documentStart
    }

    private mutating func fetchDocumentEnd() -> Token {
        // Unwind all blocks
        while indents.count > 1 {
            indents.removeLast()
            tokenQueue.append(.blockEnd)
        }

        advance() // .
        advance() // .
        advance() // .
        skipToEndOfLine()
        documentStarted = false
        yamlDirectiveSeen = false
        tagDirectives = ["!!": "tag:yaml.org,2002:"]

        tokenQueue.append(.documentEnd)
        return tokenQueue.removeFirst()
    }

    // MARK: - Explicit key

    private mutating func fetchExplicitKey(indent: Int) throws -> Token {
        if indent > indents.last! {
            indents.append(indent)
            tokenQueue.append(.key)
            advance() // skip ?
            skipSpaces()
            return .blockMappingStart
        }

        advance() // skip ?
        skipSpaces()
        return .key
    }

    // MARK: - Block entry

    private mutating func fetchBlockEntry(indent: Int) throws -> Token {
        documentStarted = true
        if indent > indents.last! {
            indents.append(indent)
            tokenQueue.append(.blockEntry)
            advance() // skip -
            skipSpaces()
            return .blockSequenceStart
        }

        advance() // skip -
        skipSpaces()
        return .blockEntry
    }

    private mutating func fetchQuotedScalarOrKey(indent: Int) throws -> Token {
        let token = try fetchQuotedScalar()
        guard case .scalar(let value, let style) = token else {
            pendingNodeIndent = nil
            return token
        }

        skipSpaces()

        // Check if this quoted scalar is a mapping key
        if let ch = peek(), ch == ":" {
            let afterColon = peekAt(offset: 1)
            if afterColon == nil || afterColon == " " || afterColon == "\t"
                || afterColon == "\n" || afterColon == "\r"
            {
                let effectiveIndent: Int
                if let pni = pendingNodeIndent, indent >= pni {
                    effectiveIndent = pni
                } else {
                    effectiveIndent = indent
                }
                pendingNodeIndent = nil
                if effectiveIndent > indents.last! {
                    indents.append(effectiveIndent)
                    tokenQueue.append(.key)
                    tokenQueue.append(.scalar(value, style))
                    advance() // skip :
                    skipSpaces()
                    tokenQueue.append(.value)
                    return .blockMappingStart
                }

                tokenQueue.append(.scalar(value, style))
                advance() // skip :
                skipSpaces()
                tokenQueue.append(.value)
                return .key
            }
        }

        pendingNodeIndent = nil
        return .scalar(value, style)
    }

    private mutating func fetchPlainScalarOrKey(indent: Int) throws -> Token {
        let scalar = try scanPlainScalar()

        skipSpaces()

        // Check if this is a mapping key
        if let ch = peek(), ch == ":" {
            let afterColon = peekAt(offset: 1)
            if afterColon == nil || afterColon == " " || afterColon == "\t"
                || afterColon == "\n" || afterColon == "\r"
            {
                let effectiveIndent: Int
                if let pni = pendingNodeIndent, indent >= pni {
                    effectiveIndent = pni
                } else {
                    effectiveIndent = indent
                }
                pendingNodeIndent = nil
                if effectiveIndent > indents.last! {
                    indents.append(effectiveIndent)
                    tokenQueue.append(.key)
                    tokenQueue.append(.scalar(scalar, .plain))
                    advance() // skip :
                    skipSpaces()
                    tokenQueue.append(.value)
                    return .blockMappingStart
                }

                tokenQueue.append(.scalar(scalar, .plain))
                advance() // skip :
                skipSpaces()
                tokenQueue.append(.value)
                return .key
            }
        }

        pendingNodeIndent = nil
        return .scalar(scalar, .plain)
    }

    // MARK: - Flow context

    private mutating func fetchFlowToken() throws -> Token {
        skipFlowWhitespace()

        if isAtEnd {
            throw YAMLError.unexpectedEndOfInput(mark: mark)
        }

        let ch = peek()!

        // Reset adjacent value flag for non-':' tokens
        if ch != ":" {
            adjacentValueAllowed = false
        }

        switch ch {
        case "[":
            if isFlowCollectionKey() {
                tokenQueue.append(fetchFlowCollectionStart(.flowSequenceStart))
                return .key
            }
            return fetchFlowCollectionStart(.flowSequenceStart)
        case "{":
            if isFlowCollectionKey() {
                tokenQueue.append(fetchFlowCollectionStart(.flowMappingStart))
                return .key
            }
            return fetchFlowCollectionStart(.flowMappingStart)
        case "]":
            return fetchFlowCollectionEnd(.flowSequenceEnd)
        case "}":
            return fetchFlowCollectionEnd(.flowMappingEnd)
        case ",":
            advance()
            flowKeyPending = false
            return .flowEntry
        case "\"", "'":
            return try fetchFlowQuotedScalarOrKey()
        case "!":
            return try scanTag()
        case "&":
            return try scanAnchor()
        case "*":
            return try scanAlias()
        case "?":
            let after = peekAt(offset: 1)
            if after == nil || after == " " || after == "\t" || after == ","
                || after == "]" || after == "}" || after == "\n" || after == "\r"
            {
                advance()
                skipFlowWhitespace()
                flowKeyPending = true
                return .key
            }
            return try fetchFlowPlainScalar()
        case ":":
            let afterColon = peekAt(offset: 1)
            let allowAdjacent = adjacentValueAllowed
            adjacentValueAllowed = false
            if allowAdjacent || afterColon == nil || afterColon == " " || afterColon == "\t"
                || afterColon == "," || afterColon == "]" || afterColon == "}"
                || afterColon == "\n" || afterColon == "\r"
            {
                advance()
                skipFlowWhitespace()
                flowKeyPending = false
                return .value
            }
            return try fetchFlowPlainScalar()
        case "@", "`":
            throw YAMLError.scanner(message: "reserved indicator '\(ch)' cannot start a plain scalar", mark: mark)
        default:
            return try fetchFlowPlainScalar()
        }
    }

    private mutating func fetchFlowQuotedScalarOrKey() throws -> Token {
        let token = try fetchQuotedScalar()
        guard case .scalar(let value, let style) = token else {
            return token
        }

        skipFlowWhitespace()

        // Check if this quoted scalar is a flow mapping key
        // In flow context, adjacent values are allowed after quoted keys: "key":value
        if !flowKeyPending, let ch = peek(), ch == ":" {
            tokenQueue.append(.scalar(value, style))
            advance() // skip :
            skipFlowWhitespace()
            tokenQueue.append(.value)
            return .key
        }

        return .scalar(value, style)
    }

    private mutating func fetchFlowPlainScalar() throws -> Token {
        let scalar = try scanFlowPlainScalar()
        skipFlowWhitespace()

        // Check if this is a mapping key inside flow (skip if explicit ? was used)
        if !flowKeyPending, let ch = peek(), ch == ":" {
            let afterColon = peekAt(offset: 1)
            if afterColon == nil || afterColon == " " || afterColon == "\t"
                || afterColon == "," || afterColon == "]" || afterColon == "}"
                || afterColon == "\n" || afterColon == "\r"
            {
                tokenQueue.append(.scalar(scalar, .plain))
                advance() // skip :
                skipFlowWhitespace()
                tokenQueue.append(.value)
                return .key
            }
        }

        return .scalar(scalar, .plain)
    }

    // MARK: - Flow collections

    private mutating func fetchFlowCollectionStart(_ token: Token) -> Token {
        flowLevel += 1
        advance()
        return token
    }

    private mutating func fetchFlowCollectionEnd(_ token: Token) -> Token {
        flowLevel -= 1
        advance()
        // Allow adjacent ':' after flow collection end (e.g., {key: val}:value)
        adjacentValueAllowed = true
        return token
    }

    // MARK: - Tags

    private mutating func scanTag() throws -> Token {
        let startMark = mark
        advance() // skip !

        guard let ch = peek() else {
            // Just "!" at end — non-specific tag
            return .tag("!")
        }

        if ch == "<" {
            // Verbatim tag !<...>
            advance() // skip <
            var uri: [Unicode.Scalar] = []
            while !isAtEnd, let c = peek(), c != ">" {
                // Validate URI characters
                if !isValidURIChar(c) {
                    throw YAMLError.scanner(message: "invalid character in verbatim tag URI", mark: mark)
                }
                uri.append(c)
                advance()
            }
            guard !isAtEnd else {
                throw YAMLError.scanner(message: "unterminated verbatim tag", mark: startMark)
            }
            advance() // skip >
            let uriStr = makeString(uri)
            if uriStr.isEmpty || uriStr == "!" {
                throw YAMLError.scanner(message: "invalid verbatim tag '!<\(uriStr)>'", mark: startMark)
            }
            skipSpaces()
            return .tag(uriStr)
        }

        if ch == "!" {
            // Secondary tag !!suffix
            advance() // skip second !
            var suffix: [Unicode.Scalar] = []
            while !isAtEnd, let c = peek(), isTagSuffixChar(c) {
                suffix.append(c)
                advance()
            }
            let suffixStr = makeString(suffix)
            if let prefix = tagDirectives["!!"] {
                skipSpaces()
                return .tag(prefix + suffixStr)
            }
            skipSpaces()
            return .tag("!!" + suffixStr)
        }

        if ch == " " || ch == "\t" || ch == "\n" || ch == "\r" {
            // Non-specific tag "! "
            return .tag("!")
        }

        // Named handle or primary tag
        var handle: [Unicode.Scalar] = ["!"]
        var suffix: [Unicode.Scalar] = []
        var foundSecondBang = false

        while !isAtEnd, let c = peek() {
            if c == "!" {
                handle.append(c)
                advance()
                foundSecondBang = true
                break
            }
            if c == " " || c == "\t" || c == "\n" || c == "\r" || c == "," || c == "]" || c == "}" {
                break
            }
            handle.append(c)
            advance()
        }

        if foundSecondBang {
            // Named handle !name! followed by suffix
            while !isAtEnd, let c = peek(), isTagSuffixChar(c) {
                suffix.append(c)
                advance()
            }
            let handleStr = makeString(handle)
            let suffixStr = makeString(suffix)
            if suffixStr.isEmpty {
                throw YAMLError.scanner(message: "tag shorthand '\(handleStr)' must have a non-empty suffix", mark: startMark)
            }
            if let prefix = tagDirectives[handleStr] {
                skipSpaces()
                return .tag(prefix + suffixStr)
            }
            throw YAMLError.scanner(message: "undeclared tag handle '\(handleStr)'", mark: startMark)
        }

        // Primary tag !suffix — handle is actually !suffix
        let rawTag = makeString(handle)
        if let prefix = tagDirectives["!"], prefix != "!" {
            let tagSuffix = String(rawTag.dropFirst()) // remove the leading !
            skipSpaces()
            return .tag(prefix + tagSuffix)
        }
        skipSpaces()
        return .tag(rawTag)
    }

    private func isTagChar(_ ch: Unicode.Scalar) -> Bool {
        if ch == " " || ch == "\t" || ch == "\n" || ch == "\r" { return false }
        if ch == "," || ch == "]" || ch == "}" || ch == "[" || ch == "{" { return false }
        return true
    }

    /// Check if character at current position is valid in tag suffix.
    private func isTagSuffixChar(_ ch: Unicode.Scalar) -> Bool {
        if !isTagChar(ch) { return false }
        // Tag suffix is terminated by `:` when followed by space/end (value indicator)
        if ch == ":" {
            // peekAt(offset:1) looks 1 past current pos, which is the char after `:`
            let next = peekAt(offset: 1)
            if next == nil || next == " " || next == "\t" || next == "\n" || next == "\r"
                || next == "," || next == "]" || next == "}" {
                return false
            }
        }
        return true
    }

    private func isValidURIChar(_ ch: Unicode.Scalar) -> Bool {
        // RFC 3986 + YAML allowed: alphanumeric, and - . _ ~ : / ? # [ ] @ ! $ & ' ( ) * + , ; = %
        let v = ch.value
        if v >= 0x61 && v <= 0x7A { return true } // a-z
        if v >= 0x41 && v <= 0x5A { return true } // A-Z
        if v >= 0x30 && v <= 0x39 { return true } // 0-9
        let allowed: Set<Unicode.Scalar> = ["-", ".", "_", "~", ":", "/", "#", "[", "]", "@",
                                             "!", "$", "&", "'", "(", ")", "*", "+", ",", ";",
                                             "=", "%"]
        return allowed.contains(ch)
    }

    // MARK: - Anchors and Aliases

    private mutating func scanAnchor() throws -> Token {
        advance() // skip &
        var name: [Unicode.Scalar] = []
        while !isAtEnd, let ch = peek(), isAnchorChar(ch) {
            name.append(ch)
            advance()
        }
        if name.isEmpty {
            throw YAMLError.scanner(message: "empty anchor name", mark: mark)
        }
        skipSpaces()
        return .anchor(makeString(name))
    }

    private mutating func scanAlias() throws -> Token {
        advance() // skip *
        var name: [Unicode.Scalar] = []
        while !isAtEnd, let ch = peek(), isAnchorChar(ch) {
            name.append(ch)
            advance()
        }
        if name.isEmpty {
            throw YAMLError.scanner(message: "empty alias name", mark: mark)
        }
        skipSpaces()
        return .alias(makeString(name))
    }

    private func isAnchorChar(_ ch: Unicode.Scalar) -> Bool {
        if ch == " " || ch == "\t" || ch == "\n" || ch == "\r" { return false }
        if ch == "," || ch == "[" || ch == "]" || ch == "{" || ch == "}" { return false }
        if ch == ":" || ch == "#" { return false }
        return true
    }

    // MARK: - Quoted scalars

    private mutating func fetchQuotedScalar() throws -> Token {
        let ch = peek()!
        if ch == "\"" {
            let s = try scanDoubleQuotedScalar()
            return .scalar(s, .doubleQuoted)
        } else {
            let s = try scanSingleQuotedScalar()
            return .scalar(s, .singleQuoted)
        }
    }

    private mutating func scanDoubleQuotedScalar() throws -> String {
        let startMark = mark
        advance() // skip opening "
        var result: [Unicode.Scalar] = []

        while !isAtEnd {
            let ch = peek()!
            if ch == "\"" {
                advance()
                return makeString(result)
            }
            if ch == "\\" {
                advance()
                guard !isAtEnd else {
                    throw YAMLError.scanner(message: "unterminated escape in double-quoted string", mark: startMark)
                }
                let escaped = peek()!
                advance()
                switch escaped {
                case "0": result.append("\0")
                case "a": result.append(Unicode.Scalar(0x07))
                case "b": result.append(Unicode.Scalar(0x08))
                case "t", "\t": result.append("\t")
                case "n": result.append("\n")
                case "v": result.append(Unicode.Scalar(0x0B))
                case "f": result.append(Unicode.Scalar(0x0C))
                case "r": result.append("\r")
                case "e": result.append(Unicode.Scalar(0x1B))
                case " ": result.append(" ")
                case "\"": result.append("\"")
                case "/": result.append("/")
                case "\\": result.append("\\")
                case "_": result.append(Unicode.Scalar(0xA0))
                case "N": result.append(Unicode.Scalar(0x85))
                case "L": result.append("\u{2028}")
                case "P": result.append("\u{2029}")
                case "x":
                    result.append(try scanHexEscape(digits: 2))
                case "u":
                    result.append(try scanHexEscape(digits: 4))
                case "U":
                    result.append(try scanHexEscape(digits: 8))
                case "\n":
                    // Escaped line break — line continuation
                    skipDoubleQuotedBreakSpaces()
                case "\r":
                    if !isAtEnd && peek() == "\n" { advance() }
                    skipDoubleQuotedBreakSpaces()
                default:
                    throw YAMLError.scanner(message: "invalid escape character '\\(\(escaped))'", mark: startMark)
                }
            } else if ch == "\n" || ch == "\r" {
                // Trim trailing whitespace before fold
                while let last = result.last, last == " " || last == "\t" {
                    result.removeLast()
                }
                // Multi-line: fold line break
                let blankLines = consumeLineBreaksAndBlanks()
                if blankLines > 0 {
                    for _ in 0..<blankLines {
                        result.append("\n")
                    }
                } else {
                    result.append(" ")
                }
            } else {
                result.append(ch)
                advance()
            }
        }

        throw YAMLError.scanner(message: "unterminated double-quoted string", mark: startMark)
    }

    private mutating func skipDoubleQuotedBreakSpaces() {
        while !isAtEnd, let ch = peek(), ch == " " || ch == "\t" || ch == "\n" || ch == "\r" {
            if ch == " " || ch == "\t" {
                advance()
            } else {
                break
            }
        }
    }

    /// Consume a line break and any subsequent blank lines + leading whitespace.
    /// Returns the number of blank lines encountered.
    private mutating func consumeLineBreaksAndBlanks() -> Int {
        // Consume the current line break
        if !isAtEnd {
            let ch = peek()!
            if ch == "\r" {
                advance()
                if !isAtEnd && peek() == "\n" { advance() }
            } else if ch == "\n" {
                advance()
            }
        }

        var blankLines = 0

        while !isAtEnd {
            // Skip leading whitespace
            while !isAtEnd, let ch = peek(), ch == " " || ch == "\t" {
                advance()
            }

            if isAtEnd { break }

            let ch = peek()!
            if ch == "\n" || ch == "\r" {
                blankLines += 1
                if ch == "\r" {
                    advance()
                    if !isAtEnd && peek() == "\n" { advance() }
                } else {
                    advance()
                }
            } else {
                break
            }
        }

        return blankLines
    }

    private mutating func scanHexEscape(digits: Int) throws -> Unicode.Scalar {
        var hex: [Unicode.Scalar] = []
        for _ in 0..<digits {
            guard !isAtEnd else {
                throw YAMLError.scanner(message: "incomplete hex escape", mark: mark)
            }
            let ch = peek()!
            guard isHexDigit(ch) else {
                throw YAMLError.scanner(message: "invalid hex character '\\(ch)' in escape", mark: mark)
            }
            hex.append(ch)
            advance()
        }
        let hexStr = makeString(hex)
        guard let codePoint = UInt32(hexStr, radix: 16),
              let scalar = Unicode.Scalar(codePoint) else {
            throw YAMLError.scanner(message: "invalid unicode escape '\\(hexStr)'", mark: mark)
        }
        return scalar
    }

    private func isHexDigit(_ ch: Unicode.Scalar) -> Bool {
        (ch >= "0" && ch <= "9") || (ch >= "a" && ch <= "f") || (ch >= "A" && ch <= "F")
    }

    private mutating func scanSingleQuotedScalar() throws -> String {
        let startMark = mark
        advance() // skip opening '
        var result: [Unicode.Scalar] = []

        while !isAtEnd {
            let ch = peek()!
            if ch == "'" {
                advance()
                // Escaped single quote: ''
                if let next = peek(), next == "'" {
                    result.append("'")
                    advance()
                } else {
                    return makeString(result)
                }
            } else if ch == "\n" || ch == "\r" {
                // Trim trailing whitespace before fold
                while let last = result.last, last == " " || last == "\t" {
                    result.removeLast()
                }
                // Multi-line: fold line break
                let blankLines = consumeLineBreaksAndBlanks()
                if blankLines > 0 {
                    for _ in 0..<blankLines {
                        result.append("\n")
                    }
                } else {
                    result.append(" ")
                }
            } else {
                result.append(ch)
                advance()
            }
        }

        throw YAMLError.scanner(message: "unterminated single-quoted string", mark: startMark)
    }

    // MARK: - Plain scalars

    private mutating func scanPlainScalar() throws -> String {
        let blockIndent = indents.last ?? -1
        var lines: [String] = []
        var currentLine: [Unicode.Scalar] = []

        // Scan first line
        while !isAtEnd {
            let ch = peek()!
            if ch == "\n" || ch == "\r" { break }
            if ch == "#" && !currentLine.isEmpty {
                let prev = currentLine.last!
                if prev == " " || prev == "\t" { break }
            }
            if ch == ":" {
                let after = peekAt(offset: 1)
                if after == nil || after == " " || after == "\t"
                    || after == "\n" || after == "\r"
                {
                    break
                }
            }
            currentLine.append(ch)
            advance()
        }

        // Trim trailing whitespace from first line
        while currentLine.last == " " || currentLine.last == "\t" {
            currentLine.removeLast()
        }
        lines.append(makeString(currentLine))

        // Try to scan continuation lines
        while !isAtEnd && (peek() == "\n" || peek() == "\r") {
            let savedPos = pos
            let savedLine = line
            let savedColumn = column

            // Count blank lines
            var blankLineCount = 0
            while !isAtEnd && (peek() == "\n" || peek() == "\r") {
                advanceNewline()
                blankLineCount += 1

                // Skip spaces on blank lines
                while !isAtEnd, let c = peek(), c == " " {
                    advance()
                }
            }

            if isAtEnd {
                // End of input — no continuation
                break
            }

            let nextIndent = column - 1

            // Check if continuation is valid
            if nextIndent <= blockIndent {
                // Not a continuation — restore position to after first newline
                pos = savedPos
                line = savedLine
                column = savedColumn
                break
            }

            // Skip s-separate-in-line (tabs and additional spaces beyond indent)
            while !isAtEnd, let c = peek(), c == " " || c == "\t" {
                advance()
            }

            if isAtEnd { break }

            let nextCh = peek()!

            // Check for document markers (--- or ...) at column 1
            if column == 1 {
                if nextCh == "-", peekAt(offset: 1) == "-", peekAt(offset: 2) == "-" {
                    let afterMarker = peekAt(offset: 3)
                    if afterMarker == nil || afterMarker == " " || afterMarker == "\t" || afterMarker == "\n" || afterMarker == "\r" {
                        pos = savedPos; line = savedLine; column = savedColumn; break
                    }
                }
                if nextCh == ".", peekAt(offset: 1) == ".", peekAt(offset: 2) == "." {
                    let afterMarker = peekAt(offset: 3)
                    if afterMarker == nil || afterMarker == " " || afterMarker == "\t" || afterMarker == "\n" || afterMarker == "\r" {
                        pos = savedPos; line = savedLine; column = savedColumn; break
                    }
                }
            }

            // Check for block indicators that would end the plain scalar
            if nextCh == "-" || nextCh == "?" || nextCh == ":" {
                let after = peekAt(offset: 1)
                if after == nil || after == " " || after == "\t" || after == "\n" || after == "\r" {
                    pos = savedPos
                    line = savedLine
                    column = savedColumn
                    break
                }
            }
            if nextCh == "#" || nextCh == "&" || nextCh == "*" || nextCh == "!" {
                pos = savedPos
                line = savedLine
                column = savedColumn
                break
            }
            if nextCh == "[" || nextCh == "]" || nextCh == "{" || nextCh == "}" {
                pos = savedPos
                line = savedLine
                column = savedColumn
                break
            }
            if nextCh == "|" || nextCh == ">" {
                pos = savedPos
                line = savedLine
                column = savedColumn
                break
            }

            // Add blank lines as newlines
            if blankLineCount > 1 {
                for _ in 0..<(blankLineCount - 1) {
                    lines.append("")
                }
            }

            // Scan continuation line
            var contLine: [Unicode.Scalar] = []
            while !isAtEnd {
                let c = peek()!
                if c == "\n" || c == "\r" { break }
                if c == "#" && !contLine.isEmpty {
                    let prev = contLine.last!
                    if prev == " " || prev == "\t" { break }
                }
                if c == ":" {
                    let after = peekAt(offset: 1)
                    if after == nil || after == " " || after == "\t"
                        || after == "\n" || after == "\r"
                    {
                        break
                    }
                }
                contLine.append(c)
                advance()
            }

            while contLine.last == " " || contLine.last == "\t" {
                contLine.removeLast()
            }

            if contLine.isEmpty && (isAtEnd || peek() == "\n" || peek() == "\r") {
                // Trailing blank — don't continue
                pos = savedPos
                line = savedLine
                column = savedColumn
                break
            }

            lines.append(makeString(contLine))
        }

        // Join lines: blank lines become newlines, regular lines fold to spaces
        var result = ""
        for (i, lineStr) in lines.enumerated() {
            if i == 0 {
                result = lineStr
            } else if lineStr.isEmpty {
                result += "\n"
            } else if i > 0 && lines[i - 1].isEmpty {
                result += lineStr
            } else {
                result += " " + lineStr
            }
        }

        return result
    }

    private mutating func scanFlowPlainScalar() throws -> String {
        var lines: [String] = []
        var currentLine: [Unicode.Scalar] = []

        // Scan first line
        while !isAtEnd {
            let ch = peek()!
            if ch == "\n" || ch == "\r" { break }
            if ch == "#" && !currentLine.isEmpty {
                let prev = currentLine.last!
                if prev == " " || prev == "\t" { break }
            }
            if ch == "," || ch == "]" || ch == "}" || ch == "[" || ch == "{" { break }
            if ch == ":" {
                let after = peekAt(offset: 1)
                if after == nil || after == " " || after == "\t"
                    || after == "," || after == "]" || after == "}"
                    || after == "\n" || after == "\r"
                {
                    break
                }
            }
            currentLine.append(ch)
            advance()
        }

        while currentLine.last == " " || currentLine.last == "\t" {
            currentLine.removeLast()
        }
        lines.append(makeString(currentLine))

        // Continuation lines in flow context
        while !isAtEnd && (peek() == "\n" || peek() == "\r") {
            let savedPos = pos
            let savedLine = line
            let savedColumn = column

            var blankLineCount = 0
            while !isAtEnd && (peek() == "\n" || peek() == "\r") {
                advanceNewline()
                blankLineCount += 1
                while !isAtEnd, let c = peek(), c == " " || c == "\t" {
                    advance()
                }
            }

            if isAtEnd {
                break
            }

            let nextCh = peek()!
            // Flow indicators end plain scalar
            if nextCh == "," || nextCh == "]" || nextCh == "}" || nextCh == "[" || nextCh == "{" {
                pos = savedPos
                line = savedLine
                column = savedColumn
                break
            }
            if nextCh == "#" || nextCh == ":" || nextCh == "?" {
                let after = peekAt(offset: 1)
                if nextCh == "#" || after == nil || after == " " || after == "\t" || after == "," || after == "]" || after == "}" {
                    pos = savedPos
                    line = savedLine
                    column = savedColumn
                    break
                }
            }

            if blankLineCount > 1 {
                for _ in 0..<(blankLineCount - 1) {
                    lines.append("")
                }
            }

            var contLine: [Unicode.Scalar] = []
            while !isAtEnd {
                let c = peek()!
                if c == "\n" || c == "\r" { break }
                if c == "," || c == "]" || c == "}" || c == "[" || c == "{" { break }
                if c == "#" && !contLine.isEmpty {
                    let prev = contLine.last!
                    if prev == " " || prev == "\t" { break }
                }
                if c == ":" {
                    let after = peekAt(offset: 1)
                    if after == nil || after == " " || after == "\t"
                        || after == "," || after == "]" || after == "}"
                        || after == "\n" || after == "\r"
                    {
                        break
                    }
                }
                contLine.append(c)
                advance()
            }

            while contLine.last == " " || contLine.last == "\t" {
                contLine.removeLast()
            }

            if contLine.isEmpty {
                pos = savedPos
                line = savedLine
                column = savedColumn
                break
            }

            lines.append(makeString(contLine))
        }

        var result = ""
        for (i, lineStr) in lines.enumerated() {
            if i == 0 {
                result = lineStr
            } else if lineStr.isEmpty {
                result += "\n"
            } else if i > 0 && lines[i - 1].isEmpty {
                result += lineStr
            } else {
                result += " " + lineStr
            }
        }

        return result
    }

    // MARK: - Block scalars

    private func isBlockScalarHeader() -> Bool {
        var offset = 1
        for _ in 0..<2 {
            guard let c = peekAt(offset: offset) else { return true }
            if c == "-" || c == "+" || (c >= "1" && c <= "9") {
                offset += 1
            } else {
                break
            }
        }
        while let c = peekAt(offset: offset) {
            if c == " " || c == "\t" { offset += 1; continue }
            if c == "#" || c == "\n" || c == "\r" { return true }
            return false
        }
        return true
    }

    private mutating func scanBlockScalar(literal: Bool) throws -> String {
        advance() // skip | or >

        var chomping = 0 // 0 = clip, -1 = strip, 1 = keep
        var explicitIndent: Int? = nil

        while !isAtEnd, let ch = peek() {
            if ch == "-" && chomping == 0 { chomping = -1; advance() }
            else if ch == "+" && chomping == 0 { chomping = 1; advance() }
            else if ch >= "1" && ch <= "9" && explicitIndent == nil {
                explicitIndent = Int(String(ch))
                advance()
            }
            else { break }
        }

        // Skip rest of header line
        while !isAtEnd, let ch = peek(), ch != "\n" && ch != "\r" {
            advance()
        }
        if !isAtEnd { advanceNewline() }

        var contentIndent: Int? = nil
        if let ei = explicitIndent {
            let base = indents.last ?? 0
            contentIndent = (base < 0 ? 0 : base) + ei
        }

        struct RawLine {
            var indent: Int
            var content: String // text after indent spaces (empty for blank lines)
            var isBlank: Bool
        }
        var rawLines: [RawLine] = []

        // Phase 1: collect raw lines
        while !isAtEnd {
            let savedPos = pos
            let savedLine = line
            let savedColumn = column

            var lineIndent = 0
            while !isAtEnd, let ch = peek(), ch == " " {
                lineIndent += 1
                advance()
            }

            if isAtEnd || peek() == "\n" || peek() == "\r" {
                // Blank line
                if !isAtEnd { advanceNewline() }
                rawLines.append(RawLine(indent: lineIndent, content: "", isBlank: true))
                continue
            }

            // Auto-detect contentIndent from first non-blank line
            if contentIndent == nil {
                let baseIndent = max(indents.last ?? 0, 0)
                if lineIndent <= baseIndent {
                    pos = savedPos
                    line = savedLine
                    column = savedColumn
                    break
                }
                contentIndent = lineIndent
            }

            if lineIndent < contentIndent! {
                pos = savedPos
                line = savedLine
                column = savedColumn
                break
            }

            var lineChars: [Unicode.Scalar] = []
            while !isAtEnd, let ch = peek(), ch != "\n" && ch != "\r" {
                lineChars.append(ch)
                advance()
            }
            if !isAtEnd { advanceNewline() }

            rawLines.append(RawLine(indent: lineIndent, content: makeString(lineChars), isBlank: false))
        }

        // Phase 2: build content lines with known contentIndent
        let ci = contentIndent ?? 0
        struct ContentLine {
            var text: String
            var isEmpty: Bool
            var extraIndent: Int
        }
        var contentLines: [ContentLine] = []

        var seenContent = false
        for raw in rawLines {
            if raw.isBlank {
                if !seenContent {
                    // Before first content line: blank lines are empty
                    contentLines.append(ContentLine(text: "", isEmpty: true, extraIndent: 0))
                } else if raw.indent >= ci {
                    // At or above contentIndent: strip indent, keep excess
                    let excess = raw.indent - ci
                    let txt = excess > 0 ? String(repeating: " ", count: excess) : ""
                    contentLines.append(ContentLine(text: txt, isEmpty: true, extraIndent: 0))
                } else {
                    // Below contentIndent after content: spaces are literal content
                    let txt = raw.indent > 0 ? String(repeating: " ", count: raw.indent) : ""
                    contentLines.append(ContentLine(text: txt, isEmpty: true, extraIndent: 0))
                }
            } else {
                seenContent = true
                let extra = raw.indent - ci
                let txt = (extra > 0 ? String(repeating: " ", count: extra) : "") + raw.content
                contentLines.append(ContentLine(text: txt, isEmpty: false, extraIndent: extra))
            }
        }

        // Separate trailing empty lines for chomping
        var trailingEmptyCount = 0
        while let last = contentLines.last, last.isEmpty {
            contentLines.removeLast()
            trailingEmptyCount += 1
        }

        var result: String
        if literal {
            result = contentLines.map(\.text).joined(separator: "\n")
        } else {
            // Folded scalar: fold line breaks between normal lines to spaces.
            // Empty lines produce literal newlines.
            // More-indented lines preserve line breaks around them.
            func isMoreIndented(_ cl: ContentLine) -> Bool {
                if cl.isEmpty { return false }
                if cl.extraIndent > 0 { return true }
                if let first = cl.text.unicodeScalars.first, first == " " || first == "\t" {
                    return true
                }
                return false
            }

            var parts: [Unicode.Scalar] = []
            var lastNonEmptyIdx = -1
            var emptyCount = 0

            for (i, cl) in contentLines.enumerated() {
                if cl.isEmpty {
                    emptyCount += 1
                } else {
                    if lastNonEmptyIdx >= 0 {
                        let prev = contentLines[lastNonEmptyIdx]
                        if emptyCount > 0 {
                            // Empty lines between non-empty lines → preserve as newlines
                            for _ in 0..<emptyCount {
                                parts.append("\n")
                            }
                            // After empties, more-indented line needs extra newline
                            if isMoreIndented(cl) {
                                parts.append("\n")
                            }
                            // After empties, if prev was more-indented, extra newline
                            if isMoreIndented(prev) && !isMoreIndented(cl) {
                                parts.append("\n")
                            }
                        } else {
                            // Adjacent non-empty lines
                            if isMoreIndented(prev) || isMoreIndented(cl) {
                                parts.append("\n")
                            } else {
                                parts.append(" ")
                            }
                        }
                    } else {
                        // First non-empty line: prepend empties as newlines
                        for _ in 0..<emptyCount {
                            parts.append("\n")
                        }
                    }
                    parts.append(contentsOf: cl.text.unicodeScalars)
                    lastNonEmptyIdx = i
                    emptyCount = 0
                }
            }
            result = makeString(Array(parts))
        }

        // Apply chomping
        if contentLines.isEmpty {
            // No content lines — empty scalar
            switch chomping {
            case 1: // keep: preserve trailing newlines
                result = String(repeating: "\n", count: trailingEmptyCount)
            default: // strip or clip: empty string
                result = ""
            }
        } else {
            switch chomping {
            case -1: break // strip: no trailing newline
            case 1: // keep: content newline + all trailing
                result += "\n"
                result += String(repeating: "\n", count: trailingEmptyCount)
            default: // clip: single trailing newline
                result += "\n"
            }
        }

        return result
    }

    // MARK: - Whitespace and comments

    /// Look ahead to determine if the flow collection at current position is an implicit mapping key.
    /// Returns true if the matching close bracket is followed by ':'.
    private func isFlowCollectionKey() -> Bool {
        var depth = 0
        var i = pos
        while i < source.count {
            let c = source[i]
            if c == "{" || c == "[" {
                depth += 1
            } else if c == "}" || c == "]" {
                depth -= 1
                if depth == 0 {
                    // Found matching close bracket — check for ':'
                    i += 1
                    // Skip spaces/tabs
                    while i < source.count && (source[i] == " " || source[i] == "\t") {
                        i += 1
                    }
                    if i < source.count && source[i] == ":" {
                        if flowLevel > 0 {
                            // In flow context, adjacent ':' after collection is always valid
                            return true
                        } else {
                            // In block context, ':' must be followed by space/newline/end
                            let afterI = i + 1
                            if afterI >= source.count { return true }
                            let after = source[afterI]
                            return after == " " || after == "\t" || after == "\n" || after == "\r"
                        }
                    }
                    return false
                }
            } else if c == "\"" {
                // Skip double-quoted string
                i += 1
                while i < source.count && source[i] != "\"" {
                    if source[i] == "\\" { i += 1 }
                    i += 1
                }
            } else if c == "'" {
                // Skip single-quoted string
                i += 1
                while i < source.count {
                    if source[i] == "'" {
                        if i + 1 < source.count && source[i + 1] == "'" {
                            i += 1
                        } else {
                            break
                        }
                    }
                    i += 1
                }
            }
            i += 1
        }
        return false
    }

    private mutating func skipWhitespaceAndComments() {
        while !isAtEnd {
            let ch = peek()!

            if ch == " " || ch == "\t" {
                advance()
            } else if ch == "\n" || ch == "\r" {
                advanceNewline()
            } else if ch == "#" {
                while !isAtEnd, let c = peek(), c != "\n" && c != "\r" {
                    advance()
                }
            } else {
                break
            }
        }
    }

    /// Like skipWhitespaceAndComments but throws on tabs used as indentation in block context.
    private mutating func skipBlockWhitespaceAndComments() throws {
        while !isAtEnd {
            let ch = peek()!

            if ch == " " {
                advance()
            } else if ch == "\t" {
                // Tab after newline at start of line = tab indentation (forbidden)
                if column == 1 || isLineStart() {
                    throw YAMLError.scanner(message: "tabs are not allowed as indentation", mark: mark)
                }
                advance()
            } else if ch == "\n" || ch == "\r" {
                advanceNewline()
            } else if ch == "#" {
                while !isAtEnd, let c = peek(), c != "\n" && c != "\r" {
                    advance()
                }
            } else {
                break
            }
        }
    }

    /// Check if we are at the start of a line (only spaces so far on this line).
    private func isLineStart() -> Bool {
        // Check backwards if we only have spaces/tabs since last newline
        var i = pos - 1
        while i >= 0 {
            let c = source[i]
            if c == "\n" || c == "\r" { return true }
            if c != " " && c != "\t" { return false }
            i -= 1
        }
        return true // start of input
    }

    private mutating func skipSpaces() {
        while !isAtEnd, let ch = peek(), ch == " " || ch == "\t" {
            advance()
        }
    }

    private mutating func skipFlowWhitespace() {
        while !isAtEnd {
            let ch = peek()!
            if ch == " " || ch == "\t" {
                advance()
            } else if ch == "\n" || ch == "\r" {
                advanceNewline()
            } else if ch == "#" {
                while !isAtEnd, let c = peek(), c != "\n" && c != "\r" {
                    advance()
                }
            } else {
                break
            }
        }
    }

    // MARK: - Stream end

    private mutating func emitStreamEnd() -> Token {
        if !streamEnded {
            streamEnded = true
            while indents.count > 1 {
                indents.removeLast()
                tokenQueue.append(.blockEnd)
            }
            tokenQueue.append(.streamEnd)
        }
        return tokenQueue.removeFirst()
    }

    // MARK: - Character access

    private var isAtEnd: Bool { pos >= source.count }

    private func peek() -> Unicode.Scalar? {
        guard pos < source.count else { return nil }
        return source[pos]
    }

    private func peekAt(offset: Int) -> Unicode.Scalar? {
        let idx = pos + offset
        guard idx < source.count else { return nil }
        return source[idx]
    }

    private mutating func advance() {
        guard pos < source.count else { return }
        let ch = source[pos]
        pos += 1
        if ch == "\n" {
            line += 1
            column = 1
        } else if ch == "\r" {
            line += 1
            column = 1
            if pos < source.count && source[pos] == "\n" {
                pos += 1
            }
        } else {
            column += 1
        }
    }

    private mutating func advanceNewline() {
        guard !isAtEnd else { return }
        let ch = source[pos]
        if ch == "\r" {
            pos += 1
            line += 1
            column = 1
            if pos < source.count && source[pos] == "\n" {
                pos += 1
            }
        } else if ch == "\n" {
            pos += 1
            line += 1
            column = 1
        }
    }

    // MARK: - String construction

    private func makeString(_ scalars: [Unicode.Scalar]) -> String {
        var s = ""
        s.unicodeScalars.append(contentsOf: scalars)
        return s
    }
}
