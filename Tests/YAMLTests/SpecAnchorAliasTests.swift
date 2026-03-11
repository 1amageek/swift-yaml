import Testing
@testable import YAML

// YAML 1.2.2 Specification - Anchor (&) and Alias (*) comprehensive tests

@Suite("Spec: Anchors and Aliases", .tags(.spec, .anchor))
struct SpecAnchorAliasTests {

    @Test("Simple anchor and alias")
    func simpleAnchorAlias() throws {
        let yaml = "anchor: &val foo\nalias: *val\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["anchor"] == .scalar(.init("foo")))
        #expect(map["alias"] == .scalar(.init("foo")))
    }

    @Test("Anchor on sequence and alias reuse")
    func anchorOnSequence() throws {
        let yaml = "original: &items\n  - one\n  - two\ncopy: *items\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .sequence(let original) = map["original"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(original[0] == .scalar(.init("one")))
        guard case .sequence(let copy) = map["copy"] else {
            Issue.record("Expected sequence for copy"); return
        }
        #expect(copy[0] == .scalar(.init("one")))
        #expect(copy[1] == .scalar(.init("two")))
    }

    @Test("Anchor on mapping and alias reuse")
    func anchorOnMapping() throws {
        let yaml = "defaults: &defaults\n  adapter: postgres\n  host: localhost\nproduction:\n  database: myapp_production\n  <<: *defaults\n"
        // Note: << merge key is a YAML 1.1 extension, may not be supported
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let defaults) = map["defaults"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(defaults["adapter"] == .scalar(.init("postgres")))
    }

    @Test("Anchor override")
    func anchorOverride() throws {
        let yaml = "first: &anchor old\nsecond: &anchor new\nthird: *anchor\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["first"] == .scalar(.init("old")))
        #expect(map["second"] == .scalar(.init("new")))
        // *anchor should resolve to most recent anchor definition
        #expect(map["third"] == .scalar(.init("new")))
    }

    @Test("Anchor with tag")
    func anchorWithTag() throws {
        let yaml = "tagged: !!str &anchor value\nalias: *anchor\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["tagged"] == .scalar(.init("value")))
        #expect(map["alias"] == .scalar(.init("value")))
    }

    @Test("Multiple anchors and aliases")
    func multipleAnchorsAliases() throws {
        let yaml = "a: &a1 foo\nb: &a2 bar\nc: *a1\nd: *a2\ne: *a1\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["a"] == .scalar(.init("foo")))
        #expect(map["b"] == .scalar(.init("bar")))
        #expect(map["c"] == .scalar(.init("foo")))
        #expect(map["d"] == .scalar(.init("bar")))
        #expect(map["e"] == .scalar(.init("foo")))
    }

    @Test("Alias in sequence")
    func aliasInSequence() throws {
        let yaml = "- &item first\n- second\n- *item\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("first")))
        #expect(seq[1] == .scalar(.init("second")))
        #expect(seq[2] == .scalar(.init("first")))
    }

    @Test("Anchor in flow collection")
    func anchorInFlowCollection() throws {
        let yaml = "[&a foo, bar, *a]\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("foo")))
        #expect(seq[1] == .scalar(.init("bar")))
        #expect(seq[2] == .scalar(.init("foo")))
    }

    @Test("Undefined alias should produce error")
    func undefinedAlias() throws {
        let yaml = "foo: *undefined\n"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml)
        }
    }

    @Test("Anchor names with various characters")
    func anchorNameCharacters() throws {
        let yaml = "a: &my-anchor_123 value\nb: *my-anchor_123\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["a"] == .scalar(.init("value")))
        #expect(map["b"] == .scalar(.init("value")))
    }
}
