import Testing
@testable import YAML

// YAML 1.2.2 Specification - Escape sequence comprehensive tests

@Suite("Spec: Escape Sequences", .tags(.spec, .escape, .scalar))
struct SpecEscapeSequenceTests {

    // MARK: - Standard Escape Sequences

    @Test("Null escape \\0")
    func nullEscape() throws {
        let yaml = "\"\\0\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\u{00}")
    }

    @Test("Bell escape \\a")
    func bellEscape() throws {
        let yaml = "\"\\a\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\u{07}")
    }

    @Test("Backspace escape \\b")
    func backspaceEscape() throws {
        let yaml = "\"\\b\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\u{08}")
    }

    @Test("Tab escape \\t")
    func tabEscape() throws {
        let yaml = "\"\\t\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\t")
    }

    @Test("Line feed escape \\n")
    func lineFeedEscape() throws {
        let yaml = "\"\\n\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\n")
    }

    @Test("Vertical tab escape \\v")
    func verticalTabEscape() throws {
        let yaml = "\"\\v\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\u{0B}")
    }

    @Test("Form feed escape \\f")
    func formFeedEscape() throws {
        let yaml = "\"\\f\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\u{0C}")
    }

    @Test("Carriage return escape \\r")
    func carriageReturnEscape() throws {
        let yaml = "\"\\r\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\r")
    }

    @Test("Escape escape \\e")
    func escapeEscape() throws {
        let yaml = "\"\\e\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\u{1B}")
    }

    @Test("Space escape \\ (backslash space)")
    func spaceEscape() throws {
        let yaml = "\"\\ \"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == " ")
    }

    @Test("Double quote escape \\\"")
    func doubleQuoteEscape() throws {
        let yaml = "\"\\\"hello\\\"\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\"hello\"")
    }

    @Test("Backslash escape \\\\")
    func backslashEscape() throws {
        let yaml = "\"\\\\\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\\")
    }

    @Test("Slash escape \\/")
    func slashEscape() throws {
        let yaml = "\"\\/\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "/")
    }

    // MARK: - Unicode Escape Sequences

    @Test("Non-break space escape \\_")
    func nonBreakSpaceEscape() throws {
        let yaml = "\"\\_\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\u{A0}")
    }

    @Test("Next line escape \\N")
    func nextLineEscape() throws {
        let yaml = "\"\\N\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\u{85}")
    }

    @Test("Line separator escape \\L")
    func lineSeparatorEscape() throws {
        let yaml = "\"\\L\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\u{2028}")
    }

    @Test("Paragraph separator escape \\P")
    func paragraphSeparatorEscape() throws {
        let yaml = "\"\\P\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\u{2029}")
    }

    @Test("Hex escape \\xNN")
    func hexEscape() throws {
        let yaml = "\"\\x41\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "A")
    }

    @Test("Unicode escape \\uNNNN")
    func unicodeEscape4() throws {
        let yaml = "\"\\u0041\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "A")
    }

    @Test("Unicode escape \\UNNNNNNNN")
    func unicodeEscape8() throws {
        let yaml = "\"\\U00000041\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "A")
    }

    @Test("Unicode smiley face \\u263A")
    func unicodeSmiley() throws {
        let yaml = "\"\\u263A\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\u{263A}")
    }

    @Test("Unicode emoji \\U0001F600")
    func unicodeEmoji() throws {
        let yaml = "\"\\U0001F600\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\u{1F600}")
    }

    @Test("Hex escape for carriage return and line feed")
    func hexEscapeCRLF() throws {
        let yaml = "\"\\x0d\\x0a\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\r\n")
    }

    @Test("Multiple escape sequences in one string")
    func multipleEscapes() throws {
        let yaml = "\"\\t\\n\\r\\\\\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\t\n\r\\")
    }

    // MARK: - Invalid Escape Sequences

    @Test("Invalid escape \\c should error")
    func invalidEscapeC() throws {
        let yaml = "\"\\c\"\n"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml)
        }
    }

    @Test("Invalid hex escape \\xGG should error")
    func invalidHexEscape() throws {
        let yaml = "\"\\xGG\"\n"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml)
        }
    }

    @Test("Incomplete unicode escape should error")
    func incompleteUnicodeEscape() throws {
        let yaml = "\"\\u004\"\n"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml)
        }
    }

    @Test("Invalid escape \\q should error")
    func invalidEscapeQ() throws {
        let yaml = "\"\\q\"\n"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml)
        }
    }
}
