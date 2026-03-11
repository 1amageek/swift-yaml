import Testing
@testable import YAML

// YAML 1.2.2 Specification - Comment comprehensive tests

@Suite("Spec: Comments", .tags(.spec, .comment))
struct SpecCommentTests {

    @Test("Comment only stream")
    func commentOnlyStream() throws {
        let yaml = "# This is a comment\n"
        let node = try compose(yaml: yaml)
        #expect(node == nil)
    }

    @Test("Multiple comment lines")
    func multipleCommentLines() throws {
        let yaml = "# Comment 1\n# Comment 2\n# Comment 3\n"
        let node = try compose(yaml: yaml)
        #expect(node == nil)
    }

    @Test("Inline comment after scalar value")
    func inlineCommentAfterScalar() throws {
        let yaml = "key: value # This is a comment\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["key"] == .scalar(.init("value")))
    }

    @Test("Inline comment after key")
    func inlineCommentAfterKey() throws {
        let yaml = "key: # Comment\n  value\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["key"] == .scalar(.init("value")))
    }

    @Test("Comment between mapping entries")
    func commentBetweenEntries() throws {
        let yaml = "a: 1\n# Comment\nb: 2\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["a"] == .scalar(.init("1")))
        #expect(map["b"] == .scalar(.init("2")))
    }

    @Test("Comment between sequence entries")
    func commentBetweenSeqEntries() throws {
        let yaml = "- one\n# Comment\n- two\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("one")))
        #expect(seq[1] == .scalar(.init("two")))
    }

    @Test("Comment inside flow sequence")
    func commentInFlowSequence() throws {
        let yaml = "[ one, # comment\n  two ]\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("one")))
        #expect(seq[1] == .scalar(.init("two")))
    }

    @Test("Comment inside flow mapping")
    func commentInFlowMapping() throws {
        let yaml = "{ key: value, # comment\n  key2: value2 }\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["key"] == .scalar(.init("value")))
        #expect(map["key2"] == .scalar(.init("value2")))
    }

    @Test("Hash in plain scalar is not a comment")
    func hashInPlainScalar() throws {
        let yaml = "key: value#not-comment\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        // # without preceding space is part of the scalar
        #expect(map["key"] == .scalar(.init("value#not-comment")))
    }

    @Test("Hash after space is a comment")
    func hashAfterSpace() throws {
        let yaml = "key: value #comment\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["key"] == .scalar(.init("value")))
    }

    @Test("Hash in quoted strings is not a comment")
    func hashInQuotedString() throws {
        let yaml = "key: \"value # not a comment\"\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["key"] == .scalar(.init("value # not a comment")))
    }

    @Test("Comment after block scalar indicator")
    func commentAfterBlockScalar() throws {
        let yaml = "key: | # Comment\n  literal\n  text\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let s) = map["key"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "literal\ntext\n")
    }

    @Test("Comment before document start")
    func commentBeforeDocument() throws {
        let yaml = "# Header comment\n---\nfoo: bar\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["foo"] == .scalar(.init("bar")))
    }

    @Test("Indented comment")
    func indentedComment() throws {
        let yaml = "key:\n  # This is a comment\n  value\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["key"] == .scalar(.init("value")))
    }

    @Test("Trailing comment on sequence entry")
    func trailingCommentOnSequence() throws {
        let yaml = "- one # first\n- two # second\n- three # third\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("one")))
        #expect(seq[1] == .scalar(.init("two")))
        #expect(seq[2] == .scalar(.init("three")))
    }
}
