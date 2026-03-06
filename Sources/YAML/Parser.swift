/// Recursive descent parser that converts a token stream into a `Node` tree.
struct Parser {
    private var scanner: Scanner
    /// Lookahead buffer (single token).
    private var peeked: Token?

    init(yaml: String) {
        self.scanner = Scanner(source: yaml)
        self.peeked = nil
    }

    // MARK: - Public

    mutating func parse() throws -> Node? {
        let first = try nextToken()
        guard case .streamStart = first else {
            throw YAMLError.parser(message: "expected stream start", mark: scanner.mark)
        }

        // Skip to first meaningful token
        if try isStreamEnd() {
            return nil
        }

        let node = try parseNode()

        // Consume remaining blockEnd and streamEnd
        while true {
            let tok = try peekToken()
            switch tok {
            case .blockEnd:
                try consumeToken()
            case .streamEnd:
                return node
            default:
                return node
            }
        }
    }

    // MARK: - Node parsing

    private mutating func parseNode() throws -> Node {
        let tok = try peekToken()

        switch tok {
        case .blockMappingStart:
            return try .mapping(parseBlockMapping())
        case .blockSequenceStart:
            return try .sequence(parseBlockSequence())
        case .flowSequenceStart:
            return try .sequence(parseFlowSequence())
        case .flowMappingStart:
            return try .mapping(parseFlowMapping())
        case .scalar(let value, _):
            try consumeToken()
            return .scalar(Node.Scalar(value))
        case .key:
            // Implicit mapping at current level
            return try .mapping(parseBlockMapping())
        case .blockEntry:
            // Implicit sequence at current level
            return try .sequence(parseBlockSequence())
        default:
            throw YAMLError.parser(message: "unexpected token: \(tok)", mark: scanner.mark)
        }
    }

    // MARK: - Block mapping

    private mutating func parseBlockMapping() throws -> Node.Mapping {
        // Consume blockMappingStart if present
        if case .blockMappingStart = try peekToken() {
            try consumeToken()
        }

        var pairs: [(Node, Node)] = []

        loop: while true {
            let tok = try peekToken()

            switch tok {
            case .key:
                try consumeToken()
                let keyNode = try parseNode()

                // Expect value indicator
                let valueTok = try peekToken()
                if case .value = valueTok {
                    try consumeToken()
                }

                // Parse value or use empty scalar for missing value
                let valueNode: Node
                let nextTok = try peekToken()
                switch nextTok {
                case .key, .blockEnd, .streamEnd:
                    valueNode = .scalar(Node.Scalar(""))
                default:
                    valueNode = try parseNode()
                }

                pairs.append((keyNode, valueNode))

            case .blockEnd:
                try consumeToken()
                break loop

            case .streamEnd:
                break loop

            default:
                break loop
            }
        }

        return Node.Mapping(pairs)
    }

    // MARK: - Block sequence

    private mutating func parseBlockSequence() throws -> Node.Sequence {
        // Consume blockSequenceStart if present
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
                case .blockEnd, .streamEnd:
                    nodes.append(.scalar(Node.Scalar("")))
                default:
                    nodes.append(try parseNode())
                }

            case .blockEnd:
                try consumeToken()
                break loop

            case .streamEnd:
                break loop

            default:
                break loop
            }
        }

        return Node.Sequence(nodes)
    }

    // MARK: - Flow sequence

    private mutating func parseFlowSequence() throws -> Node.Sequence {
        try consumeExpected(.flowSequenceStart)
        var nodes: [Node] = []

        if case .flowSequenceEnd = try peekToken() {
            try consumeToken()
            return Node.Sequence(nodes)
        }

        nodes.append(try parseFlowNode())

        while true {
            let tok = try peekToken()
            switch tok {
            case .flowEntry:
                try consumeToken()
                if case .flowSequenceEnd = try peekToken() {
                    // Trailing comma
                    break
                }
                nodes.append(try parseFlowNode())
            case .flowSequenceEnd:
                break
            default:
                break
            }
            if case .flowSequenceEnd = try peekToken() {
                break
            }
        }

        try consumeExpected(.flowSequenceEnd)
        return Node.Sequence(nodes)
    }

    // MARK: - Flow mapping

    private mutating func parseFlowMapping() throws -> Node.Mapping {
        try consumeExpected(.flowMappingStart)
        var pairs: [(Node, Node)] = []

        if case .flowMappingEnd = try peekToken() {
            try consumeToken()
            return Node.Mapping(pairs)
        }

        pairs.append(try parseFlowMappingEntry())

        while true {
            let tok = try peekToken()
            if case .flowEntry = tok {
                try consumeToken()
                if case .flowMappingEnd = try peekToken() { break }
                pairs.append(try parseFlowMappingEntry())
            } else {
                break
            }
        }

        try consumeExpected(.flowMappingEnd)
        return Node.Mapping(pairs)
    }

    private mutating func parseFlowMappingEntry() throws -> (Node, Node) {
        let tok = try peekToken()

        if case .key = tok {
            try consumeToken()
            let keyNode = try parseFlowNode()
            if case .value = try peekToken() {
                try consumeToken()
            }
            let valueNode = try parseFlowNode()
            return (keyNode, valueNode)
        }

        // Implicit key
        let keyNode = try parseFlowNode()
        if case .value = try peekToken() {
            try consumeToken()
            let valueNode = try parseFlowNode()
            return (keyNode, valueNode)
        }
        return (keyNode, .scalar(Node.Scalar("")))
    }

    // MARK: - Flow node

    private mutating func parseFlowNode() throws -> Node {
        let tok = try peekToken()
        switch tok {
        case .flowSequenceStart:
            return try .sequence(parseFlowSequence())
        case .flowMappingStart:
            return try .mapping(parseFlowMapping())
        case .scalar(let value, _):
            try consumeToken()
            return .scalar(Node.Scalar(value))
        default:
            throw YAMLError.parser(message: "unexpected token in flow: \(tok)", mark: scanner.mark)
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
        // Compare by case (ignoring associated values where appropriate)
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
