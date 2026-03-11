import Testing
@testable import YAML

// YAML 1.2.2 Specification - Complex mapping key (? key) tests

@Suite("Spec: Complex Mapping Keys", .tags(.spec, .key))
struct SpecComplexKeyTests {

    @Test("Explicit simple key with ?")
    func explicitSimpleKey() throws {
        let yaml = "? key\n: value\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["key"] == .scalar(.init("value")))
    }

    @Test("Explicit key without value")
    func explicitKeyNoValue() throws {
        let yaml = "? key\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["key"] == .scalar(.init("")))
    }

    @Test("Sequence as mapping key")
    func sequenceAsKey() throws {
        let yaml = "? - one\n  - two\n: value\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        let (key, val) = map[0]
        guard case .sequence(let keySeq) = key else {
            Issue.record("Expected sequence key"); return
        }
        #expect(keySeq[0] == .scalar(.init("one")))
        #expect(keySeq[1] == .scalar(.init("two")))
        #expect(val == .scalar(.init("value")))
    }

    @Test("Mapping as mapping key")
    func mappingAsKey() throws {
        let yaml = "? foo: bar\n: value\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        let (key, val) = map[0]
        guard case .mapping(let keyMap) = key else {
            Issue.record("Expected mapping key"); return
        }
        #expect(keyMap["foo"] == .scalar(.init("bar")))
        #expect(val == .scalar(.init("value")))
    }

    @Test("Flow sequence as block mapping key")
    func flowSequenceAsBlockKey() throws {
        let yaml = "? [a, b]\n: value\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        let (key, _) = map[0]
        guard case .sequence(let keySeq) = key else {
            Issue.record("Expected sequence key"); return
        }
        #expect(keySeq[0] == .scalar(.init("a")))
        #expect(keySeq[1] == .scalar(.init("b")))
    }

    @Test("Flow mapping as block mapping key")
    func flowMappingAsBlockKey() throws {
        let yaml = "? {a: b}\n: value\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        let (key, _) = map[0]
        guard case .mapping(let keyMap) = key else {
            Issue.record("Expected mapping key"); return
        }
        #expect(keyMap["a"] == .scalar(.init("b")))
    }

    @Test("Multiple complex keys")
    func multipleComplexKeys() throws {
        let yaml = "? first\n: 1\n? second\n: 2\n? third\n: 3\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map.count == 3)
        #expect(map["first"] == .scalar(.init("1")))
        #expect(map["second"] == .scalar(.init("2")))
        #expect(map["third"] == .scalar(.init("3")))
    }

    @Test("Explicit key in flow mapping")
    func explicitKeyInFlowMapping() throws {
        let yaml = "{ ? key : value }\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["key"] == .scalar(.init("value")))
    }

    @Test("Mixed implicit and explicit keys")
    func mixedKeys() throws {
        let yaml = "implicit: value1\n? explicit\n: value2\nalso implicit: value3\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["implicit"] == .scalar(.init("value1")))
        #expect(map["explicit"] == .scalar(.init("value2")))
        #expect(map["also implicit"] == .scalar(.init("value3")))
    }

    @Test("Empty explicit key")
    func emptyExplicitKey() throws {
        let yaml = "?\n: value\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map[""] == .scalar(.init("value")))
    }

    @Test("Empty explicit key and value")
    func emptyExplicitKeyAndValue() throws {
        let yaml = "?\n:\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map[""] == .scalar(.init("")))
    }
}
