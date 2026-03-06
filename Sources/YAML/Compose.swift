/// Parse a YAML string and return the document root node.
///
/// Returns `nil` if the input is empty or contains only whitespace/comments.
///
///     let node = try YAML.compose(yaml: "key: value")
///     // node == .mapping(...)
///
public func compose(yaml: String) throws -> Node? {
    var parser = Parser(yaml: yaml)
    return try parser.parse()
}
