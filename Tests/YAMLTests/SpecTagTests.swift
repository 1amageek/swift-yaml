import Testing
@testable import YAML

// YAML 1.2.2 Specification - Tag comprehensive tests

@Suite("Spec: Tags", .tags(.spec, .tag))
struct SpecTagTests {

    // MARK: - Local Tags

    @Test("Local tag on scalar")
    func localTagScalar() throws {
        let yaml = "!local value\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "value")
    }

    @Test("Local tag on mapping value")
    func localTagMapping() throws {
        let yaml = "key: !custom value\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["key"] == .scalar(.init("value")))
    }

    // MARK: - Standard Tags (!! shorthand)

    @Test("!!str tag")
    func strTag() throws {
        let yaml = "!!str 123\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "123")
    }

    @Test("!!int tag")
    func intTag() throws {
        let yaml = "!!int 123\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "123")
    }

    @Test("!!float tag")
    func floatTag() throws {
        let yaml = "!!float 1.23\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "1.23")
    }

    @Test("!!null tag")
    func nullTag() throws {
        let yaml = "!!null null\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "null")
    }

    @Test("!!bool tag")
    func boolTag() throws {
        let yaml = "!!bool true\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "true")
    }

    @Test("!!seq tag on block sequence")
    func seqTagBlock() throws {
        let yaml = "!!seq\n- one\n- two\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("one")))
    }

    @Test("!!map tag on block mapping")
    func mapTagBlock() throws {
        let yaml = "!!map\nfoo: bar\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["foo"] == .scalar(.init("bar")))
    }

    @Test("!!str tag with empty value")
    func strTagEmpty() throws {
        let yaml = "key: !!str\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["key"] == .scalar(.init("")))
    }

    // MARK: - Verbatim Tags

    @Test("Verbatim tag with URI")
    func verbatimTag() throws {
        let yaml = "!<tag:yaml.org,2002:str> foo\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "foo")
    }

    @Test("Verbatim tag with local prefix")
    func verbatimLocalTag() throws {
        let yaml = "!<!bar> baz\n"
        // !<!bar> should be a valid verbatim local tag
        // Actually, the spec says !<!> is invalid but !<!bar> might be valid
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "baz")
    }

    // MARK: - TAG Directive

    @Test("TAG directive with primary handle")
    func tagDirectivePrimary() throws {
        let yaml = "%TAG ! tag:example.com,2000:app/\n---\n!foo bar\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "bar")
    }

    @Test("TAG directive with secondary handle")
    func tagDirectiveSecondary() throws {
        let yaml = "%TAG !! tag:example.com,2000:app/\n---\n!!foo bar\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "bar")
    }

    @Test("TAG directive with named handle")
    func tagDirectiveNamed() throws {
        let yaml = "%TAG !e! tag:example.com,2000:app/\n---\n!e!foo bar\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "bar")
    }

    @Test("Tag on mapping key")
    func tagOnKey() throws {
        let yaml = "!!str foo: bar\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["foo"] == .scalar(.init("bar")))
    }

    @Test("Tag on sequence entry")
    func tagOnSequenceEntry() throws {
        let yaml = "- !!str 123\n- !!int 456\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("123")))
        #expect(seq[1] == .scalar(.init("456")))
    }

    @Test("Non-specific tag !")
    func nonSpecificTag() throws {
        let yaml = "- ! foo\n- ! 123\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        // ! means "use the non-specific tag" → resolved as string
        #expect(seq[0] == .scalar(.init("foo")))
        #expect(seq[1] == .scalar(.init("123")))
    }
}
