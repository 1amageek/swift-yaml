extension Node {
    /// An ordered sequence of YAML nodes.
    public struct Sequence: Sendable {
        /// Internal storage.
        private var nodes: [Node]
        /// Source position where this sequence was found.
        public var mark: Mark?
        /// The tag associated with this sequence (e.g., "tag:yaml.org,2002:seq").
        public var tag: String?

        public init(_ nodes: [Node] = [], mark: Mark? = nil, tag: String? = nil) {
            self.nodes = nodes
            self.mark = mark
            self.tag = tag
        }
    }
}

extension Node {
    /// Returns the sequence if this node is `.sequence`, otherwise `nil`.
    public var sequence: Sequence? {
        if case .sequence(let s) = self { return s }
        return nil
    }
}

// MARK: - Equatable/Hashable (only nodes participate, mark and tag excluded)

extension Node.Sequence: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.nodes == rhs.nodes
    }
}

extension Node.Sequence: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(nodes)
    }
}

// MARK: - RandomAccessCollection

extension Node.Sequence: RandomAccessCollection {
    public typealias Element = Node
    public typealias Index = Int

    public var startIndex: Int { 0 }
    public var endIndex: Int { nodes.count }

    public subscript(position: Int) -> Node {
        get { nodes[position] }
    }
}
