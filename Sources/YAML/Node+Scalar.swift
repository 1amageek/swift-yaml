extension Node {
    /// A YAML scalar value.
    public struct Scalar: Sendable, Hashable {
        /// The string content of this scalar.
        public var string: String
        /// Source position where this scalar was found.
        public var mark: Mark?

        public init(_ string: String, mark: Mark? = nil) {
            self.string = string
            self.mark = mark
        }
    }

    /// Returns the scalar if this node is `.scalar`, otherwise `nil`.
    public var scalar: Scalar? {
        if case .scalar(let s) = self { return s }
        return nil
    }
}
