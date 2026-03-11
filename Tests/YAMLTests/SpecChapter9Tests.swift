import Testing
@testable import YAML

// YAML 1.2.2 Specification - Chapter 9: Document Stream Productions
// Examples 118-123

@Suite("Spec Chapter 9: Document Stream Productions", .tags(.spec, .document))
struct SpecChapter9Tests {

    // MARK: - 9.1 Documents

    @Test("Example 9.1 (118): Document Prefix")
    func example9_1() throws {
        // BOM and comments before document
        let yaml = "\u{FEFF}# Comment\n# lines\nDocument\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "Document")
    }

    @Test("Example 9.2 (119): Document Markers")
    func example9_2() throws {
        let yaml = "%YAML 1.2\n---\nDocument\n... # Suffix\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "Document")
    }

    @Test("Example 9.3 (120): Bare Documents")
    func example9_3() throws {
        // Bare document (no markers)
        let yaml = "Bare\ndocument\n...\n# No document\n...\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        // Multi-line plain scalar
        #expect(s.string == "Bare document")
    }

    @Test("Example 9.4 (121): Explicit Documents")
    func example9_4() throws {
        let yaml = "---\n{ matches\n% : 20 }\n...\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["matches %"] == .scalar(.init("20")))
    }

    @Test("Example 9.5 (122): Directives Documents")
    func example9_5() throws {
        let yaml = "%YAML 1.2\n--- |\n %!PS-Adobe-2.0\n...\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "%!PS-Adobe-2.0\n")
    }

    @Test("Example 9.6 (123): Stream")
    func example9_6() throws {
        // Multi-document stream - test first document
        let yaml = "Document\n---\n# Empty\n...\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "Document")
    }

    // MARK: - Multi-Document Stream Tests

    @Test("Document start marker (---) begins a document")
    func documentStartMarker() throws {
        let yaml = "---\nfoo: bar\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["foo"] == .scalar(.init("bar")))
    }

    @Test("Document end marker (...) terminates a document")
    func documentEndMarker() throws {
        let yaml = "foo: bar\n...\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["foo"] == .scalar(.init("bar")))
    }

    @Test("Bare document with no markers")
    func bareDocument() throws {
        let yaml = "foo: bar\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["foo"] == .scalar(.init("bar")))
    }

    @Test("Document with --- and scalar content")
    func documentWithScalar() throws {
        let yaml = "--- text\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "text")
    }

    @Test("Document with --- and block scalar")
    func documentWithBlockScalar() throws {
        let yaml = "--- |\n  literal text\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "literal text\n")
    }

    @Test("Empty document")
    func emptyDocument() throws {
        let yaml = "---\n...\n"
        // An empty document may result in nil or empty scalar
        let node = try compose(yaml: yaml)
        if let node = node {
            if case .scalar(let s) = node {
                #expect(s.string == "")
            }
        }
    }
}
