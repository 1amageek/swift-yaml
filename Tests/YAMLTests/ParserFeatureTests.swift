import Testing
@testable import YAML

@Suite("Parser Feature Tests — ScalarStyle, Tag, composeAll, Depth Limiting")
struct ParserFeatureTests {

    // MARK: - ScalarStyle preservation

    @Test("Plain scalar preserves .plain style")
    func plainScalarStyle() throws {
        let node = try compose(yaml: "hello")
        #expect(node?.scalar?.style == .plain)
    }

    @Test("Single-quoted scalar preserves .singleQuoted style")
    func singleQuotedStyle() throws {
        let node = try compose(yaml: "'hello'")
        #expect(node?.scalar?.style == .singleQuoted)
    }

    @Test("Double-quoted scalar preserves .doubleQuoted style")
    func doubleQuotedStyle() throws {
        let node = try compose(yaml: "\"hello\"")
        #expect(node?.scalar?.style == .doubleQuoted)
    }

    @Test("Literal block scalar preserves .literal style")
    func literalBlockStyle() throws {
        let node = try compose(yaml: "|\n  hello\n  world")
        #expect(node?.scalar?.style == .literal)
    }

    @Test("Folded block scalar preserves .folded style")
    func foldedBlockStyle() throws {
        let node = try compose(yaml: ">\n  hello\n  world")
        #expect(node?.scalar?.style == .folded)
    }

    @Test("Mapping value scalar styles preserved")
    func mappingValueStyles() throws {
        let yaml = """
        plain: hello
        quoted: 'world'
        double: "foo"
        """
        let node = try compose(yaml: yaml)
        let mapping = node?.mapping
        #expect(mapping?["plain"]?.scalar?.style == .plain)
        #expect(mapping?["quoted"]?.scalar?.style == .singleQuoted)
        #expect(mapping?["double"]?.scalar?.style == .doubleQuoted)
    }

    @Test("Sequence element scalar styles preserved")
    func sequenceElementStyles() throws {
        let yaml = """
        - plain
        - 'single'
        - "double"
        """
        let node = try compose(yaml: yaml)
        let seq = node?.sequence
        #expect(seq?[0].scalar?.style == .plain)
        #expect(seq?[1].scalar?.style == .singleQuoted)
        #expect(seq?[2].scalar?.style == .doubleQuoted)
    }

    @Test("Flow collection scalar styles preserved")
    func flowScalarStyles() throws {
        let node = try compose(yaml: "[plain, 'single', \"double\"]")
        let seq = node?.sequence
        #expect(seq?[0].scalar?.style == .plain)
        #expect(seq?[1].scalar?.style == .singleQuoted)
        #expect(seq?[2].scalar?.style == .doubleQuoted)
    }

    // MARK: - Tag storage

    @Test("Tag on scalar")
    func tagOnScalar() throws {
        let node = try compose(yaml: "!!str hello")
        #expect(node?.scalar?.tag == "tag:yaml.org,2002:str")
        #expect(node?.scalar?.string == "hello")
    }

    @Test("Tag on sequence")
    func tagOnSequence() throws {
        let node = try compose(yaml: "!!seq\n- a\n- b")
        #expect(node?.sequence?.tag == "tag:yaml.org,2002:seq")
    }

    @Test("Tag on flow mapping")
    func tagOnFlowMapping() throws {
        let node = try compose(yaml: "!!map {a: b}")
        #expect(node?.mapping?.tag == "tag:yaml.org,2002:map")
    }

    @Test("Tag on mapping value scalar")
    func tagOnMappingValue() throws {
        let node = try compose(yaml: "key: !!int 42")
        #expect(node?.mapping?["key"]?.scalar?.tag == "tag:yaml.org,2002:int")
        #expect(node?.mapping?["key"]?.scalar?.string == "42")
    }

    @Test("Custom tag preserved")
    func customTag() throws {
        let node = try compose(yaml: "!custom value")
        #expect(node?.scalar?.tag == "!custom")
    }

