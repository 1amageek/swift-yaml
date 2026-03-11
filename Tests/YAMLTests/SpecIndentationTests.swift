import Testing
@testable import YAML

// YAML 1.2.2 Specification - Indentation comprehensive tests

@Suite("Spec: Indentation", .tags(.spec, .indentation))
struct SpecIndentationTests {

    @Test("1-space indentation")
    func oneSpaceIndent() throws {
        let yaml = "a:\n b: c\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let inner) = map["a"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(inner["b"] == .scalar(.init("c")))
    }

    @Test("2-space indentation")
    func twoSpaceIndent() throws {
        let yaml = "a:\n  b: c\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let inner) = map["a"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(inner["b"] == .scalar(.init("c")))
    }

    @Test("4-space indentation")
    func fourSpaceIndent() throws {
        let yaml = "a:\n    b: c\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let inner) = map["a"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(inner["b"] == .scalar(.init("c")))
    }

    @Test("Mixed indentation levels across siblings")
    func mixedIndentLevels() throws {
        let yaml = "a:\n  b: 1\nc:\n    d: 2\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let aMap) = map["a"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(aMap["b"] == .scalar(.init("1")))
        guard case .mapping(let cMap) = map["c"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(cMap["d"] == .scalar(.init("2")))
    }

    @Test("Deep nesting")
    func deepNesting() throws {
        let yaml = "a:\n  b:\n    c:\n      d: value\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let a) = map["a"] else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let b) = a["b"] else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let c) = b["c"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(c["d"] == .scalar(.init("value")))
    }

    @Test("Sibling mappings at same level")
    func siblingMappings() throws {
        let yaml = "a: 1\nb: 2\nc: 3\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map.count == 3)
        #expect(map["a"] == .scalar(.init("1")))
        #expect(map["b"] == .scalar(.init("2")))
        #expect(map["c"] == .scalar(.init("3")))
    }

    @Test("Sequence items at same level as parent key")
    func sequenceAtKeyLevel() throws {
        let yaml = "items:\n- one\n- two\n- three\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .sequence(let seq) = map["items"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 3)
    }

    @Test("Sequence items indented under parent key")
    func sequenceIndentedUnderKey() throws {
        let yaml = "items:\n  - one\n  - two\n  - three\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .sequence(let seq) = map["items"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 3)
    }

    @Test("Multiple dedents")
    func multipleDedents() throws {
        let yaml = "a:\n  b:\n    c: deep\nd: shallow\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map.count == 2)
        guard case .mapping(let a) = map["a"] else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let b) = a["b"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(b["c"] == .scalar(.init("deep")))
        #expect(map["d"] == .scalar(.init("shallow")))
    }

    @Test("Compact notation: sequence in mapping")
    func compactSequenceInMapping() throws {
        let yaml = "- key: value\n  other: thing\n- key2: value2\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 2)
        guard case .mapping(let first) = seq[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(first["key"] == .scalar(.init("value")))
        #expect(first["other"] == .scalar(.init("thing")))
    }

    @Test("Tabs are not allowed for indentation")
    func tabsNotAllowedForIndentation() throws {
        // Tabs should not be used for indentation in YAML
        let yaml = "key:\n\tvalue\n"
        // This should either error or handle gracefully
        // The spec says tabs must not be used for indentation
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml)
        }
    }

    @Test("Block collection with variable indentation across entries")
    func variableIndentAcrossEntries() throws {
        let yaml = "first:\n  a: 1\n  b: 2\nsecond:\n    c: 3\n    d: 4\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let first) = map["first"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(first["a"] == .scalar(.init("1")))
        guard case .mapping(let second) = map["second"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(second["c"] == .scalar(.init("3")))
    }

    @Test("Nested sequence of mappings")
    func nestedSequenceOfMappings() throws {
        let yaml = "items:\n  - name: a\n    val: 1\n  - name: b\n    val: 2\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .sequence(let seq) = map["items"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 2)
        guard case .mapping(let first) = seq[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(first["name"] == .scalar(.init("a")))
        #expect(first["val"] == .scalar(.init("1")))
    }
}
