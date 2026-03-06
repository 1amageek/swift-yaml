/// Tokenizer that converts a YAML string into a stream of tokens.
///
/// Tracks indentation levels to emit implicit block structure tokens
/// (`blockMappingStart`, `blockSequenceStart`, `blockEnd`).
///
/// Uses `[Unicode.Scalar]` instead of `[Character]` to correctly handle
/// CRLF line endings — Swift's `Character` merges `\r\n` into a single
/// extended grapheme cluster, breaking individual `\r` / `\n` comparisons.
struct Scanner {
    private let source: [Unicode.Scalar]
    private var pos: Int
    private var line: Int
    private var column: Int

    /// Stack of indentation levels for block contexts.
    /// Initialized with -1 (sentinel below any valid indent).
    private var indents: [Int]

    /// Flow nesting depth (0 = block context).
    private var flowLevel: Int

    /// Buffer of tokens ready to be returned.
    private var tokenQueue: [Token]

    /// Whether `streamStart` has been emitted.
    private var streamStarted: Bool

    /// Whether `streamEnd` has been emitted.
    private var streamEnded: Bool

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

        skipWhitespaceAndComments()

        if isAtEnd {
            if flowLevel > 0 {
                throw YAMLError.unexpectedEndOfInput(mark: mark)
            }
            return emitStreamEnd()
        }

        if flowLevel > 0 {
            return try fetchFlowToken()
        }

