# swift-yaml

A pure Swift YAML parser with no external dependencies. Parses YAML strings into a typed `Node` tree supporting block and flow styles, quoted strings, comments, and nested structures.

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/1amageek/swift-yaml.git", from: "0.1.0")
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
user:
  name: Alice
  tags: [swift, yaml]
""")

if case .mapping(let root) = node {
    // Access by string key
    if case .mapping(let user) = root["user"] {
        print(user["name"])  // Optional(.scalar("Alice"))
    }
}
```

### Node Types

- **`.scalar(Scalar)`** — String value with optional source position
- **`.mapping(Mapping)`** — Ordered key-value pairs (subscriptable by string key)
- **`.sequence(Sequence)`** — Ordered list of nodes

### Supported Syntax

| Feature | Example |
|---|---|
| Block mapping | `key: value` |
| Block sequence | `- item` |
| Flow sequence | `[a, b, c]` |
| Flow mapping | `{key: value}` |
| Single-quoted | `'hello'` |
| Double-quoted | `"hello\nworld"` |
| Comments | `# comment` |
| Nested structures | Arbitrary depth |

## License

MIT License. See [LICENSE](LICENSE) for details.