    @Test("Verbatim tag preserved")
    func verbatimTag() throws {
        let node = try compose(yaml: "!<tag:example.com,2000:type/text> foo")
        #expect(node?.scalar?.tag == "tag:example.com,2000:type/text")
    }

    @Test("No tag returns nil")
    func noTagReturnsNil() throws {
        let node = try compose(yaml: "hello")
        #expect(node?.scalar?.tag == nil)
    }

    @Test("Tag on flow sequence element")
    func tagOnFlowSequenceElement() throws {
        let node = try compose(yaml: "[!!str foo, !!int 42]")
        let seq = node?.sequence
        #expect(seq?[0].scalar?.tag == "tag:yaml.org,2002:str")
        #expect(seq?[1].scalar?.tag == "tag:yaml.org,2002:int")
    }

    // MARK: - composeAll (multi-document)

    @Test("Single document via composeAll")
    func composeAllSingleDoc() throws {
        let nodes = try composeAll(yaml: "hello")
        #expect(nodes.count == 1)
        #expect(nodes[0].scalar?.string == "hello")
    }

    @Test("Two documents separated by ---")
    func composeAllTwoDocs() throws {
        let yaml = "---\nfoo\n---\nbar"
        let nodes = try composeAll(yaml: yaml)
        #expect(nodes.count == 2)
        #expect(nodes[0].scalar?.string == "foo")
        #expect(nodes[1].scalar?.string == "bar")
    }

    @Test("Three documents with document end markers")
    func composeAllThreeDocsWithEnd() throws {
        let yaml = "---\na\n...\n---\nb\n...\n---\nc"
        let nodes = try composeAll(yaml: yaml)
        #expect(nodes.count == 3)
        #expect(nodes[0].scalar?.string == "a")
        #expect(nodes[1].scalar?.string == "b")
        #expect(nodes[2].scalar?.string == "c")
    }

    @Test("composeAll with mapping documents")
    func composeAllMappings() throws {
        let yaml = "---\na: 1\n---\nb: 2"
        let nodes = try composeAll(yaml: yaml)
        #expect(nodes.count == 2)
        #expect(nodes[0].mapping?["a"]?.scalar?.string == "1")
        #expect(nodes[1].mapping?["b"]?.scalar?.string == "2")
    }

    @Test("composeAll with no document markers")
    func composeAllNoMarkers() throws {
        let nodes = try composeAll(yaml: "hello")
        #expect(nodes.count == 1)
        #expect(nodes[0].scalar?.string == "hello")
    }

    @Test("composeAll with empty input")
    func composeAllEmpty() throws {
        let nodes = try composeAll(yaml: "")
        #expect(nodes.isEmpty)
    }

