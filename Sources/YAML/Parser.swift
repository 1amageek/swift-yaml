/// Recursive descent parser that converts a token stream into a `Node` tree.
struct Parser {
    private var scanner: Scanner
    /// Lookahead buffer (single token).
    private var peeked: Token?
    /// Anchor registry for alias resolution.
    private var anchors: [String: Node] = [:]
    /// Maximum nesting depth to prevent stack overflow.
    private let maxDepth: Int
    /// Current nesting depth.
    private var currentDepth: Int = 0

    init(yaml: String, maxDepth: Int = 512) {
        self.scanner = Scanner(source: yaml)
        self.peeked = nil
        self.maxDepth = maxDepth
    }

    // MARK: - Public

    mutating func parse() throws -> Node? {
        let first = try nextToken()
        guard case .streamStart = first else {
            throw YAMLError.parser(message: "expected stream start", mark: scanner.mark)
        }

        // Skip document start if present
        if case .documentStart = try peekToken() {
            try consumeToken()
        }

        if try isStreamEnd() {
            return nil
        }
        // Empty document (--- followed by ... or ---)
        if case .documentEnd = try peekToken() {
            return nil
        }
        if case .documentStart = try peekToken() {
            return nil
        }

        let node = try parseNode(pushPropertiesToFirstKey: true)

        // Consume remaining blockEnd, documentEnd, streamEnd
        while true {
            let tok = try peekToken()
            switch tok {
            case .blockEnd:
                try consumeToken()
            case .documentEnd:
                try consumeToken()
            case .streamEnd:
                return node
            case .documentStart:
                return node
            default:
                return node
            }
        }
    }

    /// Parse all documents in the YAML stream.
    mutating func parseAll() throws -> [Node] {
        let first = try nextToken()
        guard case .streamStart = first else {
            throw YAMLError.parser(message: "expected stream start", mark: scanner.mark)
        }

        var documents: [Node] = []

        while !(try isStreamEnd()) {
            // Skip document start/end markers
            let tok = try peekToken()
            if case .documentStart = tok {
                try consumeToken()
                continue
            }
            if case .documentEnd = tok {
                try consumeToken()
                continue
            }

            // Reset anchors for each document
            anchors = [:]

            let node = try parseNode(pushPropertiesToFirstKey: true)
            documents.append(node)

            // Consume trailing blockEnd tokens
            consumeTrailing: while true {
                switch try peekToken() {
                case .blockEnd:
                    try consumeToken()
                default:
                    break consumeTrailing
                }
            }
        }

        return documents
    }

    // MARK: - Node parsing

    private mutating func parseNode(pushPropertiesToFirstKey: Bool = false) throws -> Node {
        var anchorName: String? = nil
        var tagName: String? = nil

        // Consume node properties (tag, anchor) before the actual node
        propertyLoop: while true {
            let tok = try peekToken()
            switch tok {
            case .tag(let value):
                try consumeToken()
                tagName = value
            case .anchor(let name):
                try consumeToken()
                anchorName = name
            case .alias(let name):
                try consumeToken()
                guard let resolved = anchors[name] else {
                    throw YAMLError.parser(message: "undefined alias '*\(name)'", mark: scanner.mark)
                }
                return resolved
            default:
                break propertyLoop
            }
        }

        let tok = try peekToken()
        var node: Node

        switch tok {
        case .blockMappingStart:
            if pushPropertiesToFirstKey, anchorName != nil {
                let savedAnchor = anchorName
                anchorName = nil
                node = try .mapping(parseBlockMapping(firstKeyAnchor: savedAnchor))
            } else {
                node = try .mapping(parseBlockMapping())
            }
        case .blockSequenceStart:
            node = try .sequence(parseBlockSequence())
        case .flowSequenceStart:
            node = try .sequence(parseFlowSequence())
        case .flowMappingStart:
            node = try .mapping(parseFlowMapping())
        case .scalar(let value, let style):
            try consumeToken()
            node = .scalar(Node.Scalar(value, style: style))
        case .key:
            if pushPropertiesToFirstKey, anchorName != nil {
                let savedAnchor = anchorName
                anchorName = nil
                node = try .mapping(parseBlockMapping(firstKeyAnchor: savedAnchor))
            } else {
                node = try .mapping(parseBlockMapping())
            }
        case .blockEntry:
            node = try .sequence(parseBlockSequence())
        case .value:
            // Empty key scenario — value without preceding key
            node = .scalar(Node.Scalar(""))
        // After tag/anchor, if next is end-of-context, produce empty scalar
        case .blockEnd, .streamEnd, .documentEnd, .documentStart,
             .flowEntry, .flowSequenceEnd, .flowMappingEnd:
            node = .scalar(Node.Scalar(""))
        default:
            throw YAMLError.parser(message: "unexpected token: \(tok)", mark: scanner.mark)
        }

        // Attach tag to the constructed node
        node = applyTag(tagName, to: node)

        if let name = anchorName {
            anchors[name] = node
        }

        return node
    }

