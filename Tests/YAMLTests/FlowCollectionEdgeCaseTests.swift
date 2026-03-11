import Testing
@testable import YAML

@Suite("Flow Collection Edge Cases", .tags(.regression, .flow))
struct FlowCollectionEdgeCaseTests {

    @Test("Flow sequence with spaces around delimiters")
    func spacesAroundDelimiters() throws {
        let yaml = "items: [ a , b , c ]"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .sequence(let seq) = m[0].value else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 3)
        #expect(seq[0] == .scalar(Node.Scalar("a")))
        #expect(seq[1] == .scalar(Node.Scalar("b")))
        #expect(seq[2] == .scalar(Node.Scalar("c")))
    }

    @Test("Flow sequence with trailing comma")
    func trailingComma() throws {
        let yaml = "items: [a, b, c,]"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .sequence(let seq) = m[0].value else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 3)
    }

    @Test("Flow sequence with single item")
    func singleItem() throws {
        let yaml = "items: [only]"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .sequence(let seq) = m[0].value else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 1)
        #expect(seq[0] == .scalar(Node.Scalar("only")))
    }

    @Test("Flow mapping with spaces")
    func flowMappingSpaces() throws {
        let yaml = "data: { name: test , value: 42 }"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .mapping(let inner) = m[0].value else {
            Issue.record("Expected flow mapping"); return
        }
        #expect(inner.count == 2)
    }

    @Test("Flow mapping inside flow sequence")
    func flowMappingInSequence() throws {
        let yaml = "items: [{name: a, val: 1}, {name: b, val: 2}]"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .sequence(let seq) = m[0].value else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 2)

        guard case .mapping(let first) = seq[0], case .mapping(let second) = seq[1] else {
            Issue.record("Expected mappings in sequence"); return
        }
        #expect(first.count == 2)
        #expect(second.count == 2)
    }

    @Test("Flow sequence inside flow mapping")
    func flowSequenceInMapping() throws {
        let yaml = "data: {tags: [a, b], name: test}"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .mapping(let inner) = m[0].value else {
            Issue.record("Expected flow mapping"); return
        }
        #expect(inner.count == 2)

        guard case .sequence(let tags) = inner[0].value else {
            Issue.record("Expected tags sequence"); return
        }
        #expect(tags.count == 2)
    }

    @Test("Quoted strings in flow sequence")
    func quotedInFlowSequence() throws {
        let yaml = """
        items: ["hello world", 'single quoted', plain]
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .sequence(let seq) = m[0].value else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 3)
        #expect(seq[0] == .scalar(Node.Scalar("hello world")))
        #expect(seq[1] == .scalar(Node.Scalar("single quoted")))
        #expect(seq[2] == .scalar(Node.Scalar("plain")))
    }

    @Test("Quoted key in flow mapping")
    func quotedKeyInFlowMapping() throws {
        let yaml = """
        data: {"key with spaces": value}
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .mapping(let inner) = m[0].value else {
            Issue.record("Expected flow mapping"); return
        }
        guard case .scalar(let k) = inner[0].key else {
            Issue.record("Expected scalar key"); return
        }
        #expect(k.string == "key with spaces")
    }

    @Test("Deeply nested flow: [[{a: [1, 2]}]]")
    func deeplyNestedFlow() throws {
        let yaml = "data: [[{a: [1, 2]}]]"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .sequence(let outer) = m[0].value else {
            Issue.record("Expected outer sequence"); return
        }
        #expect(outer.count == 1)
        guard case .sequence(let mid) = outer[0] else {
            Issue.record("Expected middle sequence"); return
        }
        #expect(mid.count == 1)
        guard case .mapping(let inner) = mid[0] else {
            Issue.record("Expected mapping"); return
        }
        guard case .sequence(let deepest) = inner[0].value else {
            Issue.record("Expected deepest sequence"); return
        }
        #expect(deepest.count == 2)
    }

    @Test("Flow sequence after block sequence entry")
    func flowAfterBlockEntry() throws {
        let yaml = """
        items:
          - [a, b]
          - [c, d]
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .sequence(let items) = m[0].value else {
            Issue.record("Expected sequence"); return
        }
        #expect(items.count == 2)

        guard case .sequence(let first) = items[0], case .sequence(let second) = items[1] else {
            Issue.record("Expected nested sequences"); return
        }
        #expect(first.count == 2)
        #expect(second.count == 2)
    }

    @Test("Flow collection after comment on previous line")
    func flowAfterComment() throws {
        let yaml = """
        # comment
        items: [a, b]
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .sequence(let seq) = m[0].value else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 2)
    }
}
