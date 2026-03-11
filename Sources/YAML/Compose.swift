/// Parse a YAML string and return the document root node.
///
/// Returns `nil` if the input is empty or contains only whitespace/comments.
///
///     let node = try YAML.compose(yaml: "key: value")
///     // node == .mapping(...)
///
/// - Parameters:
///   - yaml: The YAML string to parse.
///   - maxDepth: Maximum nesting depth (default: 512). Throws if exceeded.
public func compose(yaml: String, maxDepth: Int = 512) throws -> Node? {
    var parser = Parser(yaml: yaml, maxDepth: maxDepth)
    return try parser.parse()
}

/// Parse all documents in a multi-document YAML stream.
///
///     let nodes = try YAML.composeAll(yaml: "---\nfoo\n---\nbar")
///     // nodes == [.scalar("foo"), .scalar("bar")]
///
/// - Parameters:
///   - yaml: The YAML string containing one or more documents.
///   - maxDepth: Maximum nesting depth (default: 512). Throws if exceeded.
public func composeAll(yaml: String, maxDepth: Int = 512) throws -> [Node] {
    var parser = Parser(yaml: yaml, maxDepth: maxDepth)
    return try parser.parseAll()
}