    @Test("composeAll resets anchors between documents")
    func composeAllAnchorsReset() throws {
        let yaml = "---\n&a foo\n---\n*a"
        #expect(throws: YAMLError.self) {
            _ = try composeAll(yaml: yaml)
        }
    }

    // MARK: - Depth limiting

    @Test("Deeply nested mapping triggers depth limit")
    func depthLimitMapping() throws {
        // Create a deeply nested mapping: a: b: c: ... (depth > 3)
        var yaml = ""
        for i in 0..<10 {
            yaml += String(repeating: "  ", count: i) + "k\(i):\n"
        }
        yaml += String(repeating: "  ", count: 10) + "leaf"

        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml, maxDepth: 3)
        }
    }

    @Test("Deeply nested sequence triggers depth limit")
    func depthLimitSequence() throws {
        // Nested sequences via flow style
        let yaml = "[[[[[[[[[[deep]]]]]]]]]]"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml, maxDepth: 3)
        }
    }

    @Test("Deeply nested flow mapping triggers depth limit")
    func depthLimitFlowMapping() throws {
        let yaml = "{a: {b: {c: {d: deep}}}}"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml, maxDepth: 3)
        }
    }

    @Test("Within depth limit succeeds")
    func withinDepthLimit() throws {
        let yaml = "{a: {b: c}}"
        let node = try compose(yaml: yaml, maxDepth: 10)
        #expect(node != nil)
    }

    @Test("Default depth limit allows deep nesting")
    func defaultDepthLimitAllowsDeep() throws {
        // 20 levels of nesting should be fine with default 512 limit
        var yaml = ""
        for i in 0..<20 {
            yaml += String(repeating: "  ", count: i) + "k\(i):\n"
        }
        yaml += String(repeating: "  ", count: 20) + "leaf"
        let node = try compose(yaml: yaml)
        #expect(node != nil)
    }

    @Test("Depth limit of 1 rejects any collection")
    func depthLimitOne() throws {
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: "a: b", maxDepth: 0)
        }
    }

    @Test("depthLimitExceeded error description")
    func depthLimitErrorDescription() throws {
        let error = YAMLError.depthLimitExceeded(mark: Mark(line: 1, column: 1))
        #expect(error.description.contains("nesting depth limit exceeded"))
    }

    // MARK: - Custom Equatable (mark excluded)

    @Test("Scalars with different marks are equal")
    func scalarEqualityIgnoresMark() throws {
        let s1 = Node.Scalar("hello", mark: Mark(line: 1, column: 1))
        let s2 = Node.Scalar("hello", mark: Mark(line: 5, column: 10))
        #expect(s1 == s2)
    }

    @Test("Scalars with different styles are equal")
    func scalarEqualityIgnoresStyle() throws {
        let s1 = Node.Scalar("hello", style: .plain)
        let s2 = Node.Scalar("hello", style: .doubleQuoted)
        #expect(s1 == s2)
    }

    @Test("Scalars with different tags are equal")
    func scalarEqualityIgnoresTag() throws {
        let s1 = Node.Scalar("42", tag: "!!int")
        let s2 = Node.Scalar("42", tag: "!!str")
        #expect(s1 == s2)
    }

    @Test("Mappings with different marks are equal")
    func mappingEqualityIgnoresMark() throws {
        let m1 = Node.Mapping([(.scalar(Node.Scalar("a")), .scalar(Node.Scalar("b")))], mark: Mark(line: 1, column: 1))
        let m2 = Node.Mapping([(.scalar(Node.Scalar("a")), .scalar(Node.Scalar("b")))], mark: Mark(line: 9, column: 9))
        #expect(m1 == m2)
    }

    @Test("Sequences with different marks are equal")
    func sequenceEqualityIgnoresMark() throws {
        let s1 = Node.Sequence([.scalar(Node.Scalar("a"))], mark: Mark(line: 1, column: 1))
        let s2 = Node.Sequence([.scalar(Node.Scalar("a"))], mark: Mark(line: 9, column: 9))
        #expect(s1 == s2)
    }

    @Test("Scalars with different strings are not equal")
    func scalarInequalityOnString() throws {
        let s1 = Node.Scalar("hello")
        let s2 = Node.Scalar("world")
        #expect(s1 != s2)
    }

    // MARK: - Hashable consistency

    @Test("Equal scalars produce same hash")
    func scalarHashConsistency() throws {
        let s1 = Node.Scalar("hello", mark: Mark(line: 1, column: 1), style: .plain, tag: "!!str")
        let s2 = Node.Scalar("hello", mark: Mark(line: 5, column: 5), style: .doubleQuoted, tag: "!!int")
        #expect(s1.hashValue == s2.hashValue)
    }

    @Test("Nodes can be used as dictionary keys")
    func nodeAsDictionaryKey() throws {
        let node1: Node = .scalar(Node.Scalar("key", style: .plain))
        let node2: Node = .scalar(Node.Scalar("key", style: .doubleQuoted))
        var dict: [Node: String] = [:]
        dict[node1] = "value"
        #expect(dict[node2] == "value")
    }
}