    // MARK: - Block mapping

    private mutating func parseBlockMapping(firstKeyAnchor: String? = nil) throws -> Node.Mapping {
        try incrementDepth()
        defer { decrementDepth() }

        if case .blockMappingStart = try peekToken() {
            try consumeToken()
        }

        var pairs: [(Node, Node)] = []
        var isFirstKey = true

        loop: while true {
            // Consume entry-level node properties (tag/anchor before key)
            var entryAnchor: String? = nil
            var entryTag: String? = nil
            entryPropertyLoop: while true {
                let propTok = try peekToken()
                switch propTok {
                case .tag(let value):
                    try consumeToken()
                    entryTag = value
                case .anchor(let name):
                    try consumeToken()
                    entryAnchor = name
                default:
                    break entryPropertyLoop
                }
            }

            let tok = try peekToken()

            switch tok {
            case .key:
                try consumeToken()

                // Parse key — might be empty if next is .value
                var keyNode: Node
                let afterKey = try peekToken()
                switch afterKey {
                case .value:
                    keyNode = .scalar(Node.Scalar(""))
                case .key, .blockEnd, .streamEnd, .documentEnd, .documentStart:
                    keyNode = .scalar(Node.Scalar(""))
                default:
                    keyNode = try parseNode()
                }

                // Attach anchor from parent properties to first key
                if isFirstKey, let anchor = firstKeyAnchor {
                    anchors[anchor] = keyNode
                }
                // Attach entry-level anchor to key
                if let anchor = entryAnchor {
                    anchors[anchor] = keyNode
                }
                // Attach entry-level tag to key
                keyNode = applyTag(entryTag, to: keyNode)

                isFirstKey = false

                // Expect value indicator
                if case .value = try peekToken() {
                    try consumeToken()
                }

                // Parse value or use empty scalar for missing value
                let valueNode: Node
                let nextTok = try peekToken()
                switch nextTok {
                case .key, .blockEnd, .streamEnd, .documentEnd, .documentStart:
                    valueNode = .scalar(Node.Scalar(""))
                default:
                    valueNode = try parseNode()
                }

                pairs.append((keyNode, valueNode))

            case .value:
                // Value without preceding key → implicit empty key
                try consumeToken()
                let valueNode: Node
                let nextTok = try peekToken()
                switch nextTok {
                case .key, .value, .blockEnd, .streamEnd, .documentEnd, .documentStart:
                    valueNode = .scalar(Node.Scalar(""))
                default:
                    valueNode = try parseNode()
                }
                var emptyKey: Node = .scalar(Node.Scalar(""))
                emptyKey = applyTag(entryTag, to: emptyKey)
                if let anchor = entryAnchor {
                    anchors[anchor] = emptyKey
                }
                pairs.append((emptyKey, valueNode))

            case .blockEnd:
                try consumeToken()
                break loop

            case .streamEnd, .documentEnd, .documentStart:
                break loop

            default:
                break loop
            }
        }

        return Node.Mapping(pairs)
    }

    // MARK: - Block sequence

    private mutating func parseBlockSequence() throws -> Node.Sequence {
        try incrementDepth()
        defer { decrementDepth() }

        if case .blockSequenceStart = try peekToken() {
            try consumeToken()
        }

        var nodes: [Node] = []

        loop: while true {
            let tok = try peekToken()

            switch tok {
            case .blockEntry:
                try consumeToken()
                let nextTok = try peekToken()
                switch nextTok {
                case .blockEntry:
                    // Empty entry before next entry
                    nodes.append(.scalar(Node.Scalar("")))
                case .blockEnd, .streamEnd, .documentEnd, .documentStart:
                    nodes.append(.scalar(Node.Scalar("")))
                default:
                    nodes.append(try parseNode())
                }

            case .blockEnd:
                try consumeToken()
                break loop

            case .streamEnd, .documentEnd, .documentStart:
                break loop

            default:
                break loop
            }
        }

        return Node.Sequence(nodes)
    }

