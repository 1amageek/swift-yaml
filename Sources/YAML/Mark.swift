/// Source position in a YAML document.
public struct Mark: Sendable, Hashable, CustomStringConvertible {
    /// Line number, 1-based.
    public let line: Int
    /// Column number, 1-based.
    public let column: Int

    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }

    public var description: String { "\(line):\(column)" }
}