        return try fetchBlockToken()
    }

    // MARK: - Block context

    private mutating func fetchBlockToken() throws -> Token {
        skipWhitespaceAndComments()

        if isAtEnd {
            return emitStreamEnd()
        }

        let indent = column - 1

        // Unwind blocks that are deeper than current indentation
        while indents.count > 1 && indent < indents.last! {
            indents.removeLast()
            tokenQueue.append(.blockEnd)
        }

        if !tokenQueue.isEmpty {
            return tokenQueue.removeFirst()
        }

        let ch = peek()!

        // Block sequence entry
        if ch == "-" && peekAt(offset: 1).map({ $0 == " " || $0 == "\n" || $0 == "\r" }) == true {
            return try fetchBlockEntry(indent: indent)
        }
        if ch == "-" && pos + 1 >= source.count {
            return try fetchBlockEntry(indent: indent)
        }

        // Flow collection start
        if ch == "[" { return fetchFlowCollectionStart(.flowSequenceStart) }
        if ch == "{" { return fetchFlowCollectionStart(.flowMappingStart) }

        // Quoted scalar (may be a mapping key)
        if ch == "\"" || ch == "'" {
            return try fetchQuotedScalarOrKey(indent: indent)
        }

        // Plain scalar (may be a mapping key)
        return try fetchPlainScalarOrKey(indent: indent)
    }

    private mutating func fetchBlockEntry(indent: Int) throws -> Token {
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
            return token
        }

        skipSpaces()

        // Check if this quoted scalar is a mapping key
        if let ch = peek(), ch == ":" {
            let afterColon = peekAt(offset: 1)
            if afterColon == nil || afterColon == " " || afterColon == "\t"
                || afterColon == "\n" || afterColon == "\r"
            {
                if indent > indents.last! {
                    indents.append(indent)
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

        return .scalar(value, style)
    }

    private mutating func fetchPlainScalarOrKey(indent: Int) throws -> Token {
        let scalar = try scanPlainScalar()

        skipSpaces()

        // Check if this is a mapping key (followed by ':' then space/newline/end)
        if let ch = peek(), ch == ":" {
            let afterColon = peekAt(offset: 1)
            if afterColon == nil || afterColon == " " || afterColon == "\t"
                || afterColon == "\n" || afterColon == "\r"
            {
                // This is a mapping key
                if indent > indents.last! {
                    indents.append(indent)
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

        // Plain scalar value (not a key)
        return .scalar(scalar, .plain)
    }

    // MARK: - Flow context

    private mutating func fetchFlowToken() throws -> Token {
        skipFlowWhitespace()

        if isAtEnd {
            throw YAMLError.unexpectedEndOfInput(mark: mark)
        }

        let ch = peek()!

        switch ch {
        case "[":
            return fetchFlowCollectionStart(.flowSequenceStart)
        case "{":
            return fetchFlowCollectionStart(.flowMappingStart)
        case "]":
            return fetchFlowCollectionEnd(.flowSequenceEnd)
        case "}":
            return fetchFlowCollectionEnd(.flowMappingEnd)
        case ",":
            advance()
            return .flowEntry
        case "\"", "'":
            return try fetchQuotedScalar()
        case ":":
            let afterColon = peekAt(offset: 1)
            if afterColon == nil || afterColon == " " || afterColon == "\t"
                || afterColon == "," || afterColon == "]" || afterColon == "}"
                || afterColon == "\n" || afterColon == "\r"
            {
                advance()
                skipFlowWhitespace()
                return .value
            }
            return try fetchFlowPlainScalar()
        default:
            return try fetchFlowPlainScalar()
        }
    }

    private mutating func fetchFlowPlainScalar() throws -> Token {
        let scalar = try scanFlowPlainScalar()
        skipFlowWhitespace()

        // Check if this is a mapping key inside flow
        if let ch = peek(), ch == ":" {
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
        return token
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
                case "n": result.append("\n")
                case "t": result.append("\t")
                case "r": result.append("\r")
                case "\\": result.append("\\")
                case "\"": result.append("\"")
                case "/": result.append("/")
                case "0": result.append("\0")
                case " ": result.append(" ")
                default:
                    result.append("\\")
                    result.append(escaped)
                }
            } else {
                result.append(ch)
                advance()
            }
        }

        throw YAMLError.scanner(message: "unterminated double-quoted string", mark: startMark)
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
            } else {
                result.append(ch)
                advance()
            }
        }

        throw YAMLError.scanner(message: "unterminated single-quoted string", mark: startMark)
    }

    // MARK: - Plain scalars

    private mutating func scanPlainScalar() throws -> String {
        var result: [Unicode.Scalar] = []
        var previousWasSpace = false

        while !isAtEnd {
            let ch = peek()!

            // Newline ends the plain scalar in block context
            if ch == "\n" || ch == "\r" { break }

            // '#' preceded by whitespace is a comment
            if ch == "#" && previousWasSpace { break }

            // ':' followed by whitespace/end is a value indicator
            if ch == ":" {
                let after = peekAt(offset: 1)
                if after == nil || after == " " || after == "\t"
                    || after == "\n" || after == "\r"
                {
                    break
                }
            }

            previousWasSpace = (ch == " " || ch == "\t")
            result.append(ch)
            advance()
        }

        // Trim trailing whitespace
        while result.last == " " || result.last == "\t" {
            result.removeLast()
        }

        return makeString(result)
    }

    private mutating func scanFlowPlainScalar() throws -> String {
        var result: [Unicode.Scalar] = []
        var previousWasSpace = false

        while !isAtEnd {
            let ch = peek()!

            if ch == "\n" || ch == "\r" { break }
            if ch == "#" && previousWasSpace { break }

            // Flow delimiters end the scalar
            if ch == "," || ch == "]" || ch == "}" || ch == "[" || ch == "{" { break }

            // ':' followed by flow delimiter or whitespace
            if ch == ":" {
                let after = peekAt(offset: 1)
                if after == nil || after == " " || after == "\t"
                    || after == "," || after == "]" || after == "}"
                    || after == "\n" || after == "\r"
                {
                    break
                }
            }

            previousWasSpace = (ch == " " || ch == "\t")
            result.append(ch)
            advance()
        }

        while result.last == " " || result.last == "\t" {
            result.removeLast()
        }

        return makeString(result)
    }

    // MARK: - Whitespace and comments

    private mutating func skipWhitespaceAndComments() {
        while !isAtEnd {
            let ch = peek()!

            if ch == " " || ch == "\t" {
                advance()
            } else if ch == "\n" || ch == "\r" {
                advanceNewline()
            } else if ch == "#" {
                // Skip comment to end of line
                while !isAtEnd, let c = peek(), c != "\n" && c != "\r" {
                    advance()
                }
            } else {
                break
            }
        }
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
            // Unwind all remaining blocks
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
            // Skip \n in \r\n
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
