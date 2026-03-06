extension Node {
    /// An ordered sequence of YAML nodes.
    public struct Sequence: Sendable, Hashable {
        /// Internal storage.
        private var nodes: [Node]
        /// Source position where this sequence was found.
        public var mark: Mark?

        public init(_ nodes: [Node] = [], mark: Mark? = nil) {
            self.nodes = nodes
            self.mark = mark
        }
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