    // MARK: - Flow sequence

    private mutating func parseFlowSequence() throws -> Node.Sequence {
        try incrementDepth()
        defer { decrementDepth() }

        try consumeExpected(.flowSequenceStart)
        var nodes: [Node] = []

        loop: while true {
            let tok = try peekToken()
            switch tok {
            case .flowSequenceEnd:
                try consumeToken()
                break loop
            case .flowEntry:
                try consumeToken()
            case .streamEnd:
                throw YAMLError.parser(message: "unterminated flow sequence", mark: scanner.mark)
            default:
                nodes.append(try parseFlowNode())
            }
        }

        return Node.Sequence(nodes)
    }

    // MARK: - Flow mapping

    private mutating func parseFlowMapping() throws -> Node.Mapping {
        try incrementDepth()
        defer { decrementDepth() }

        try consumeExpected(.flowMappingStart)
        var pairs: [(Node, Node)] = []

        loop: while true {
            let tok = try peekToken()
            switch tok {
            case .flowMappingEnd:
                try consumeToken()
                break loop
            case .flowEntry:
                try consumeToken()
            case .streamEnd:
                throw YAMLError.parser(message: "unterminated flow mapping", mark: scanner.mark)
            default:
                pairs.append(try parseFlowMappingEntry())
            }
        }

        return Node.Mapping(pairs)
    }

    private mutating func parseFlowMappingEntry() throws -> (Node, Node) {
        let tok = try peekToken()

        // Empty key: `: value` pattern in flow mapping
        if case .value = tok {
            try consumeToken()
            let valueNode: Node
            let afterVal = try peekToken()
            switch afterVal {
            case .flowMappingEnd, .flowEntry, .flowSequenceEnd:
                valueNode = .scalar(Node.Scalar(""))
            default:
                valueNode = try parseFlowNode()
            }
            return (.scalar(Node.Scalar("")), valueNode)
        }

        if case .key = tok {
            try consumeToken()

            let keyNode: Node
            let afterKey = try peekToken()
            switch afterKey {
            case .value:
                keyNode = .scalar(Node.Scalar(""))
            case .flowMappingEnd, .flowEntry:
                keyNode = .scalar(Node.Scalar(""))
            default:
                keyNode = try parseFlowNode()
            }

            if case .value = try peekToken() {
                try consumeToken()
            }

            let valueNode: Node
            let afterVal = try peekToken()
            switch afterVal {
            case .flowMappingEnd, .flowEntry, .flowSequenceEnd:
                valueNode = .scalar(Node.Scalar(""))
            default:
                valueNode = try parseFlowNode()
            }
            return (keyNode, valueNode)
        }

        // Implicit key
        let keyNode = try parseFlowNode()
        if case .value = try peekToken() {
            try consumeToken()
            let afterVal = try peekToken()
            let valueNode: Node
            switch afterVal {
            case .flowMappingEnd, .flowEntry, .flowSequenceEnd:
                valueNode = .scalar(Node.Scalar(""))
            default:
                valueNode = try parseFlowNode()
            }
            return (keyNode, valueNode)
        }
        return (keyNode, .scalar(Node.Scalar("")))
    }

    // MARK: - Flow node

