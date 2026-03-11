import Testing
@testable import YAML

// YAML 1.2.2 Specification - Empty and null node tests

@Suite("Spec: Empty Nodes", .tags(.spec, .empty))
struct SpecEmptyNodeTests {

    @Test("Empty mapping value")
    func emptyMappingValue() throws {
        let yaml = "key:\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["key"] == .scalar(.init("")))
    }

    @Test("Multiple empty values")
    func multipleEmptyValues() throws {
        let yaml = "a:\nb:\nc:\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["a"] == .scalar(.init("")))
        #expect(map["b"] == .scalar(.init("")))
        #expect(map["c"] == .scalar(.init("")))
    }

    @Test("Empty sequence entry")
    func emptySequenceEntry() throws {
        let yaml = "-\n- value\n-\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("")))
        #expect(seq[1] == .scalar(.init("value")))
        #expect(seq[2] == .scalar(.init("")))
    }

    @Test("Empty flow sequence")
    func emptyFlowSequence() throws {
        let yaml = "[]\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 0)
    }

    @Test("Empty flow mapping")
    func emptyFlowMapping() throws {
        let yaml = "{}\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map.count == 0)
    }

    @Test("Empty value in flow mapping")
    func emptyValueInFlowMapping() throws {
        let yaml = "{key: }\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["key"] == .scalar(.init("")))
    }

    @Test("Empty key in flow mapping")
    func emptyKeyInFlowMapping() throws {
        let yaml = "{: value}\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map[""] == .scalar(.init("value")))
    }

    @Test("Empty key in block mapping")
    func emptyKeyInBlockMapping() throws {
        let yaml = ": value\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map[""] == .scalar(.init("value")))
    }

    @Test("Null-like values as plain scalars")
    func nullLikeValues() throws {
        let yaml = "- null\n- ~\n- \n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("null")))
        #expect(seq[1] == .scalar(.init("~")))
        #expect(seq[2] == .scalar(.init("")))
    }

    @Test("Empty document")
    func emptyDocument() throws {
        let yaml = ""
        let node = try compose(yaml: yaml)
        #expect(node == nil)
    }

    @Test("Whitespace only document")
    func whitespaceOnlyDocument() throws {
        let yaml = "   \n  \n"
        let node = try compose(yaml: yaml)
        #expect(node == nil)
    }

    @Test("Nested empty values")
    func nestedEmptyValues() throws {
        let yaml = "outer:\n  inner:\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let inner) = map["outer"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(inner["inner"] == .scalar(.init("")))
    }
}
