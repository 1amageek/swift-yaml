extension Node {
    /// A YAML scalar value.
    public struct Scalar: Sendable {
        /// The string content of this scalar.
        public var string: String
        /// Source position where this scalar was found.
        public var mark: Mark?
        /// The presentation style of this scalar.
        public var style: ScalarStyle
        /// The tag associated with this scalar (e.g., "tag:yaml.org,2002:str").
        public var tag: String?

        public init(_ string: String, mark: Mark? = nil, style: ScalarStyle = .plain, tag: String? = nil) {
            self.string = string
            self.mark = mark
            self.style = style
            self.tag = tag
        }
    }

    /// Returns the scalar if this node is `.scalar`, otherwise `nil`.
    public var scalar: Scalar? {
        if case .scalar(let s) = self { return s }
        return nil
    }
}

// MARK: - Equatable/Hashable (only string participates)

extension Node.Scalar: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.string == rhs.string
    }
}

extension Node.Scalar: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(string)
    }
}
