import Testing
@testable import YAML

// YAML 1.2.2 Specification - Chapter 5: Character Productions
// Examples 29-42

@Suite("Spec Chapter 5: Character Productions", .tags(.spec, .scalar))
struct SpecChapter5Tests {

    // MARK: - 5.2 Character Encodings

    @Test("Example 5.1 (29): Byte Order Mark")
    func example5_1() throws {
        // BOM (U+FEFF) at start of stream should be ignored
        let yaml = "\u{FEFF}# Comment only.\n"
        let node = try compose(yaml: yaml)
        #expect(node == nil)
    }

    @Test("Example 5.2 (30): Invalid Byte Order Mark")
    func example5_2() throws {
        // BOM inside a document is an error
        let yaml = "- Invalid use of BOM\n\u{FEFF}\n- Inside a document."
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml)
        }
    }

    // MARK: - 5.3 Indicator Characters

    @Test("Example 5.3 (31): Block Structure Indicators")
    func example5_3() throws {
        let yaml = """
        sequence:
        - one
        - two
        mapping:
          ? sky
          : blue
          sea : green
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .sequence(let seq) = map["sequence"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("one")))
        #expect(seq[1] == .scalar(.init("two")))
        guard case .mapping(let mapping) = map["mapping"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(mapping["sky"] == .scalar(.init("blue")))
        #expect(mapping["sea"] == .scalar(.init("green")))
    }

    @Test("Example 5.4 (32): Flow Collection Indicators")
    func example5_4() throws {
        let yaml = """
        sequence: [ one, two, ]
        mapping: { sky: blue, sea: green }
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .sequence(let seq) = map["sequence"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 2)
        #expect(seq[0] == .scalar(.init("one")))
        #expect(seq[1] == .scalar(.init("two")))
        guard case .mapping(let mapping) = map["mapping"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(mapping["sky"] == .scalar(.init("blue")))
        #expect(mapping["sea"] == .scalar(.init("green")))
    }

    @Test("Example 5.5 (33): Comment Indicator")
    func example5_5() throws {
        let yaml = "# Comment only.\n\n"
        let node = try compose(yaml: yaml)
        #expect(node == nil)
    }

    @Test("Example 5.6 (34): Node Property Indicators")
    func example5_6() throws {
        // Tags (!) and anchors (&)
        let yaml = """
        anchored: !local &anchor value
        alias: *anchor
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["anchored"] == .scalar(.init("value")))
        #expect(map["alias"] == .scalar(.init("value")))
    }

    @Test("Example 5.7 (35): Block Scalar Indicators")
    func example5_7() throws {
        let yaml = """
        literal: |
          some
          text
        folded: >
          some
          text
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let literal) = map["literal"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(literal.string == "some\ntext\n")
        guard case .scalar(let folded) = map["folded"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(folded.string == "some text\n")
    }

    @Test("Example 5.8 (36): Quoted Scalar Indicators")
    func example5_8() throws {
        let yaml = """
        single: 'text'
        double: "text"
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["single"] == .scalar(.init("text")))
        #expect(map["double"] == .scalar(.init("text")))
    }

    // MARK: - 5.4 Line Break Characters

    @Test("Example 5.9 (37): Directive Indicator")
    func example5_9() throws {
        let yaml = """
        %YAML 1.2
        --- text
        """
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "text")
    }

    @Test("Example 5.10 (38): Invalid use of Reserved Indicators")
    func example5_10() throws {
        // @ and ` are reserved and cannot start a plain scalar
        let yaml1 = "commercial-at: @text"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml1)
        }
        let yaml2 = "grave-accent: `text"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml2)
        }
    }

    // MARK: - 5.4 Line Break Characters

    @Test("Example 5.11 (39): Line Break Characters")
    func example5_11() throws {
        // Line feed and carriage return
        let yaml = "|\n  Line break (no glyph)\n  Line break (no glyph)\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "Line break (no glyph)\nLine break (no glyph)\n")
    }

    @Test("Example 5.12 (40): Tabs and Spaces")
    func example5_12() throws {
        // Tabs and spaces
        let yaml = "# Tabs and spaces\n# are\n# formatted\n# using tabs.\nquoted: \"Quoted \t\"\nblock:\t|\n  void main() {\n  \tprintf(\"Hello, world!\\n\");\n  }\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["quoted"] == .scalar(.init("Quoted \t")))
        guard case .scalar(let block) = map["block"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(block.string.contains("printf"))
    }

    // MARK: - 5.6 Miscellaneous Characters

    @Test("Example 5.13 (41): Escaped Characters")
    func example5_13() throws {
        // Double-quoted escape sequences
        let yaml = """
        "Fun with \\\\
        \\" \\a \\b \\e \\f \\
        \\n \\r \\t \\v\\0\\
        \\ \\_\\N\\L\\P\\
        \\x41\\u0041\\U00000041"
        """
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        // Expected result contains:
        // \\ → \, \" → ", \a → BEL, \b → BS, \e → ESC, \f → FF
        // \n → LF, \r → CR, \t → TAB, \v → VT, \0 → NUL
        // \  → space, \_ → NBSP, \N → NEL, \L → LS, \P → PS
        // \x41 → A, \u0041 → A, \U00000041 → A
        let expected = "Fun with \\ \" \u{07} \u{08} \u{1B} \u{0C} \n \r \t \u{0B}\u{00} \u{A0}\u{85}\u{2028}\u{2029}AAA"
        #expect(s.string == expected)
    }

    @Test("Example 5.14 (42): Invalid Escaped Characters")
    func example5_14() throws {
        // Invalid escape sequences should produce errors
        let yaml1 = "Bad escapes:\n  \"\\c\n  \\xq-\""
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml1)
        }
    }
}
