import Testing
@testable import YAML

// YAML 1.2.2 Specification - Multi-line scalar comprehensive tests

@Suite("Spec: Multi-line Scalars", .tags(.spec, .multiline, .scalar))
struct SpecMultilineScalarTests {

    // MARK: - Plain Multi-line Scalars

    @Test("Plain scalar spanning two lines")
    func plainTwoLines() throws {
        let yaml = "key:\n  first\n  second\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let s) = map["key"] else {
            Issue.record("Expected scalar"); return
        }
        // Line breaks in plain scalars are folded to spaces
        #expect(s.string == "first second")
    }

    @Test("Plain scalar with blank line becomes newline")
    func plainWithBlankLine() throws {
        let yaml = "key:\n  first\n\n  second\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let s) = map["key"] else {
            Issue.record("Expected scalar"); return
        }
        // A blank line in plain scalars becomes a line feed
        #expect(s.string == "first\nsecond")
    }

    @Test("Plain scalar with multiple blank lines")
    func plainWithMultipleBlankLines() throws {
        let yaml = "key:\n  first\n\n\n  second\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let s) = map["key"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "first\n\nsecond")
    }

    @Test("Plain scalar as root node")
    func plainScalarRoot() throws {
        let yaml = "first\nsecond\nthird\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "first second third")
    }

    // MARK: - Double-Quoted Multi-line Scalars

    @Test("Double-quoted scalar line folding")
    func doubleQuotedLineFolding() throws {
        let yaml = "\"first\n  second\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        // Line break folded to space, leading whitespace trimmed
        #expect(s.string == "first second")
    }

    @Test("Double-quoted scalar with escaped newline")
    func doubleQuotedEscapedNewline() throws {
        let yaml = "\"first\\n  second\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "first\n  second")
    }

    @Test("Double-quoted scalar with backslash at end of line")
    func doubleQuotedBackslashContinuation() throws {
        let yaml = "\"first \\\n  second\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        // Backslash-newline is line continuation (no space)
        #expect(s.string == "first second")
    }

    @Test("Double-quoted scalar with empty line")
    func doubleQuotedEmptyLine() throws {
        let yaml = "\"first\n\n  second\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        // Empty line becomes newline
        #expect(s.string == "first\nsecond")
    }

    @Test("Double-quoted scalar preserves leading/trailing spaces")
    func doubleQuotedPreservesSpaces() throws {
        let yaml = "\" first \n last \"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == " first last ")
    }

    // MARK: - Single-Quoted Multi-line Scalars

    @Test("Single-quoted scalar line folding")
    func singleQuotedLineFolding() throws {
        let yaml = "'first\n  second'\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "first second")
    }

    @Test("Single-quoted scalar with empty line")
    func singleQuotedEmptyLine() throws {
        let yaml = "'first\n\n  second'\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "first\nsecond")
    }

    @Test("Single-quoted scalar with escaped quote")
    func singleQuotedEscapedQuote() throws {
        let yaml = "'it''s a test'\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "it's a test")
    }

    // MARK: - Block Literal Scalars

    @Test("Literal scalar preserves newlines")
    func literalPreservesNewlines() throws {
        let yaml = "|\n  first\n  second\n  third\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "first\nsecond\nthird\n")
    }

    @Test("Literal scalar with extra indentation")
    func literalExtraIndentation() throws {
        let yaml = "|\n  first\n    indented\n  back\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "first\n  indented\nback\n")
    }

    @Test("Literal scalar strip chomping")
    func literalStripChomping() throws {
        let yaml = "|-\n  text\n\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "text")
    }

    @Test("Literal scalar keep chomping")
    func literalKeepChomping() throws {
        let yaml = "|+\n  text\n\n\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "text\n\n\n")
    }

    @Test("Literal scalar clip chomping (default)")
    func literalClipChomping() throws {
        let yaml = "|\n  text\n\n\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "text\n")
    }

    @Test("Literal scalar with indentation indicator")
    func literalWithIndentIndicator() throws {
        let yaml = "|2\n  text\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "text\n")
    }

    @Test("Literal scalar empty")
    func literalEmpty() throws {
        let yaml = "|\n\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "")
    }

    // MARK: - Block Folded Scalars

    @Test("Folded scalar joins lines with space")
    func foldedJoinsLines() throws {
        let yaml = ">\n  first\n  second\n  third\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "first second third\n")
    }

    @Test("Folded scalar preserves blank lines")
    func foldedPreservesBlankLines() throws {
        let yaml = ">\n  first\n\n  second\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "first\nsecond\n")
    }

    @Test("Folded scalar preserves more-indented lines")
    func foldedPreservesMoreIndented() throws {
        let yaml = ">\n  normal\n    indented\n  back\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "normal\n  indented\nback\n")
    }

    @Test("Folded scalar strip chomping")
    func foldedStripChomping() throws {
        let yaml = ">-\n  text\n\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "text")
    }

    @Test("Folded scalar keep chomping")
    func foldedKeepChomping() throws {
        let yaml = ">+\n  text\n\n\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "text\n\n\n")
    }

    @Test("Folded scalar clip chomping (default)")
    func foldedClipChomping() throws {
        let yaml = ">\n  text\n\n\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "text\n")
    }

    @Test("Folded scalar with indentation indicator")
    func foldedWithIndentIndicator() throws {
        let yaml = ">2\n  text\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "text\n")
    }

    @Test("Folded scalar with both indicators")
    func foldedWithBothIndicators() throws {
        let yaml = ">2-\n  text\n\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "text")
    }
}
