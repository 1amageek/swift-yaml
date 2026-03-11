import Testing

// MARK: - Test Tags for categorized execution
//
// Usage:
//   swift test --filter "Tag:scalar"         # Scalar-related tests
//   swift test --filter "Tag:flow"           # Flow style tests
//   swift test --filter "Tag:block"          # Block style tests
//   swift test --filter "Tag:tag"            # Tag/directive tests
//   swift test --filter "Tag:key"            # Mapping key tests
//   swift test --filter "Tag:escape"         # Escape sequence tests
//   swift test --filter "Tag:multiline"      # Multi-line scalar tests
//   swift test --filter "Tag:spec"           # All spec tests
//   swift test --filter "Tag:regression"     # Original regression tests

extension Tag {
    /// Scalar parsing: plain, single-quoted, double-quoted scalars
    @Tag static var scalar: Self
    /// Flow style: flow sequences `[...]` and flow mappings `{...}`
    @Tag static var flow: Self
    /// Block style: block sequences, block mappings, block scalars (`|`, `>`)
    @Tag static var block: Self
    /// Tags and directives: `!tag`, `!!type`, `%YAML`, `%TAG`
    @Tag static var tag: Self
    /// Mapping keys: implicit keys, explicit `?` keys, complex keys
    @Tag static var key: Self
    /// Escape sequences in double-quoted strings
    @Tag static var escape: Self
    /// Multi-line scalar folding and line joining
    @Tag static var multiline: Self
    /// YAML 1.2.2 specification compliance tests
    @Tag static var spec: Self
    /// Original regression / edge-case tests
    @Tag static var regression: Self
    /// Anchor and alias resolution
    @Tag static var anchor: Self
    /// Comment handling
    @Tag static var comment: Self
    /// Document markers (---, ...) and multi-document streams
    @Tag static var document: Self
    /// Indentation handling
    @Tag static var indentation: Self
    /// Empty node handling
    @Tag static var empty: Self
    /// Error edge cases: scanner and parser error paths
    @Tag static var edgeCases: Self
}
