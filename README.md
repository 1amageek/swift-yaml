# swift-yaml

A pure Swift YAML 1.2.2 parser with zero dependencies. Parses YAML strings into a typed `Node` tree with full spec compliance, verified by 569 tests.

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/1amageek/swift-yaml.git", from: "0.3.0")
]
```

Then add `"YAML"` to your target's dependencies:

```swift
.target(name: "YourTarget", dependencies: ["YAML"])
```

## Usage

```swift
import YAML

let node = try compose(yaml: """
server:
  host: localhost
  port: 8080
  features: [auth, logging]
""")

if case .mapping(let root) = node,
   case .mapping(let server) = root["server"] {
    print(server["host"])      // Optional(.scalar("localhost"))
    print(server["port"])      // Optional(.scalar("8080"))
    print(server["features"])  // Optional(.sequence([...]))
}
```

### Node Types

The parser produces a recursive `Node` tree with three cases:

| Case | Type | Description |
|---|---|---|
| `.scalar(Scalar)` | `Node.Scalar` | String value with optional source position |
| `.mapping(Mapping)` | `Node.Mapping` | Ordered key-value pairs (`RandomAccessCollection`) |
| `.sequence(Sequence)` | `Node.Sequence` | Ordered list of nodes (`RandomAccessCollection`) |

Access values using computed properties:

```swift
node.scalar?.string     // "value" or nil
node.mapping?["key"]    // Node? or nil
node.sequence?[0]       // Node or nil
```

### Supported YAML Features

| Feature | Example |
|---|---|
| Block mapping | `key: value` |
| Block sequence | `- item` |
| Flow sequence | `[a, b, c]` |
| Flow mapping | `{key: value}` |
| Literal block scalar | <code>&#124;</code>, <code>&#124;-</code>, <code>&#124;+</code> |
| Folded block scalar | `>`, `>-`, `>+` |
| Single-quoted string | `'it''s escaped'` |
| Double-quoted string | `"hello\nworld"` |
| Anchors & aliases | `&anchor` / `*anchor` |
| Tags | `!!str`, `!custom`, `!<verbatim>` |
| Multi-document | `---` / `...` |
| Directives | `%YAML 1.2`, `%TAG` |
| Comments | `# comment` |
| Complex mapping keys | `{flow: map}: value`, `[seq]: value` |
| Escape sequences | All 18 YAML escapes + `\xNN`, `\uNNNN`, `\UNNNNNNNN` |
| Nested structures | Arbitrary depth |

### Error Handling

All parse errors are reported as `YAMLError` with source position:

```swift
do {
    let node = try compose(yaml: invalidYAML)
} catch let error as YAMLError {
    print(error) // "3:12: scanner error: unterminated double-quoted string"
}
```

### Type Safety

All public types conform to `Sendable`, `Hashable`, and `Equatable`:

```swift
// Use nodes as dictionary keys or set elements
var seen: Set<Node> = []
seen.insert(node)

// Compare nodes
if node == .scalar(Node.Scalar("expected")) { ... }
```

## Architecture

The parser uses a classic three-stage pipeline:

```
YAML String → Scanner → Parser → Node Tree
               (tokens)  (recursive descent)
```

1. **Scanner** — Tokenizes YAML input with indentation tracking, flow/block context switching, and block scalar processing
2. **Parser** — Recursive descent parser that consumes tokens and builds the `Node` tree with anchor resolution
3. **Compose** — Public entry point (`compose(yaml:)`) that wires Scanner and Parser together

## API Reference

### Entry Point

```swift
public func compose(yaml: String) throws -> Node?
```

Returns `nil` for empty documents. Throws `YAMLError` on invalid input.

### Node

```swift
public enum Node: Sendable, Hashable {
    case scalar(Scalar)
    case mapping(Mapping)
    case sequence(Sequence)

    var scalar: Scalar?     { get }
    var mapping: Mapping?   { get }
    var sequence: Sequence? { get }
}
```

### Node.Scalar

```swift
public struct Scalar: Sendable, Hashable {
    public let string: String
    public let mark: Mark?
    public init(_ string: String, mark: Mark? = nil)
}
```

### Node.Mapping

```swift
public struct Mapping: Sendable, Hashable, RandomAccessCollection {
    // Element = (key: Node, value: Node)
    public subscript(key: String) -> Node?          // lookup by string key
    public subscript(position: Int) -> (Node, Node)  // access by index
    public var first: (key: Node, value: Node)?
    public var isEmpty: Bool
}
```

### Node.Sequence

```swift
public struct Sequence: Sendable, Hashable, RandomAccessCollection {
    // Element = Node
    public subscript(position: Int) -> Node
}
```

### Mark

```swift
public struct Mark: Sendable, Hashable, CustomStringConvertible {
    public let line: Int    // 1-based
    public let column: Int  // 1-based
}
```

### YAMLError

```swift
public enum YAMLError: Error, Sendable, CustomStringConvertible {
    case scanner(message: String, mark: Mark)
    case parser(message: String, mark: Mark)
    case unexpectedEndOfInput(mark: Mark)
}
```

## Requirements

- Swift 6.2+

## License

MIT License. See [LICENSE](LICENSE) for details.