    private mutating func parseFlowNode() throws -> Node {
        var anchorName: String? = nil
        var tagName: String? = nil
        var hasProperties = false

        // Consume node properties
        propertyLoop: while true {
            let tok = try peekToken()
            switch tok {
            case .tag(let value):
                try consumeToken()
                tagName = value
                hasProperties = true
            case .anchor(let name):
                try consumeToken()
                anchorName = name
                hasProperties = true
            case .alias(let name):
                try consumeToken()
                guard let resolved = anchors[name] else {
                    throw YAMLError.parser(message: "undefined alias '*\(name)'", mark: scanner.mark)
                }
                return resolved
            default:
                break propertyLoop
            }
        }

        let tok = try peekToken()
        var node: Node

        switch tok {
        case .flowSequenceStart:
            node = try .sequence(parseFlowSequence())
        case .flowMappingStart:
            node = try .mapping(parseFlowMapping())
        case .scalar(let value, let style):
            try consumeToken()
            node = .scalar(Node.Scalar(value, style: style))
        case .key:
            // Implicit mapping inside flow sequence (single-pair)
            node = try .mapping(parseFlowImplicitMapping())
        case .value:
            if hasProperties {
                // Tag/anchor on empty node followed by value indicator
                // Return empty scalar; caller handles the value
                node = .scalar(Node.Scalar(""))
            } else {
                // Implicit mapping with empty key: `: value` in flow context
                try consumeToken()
                let val: Node
                let nextAfterValue = try peekToken()
                switch nextAfterValue {
                case .flowEntry, .flowSequenceEnd, .flowMappingEnd:
                    val = .scalar(Node.Scalar(""))
                default:
                    val = try parseFlowNode()
                }
                node = .mapping(Node.Mapping([(.scalar(Node.Scalar("")), val)]))
            }
        case .flowEntry, .flowSequenceEnd, .flowMappingEnd:
            node = .scalar(Node.Scalar(""))
        default:
            throw YAMLError.parser(message: "unexpected token in flow: \(tok)", mark: scanner.mark)
        }

        // Attach tag to the constructed node
        node = applyTag(tagName, to: node)

        if let name = anchorName {
            anchors[name] = node
        }

        return node
    }

    /// Parse an implicit single-pair mapping inside a flow sequence.
    private mutating func parseFlowImplicitMapping() throws -> Node.Mapping {
        try incrementDepth()
        defer { decrementDepth() }

        // key token already peeked
        try consumeToken() // consume .key

        let keyNode: Node
        let afterKey = try peekToken()
        switch afterKey {
        case .value:
            keyNode = .scalar(Node.Scalar(""))
        default:
            keyNode = try parseFlowNode()
        }

        if case .value = try peekToken() {
            try consumeToken()
        }

        let valueNode: Node
        let afterVal = try peekToken()
        switch afterVal {
        case .flowEntry, .flowSequenceEnd, .flowMappingEnd:
            valueNode = .scalar(Node.Scalar(""))
        default:
            valueNode = try parseFlowNode()
        }

        return Node.Mapping([(keyNode, valueNode)])
    }

    // MARK: - Depth limiting

    private mutating func incrementDepth() throws {
        currentDepth += 1
        if currentDepth > maxDepth {
            throw YAMLError.depthLimitExceeded(mark: scanner.mark)
        }
    }

    private mutating func decrementDepth() {
        currentDepth -= 1
    }

    // MARK: - Tag helper

    private func applyTag(_ tag: String?, to node: Node) -> Node {
        guard let tag = tag else { return node }
        switch node {
        case .scalar(var s):
            s.tag = tag
            return .scalar(s)
        case .mapping(var m):
            m.tag = tag
            return .mapping(m)
        case .sequence(var s):
            s.tag = tag
            return .sequence(s)
        }
    }

    // MARK: - Token helpers

    private mutating func peekToken() throws -> Token {
        if let t = peeked { return t }
        let t = try scanner.nextToken()
        peeked = t
        return t
    }

    @discardableResult
    private mutating func nextToken() throws -> Token {
        if let t = peeked {
            peeked = nil
            return t
        }
        return try scanner.nextToken()
    }

    private mutating func consumeToken() throws {
        _ = try nextToken()
    }

    private mutating func consumeExpected(_ expected: Token) throws {
        let tok = try nextToken()
        switch (expected, tok) {
        case (.flowSequenceStart, .flowSequenceStart),
             (.flowSequenceEnd, .flowSequenceEnd),
             (.flowMappingStart, .flowMappingStart),
             (.flowMappingEnd, .flowMappingEnd),
             (.blockEnd, .blockEnd),
             (.streamEnd, .streamEnd):
            return
        default:
            throw YAMLError.parser(message: "expected \(expected) but got \(tok)", mark: scanner.mark)
        }
    }

    private mutating func isStreamEnd() throws -> Bool {
        if case .streamEnd = try peekToken() { return true }
        return false
    }
}
