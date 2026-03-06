extension Node {
    /// An ordered mapping of key-value pairs.
    public struct Mapping: Sendable, Hashable {
        /// Internal storage preserving insertion order.
        private var pairs: [Pair]
        /// Source position where this mapping was found.
        public var mark: Mark?

        public init(_ pairs: [(Node, Node)] = [], mark: Mark? = nil) {
            self.pairs = pairs.map { Pair(key: $0.0, value: $0.1) }
            self.mark = mark
        }

        /// Returns the first key-value pair, or `nil` if empty.
        public var first: (key: Node, value: Node)? {
            pairs.first.map { ($0.key, $0.value) }
        }

        /// The number of key-value pairs.
        public var count: Int { pairs.count }

        /// Whether the mapping is empty.
        public var isEmpty: Bool { pairs.isEmpty }
    }
}

// MARK: - Hashable internal pair

extension Node.Mapping {
    private struct Pair: Sendable, Hashable {
        let key: Node
        let value: Node
    }
}

// MARK: - RandomAccessCollection

extension Node.Mapping: RandomAccessCollection {
    public typealias Element = (key: Node, value: Node)
    public typealias Index = Int

    public var startIndex: Int { 0 }
    public var endIndex: Int { pairs.count }

    public subscript(position: Int) -> (key: Node, value: Node) {
        let p = pairs[position]
        return (p.key, p.value)
    }
}

// MARK: - Subscript by string key

extension Node.Mapping {
    /// Look up a value by string key.
    public subscript(key: String) -> Node? {
        pairs.first(where: { $0.key == .scalar(Node.Scalar(key)) })?.value
    }
}
