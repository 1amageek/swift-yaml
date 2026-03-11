import Testing
@testable import YAML

// YAML 1.2.2 Specification - Chapter 6: Structural Productions
// Examples 43-71

@Suite("Spec Chapter 6: Structural Productions", .tags(.spec))
struct SpecChapter6Tests {

    // MARK: - 6.1 Indentation Spaces

    @Test("Example 6.1 (43): Indentation Spaces")
    func example6_1() throws {
        let yaml = """
          # Leading comment line spaces are
           # temporary part of the content.
        Not indented:
          By one space: |
            By four
              spaces
          Flow style: [    # Leading spaces
           By two,        # in flow style
          Also by two,    # are neither
          \tStill by two   # content nor
            ]             # indentation.
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let inner) = map["Not indented"] else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let byOne) = inner["By one space"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(byOne.string == "By four\n  spaces\n")
        guard case .sequence(let flow) = inner["Flow style"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(flow[0] == .scalar(.init("By two")))
        #expect(flow[1] == .scalar(.init("Also by two")))
        #expect(flow[2] == .scalar(.init("Still by two")))
    }

    @Test("Example 6.2 (44): Indentation Indicators")
    func example6_2() throws {
        let yaml = "? a\n: -\tb\n  -  -\tc\n     - d\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .sequence(let val) = map["a"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(val[0] == .scalar(.init("b")))
        guard case .sequence(let inner) = val[1] else {
            Issue.record("Expected sequence"); return
        }
        #expect(inner[0] == .scalar(.init("c")))
        #expect(inner[1] == .scalar(.init("d")))
    }

    // MARK: - 6.2 Separation Spaces

    @Test("Example 6.3 (45): Separation Spaces")
    func example6_3() throws {
        let yaml = "- foo:\t bar\n- - baz\n  -\tbax\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        guard case .mapping(let m) = seq[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(m["foo"] == .scalar(.init("bar")))
        guard case .sequence(let inner) = seq[1] else {
            Issue.record("Expected sequence"); return
        }
        #expect(inner[0] == .scalar(.init("baz")))
        #expect(inner[1] == .scalar(.init("bax")))
    }

    // MARK: - 6.3 Line Prefixes

    @Test("Example 6.4 (46): Line Prefixes")
    func example6_4() throws {
        let yaml = "plain: text\n  lines\nquoted: \"text\n  \tlines\"\nblock: |\n  text\n  \tlines\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let plain) = map["plain"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(plain.string == "text lines")

        guard case .scalar(let quoted) = map["quoted"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(quoted.string == "text lines")

        guard case .scalar(let block) = map["block"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(block.string == "text\n\tlines\n")
    }

    // MARK: - 6.4 Empty Lines

    @Test("Example 6.5 (47): Empty Lines")
    func example6_5() throws {
        let yaml = "Folding:\n  \"Empty line\n   \t\n  as a line feed\"\nChomping: |\n  Clipped empty lines\n \n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let folding) = map["Folding"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(folding.string == "Empty line\nas a line feed")

        guard case .scalar(let chomping) = map["Chomping"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(chomping.string == "Clipped empty lines\n")
    }

    // MARK: - 6.5 Line Folding

    @Test("Example 6.6 (48): Line Folding")
    func example6_6() throws {
        let yaml = ">-\n  trimmed\n  \n \n\n  as\n  space\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "trimmed\n\n\nas space")
    }

    @Test("Example 6.7 (49): Block Folding")
    func example6_7() throws {
        let yaml = ">\n  foo \n \n  \t bar\n\n  baz\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "foo \n\n\t bar\n\nbaz\n")
    }

    @Test("Example 6.8 (50): Flow Folding")
    func example6_8() throws {
        let yaml = "\"\n  foo \n \n  \t bar\n\n  baz\n\""
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == " foo\nbar\nbaz ")
    }

    // MARK: - 6.6 Comments

    @Test("Example 6.9 (51): Separated Comment")
    func example6_9() throws {
        let yaml = "key:    # Comment\n  value\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["key"] == .scalar(.init("value")))
    }

    @Test("Example 6.10 (52): Comment Lines")
    func example6_10() throws {
        let yaml = "  # Comment\n   \n\n"
        let node = try compose(yaml: yaml)
        #expect(node == nil)
    }

    @Test("Example 6.11 (53): Multi-Line Comments")
    func example6_11() throws {
        let yaml = "key:    # Comment\n        # lines\n  value\n\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["key"] == .scalar(.init("value")))
    }

    // MARK: - 6.7 Separation Lines

    @Test("Example 6.12 (54): Separation Spaces")
    func example6_12() throws {
        let yaml = "{ first: Sammy, last: Sosa }:\n# Statistics:\n  hr:  # Home runs\n     65\n  avg: # Average\n   0.278\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        // Flow mapping as key
        let (key, val) = map[0]
        guard case .mapping(let keyMap) = key else {
            Issue.record("Expected mapping key"); return
        }
        #expect(keyMap["first"] == .scalar(.init("Sammy")))
        #expect(keyMap["last"] == .scalar(.init("Sosa")))
        guard case .mapping(let valMap) = val else {
            Issue.record("Expected mapping value"); return
        }
        #expect(valMap["hr"] == .scalar(.init("65")))
        #expect(valMap["avg"] == .scalar(.init("0.278")))
    }

    // MARK: - 6.8 Directives

    @Test("Example 6.13 (55): Reserved Directives")
    func example6_13() throws {
        // Unknown directives should be ignored with a warning
        let yaml = "%FOO  bar baz # Should be ignored\n               # with a warning.\n--- \"foo\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "foo")
    }

    @Test("Example 6.14 (56): \"YAML\" directive")
    func example6_14() throws {
        let yaml = "%YAML 1.3 # Attempt parsing\n           # with a warning\n---\n\"foo\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "foo")
    }

    @Test("Example 6.15 (57): Invalid Repeated YAML directive")
    func example6_15() throws {
        let yaml = "%YAML 1.2\n%YAML 1.1\nfoo\n"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml)
        }
    }

    @Test("Example 6.16 (58): \"TAG\" directive")
    func example6_16() throws {
        let yaml = "%TAG !yaml! tag:yaml.org,2002:\n---\n!yaml!str \"foo\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "foo")
    }

    @Test("Example 6.17 (59): Invalid Repeated TAG directive")
    func example6_17() throws {
        let yaml = "%TAG ! !foo\n%TAG ! !foo\nbar\n"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml)
        }
    }

    @Test("Example 6.18 (60): Primary Tag Handle")
    func example6_18() throws {
        let yaml = "# Private\n!foo \"bar\"\n...\n# Global\n%TAG ! tag:example.com,2000:app/\n---\n!foo \"bar\"\n"
        // First document: !foo is local tag
        // Second document: !foo resolves to tag:example.com,2000:app/foo
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "bar")
    }

    @Test("Example 6.19 (61): Secondary Tag Handle")
    func example6_19() throws {
        let yaml = "%TAG !! tag:example.com,2000:app/\n---\n!!int 1 - 3 # Interval, not integer\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "1 - 3")
    }

    @Test("Example 6.20 (62): Tag Handles")
    func example6_20() throws {
        let yaml = "%TAG !e! tag:example.com,2000:app/\n---\n!e!foo \"bar\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "bar")
    }

    @Test("Example 6.21 (63): Local Tag Prefix")
    func example6_21() throws {
        let yaml = "%TAG !m! !my-\n--- # Bulb here\n!m!light fluorescent\n...\n%TAG !m! !my-\n--- # Color here\n!m!hierarchical list\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "fluorescent")
    }

    @Test("Example 6.22 (64): Global Tag Prefix")
    func example6_22() throws {
        let yaml = "%TAG !e! tag:example.com,2000:app/\n---\n- !e!foo \"bar\"\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("bar")))
    }

    // MARK: - 6.9 Node Properties

    @Test("Example 6.23 (65): Node Properties")
    func example6_23() throws {
        let yaml = "!!str &a1 \"foo\":\n  !!str bar\n&a2 baz : *a1\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["foo"] == .scalar(.init("bar")))
        // *a1 should resolve to "foo"
        #expect(map["baz"] == .scalar(.init("foo")))
    }

    @Test("Example 6.24 (66): Verbatim Tags")
    func example6_24() throws {
        let yaml = "!<tag:yaml.org,2002:str> foo :\n  !<!bar> baz\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["foo"] == .scalar(.init("baz")))
    }

    @Test("Example 6.25 (67): Invalid Verbatim Tags")
    func example6_25() throws {
        // !<!> is invalid (empty verbatim tag)
        let yaml1 = "- !<!> foo\n"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml1)
        }
        // !<$:?> contains invalid URI characters
        let yaml2 = "- !<$:?> bar\n"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml2)
        }
    }

    @Test("Example 6.26 (68): Tag Shorthands")
    func example6_26() throws {
        let yaml = "%TAG !e! tag:example.com,2000:app/\n---\n- !local foo\n- !!str bar\n- !e!tag%21 baz\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("foo")))
        #expect(seq[1] == .scalar(.init("bar")))
        #expect(seq[2] == .scalar(.init("baz")))
    }

    @Test("Example 6.27 (69): Invalid Tag Shorthands")
    func example6_27() throws {
        // Tag shorthand with no suffix
        let yaml1 = "%TAG !e! tag:example,2000:app/\n---\n- !e! foo\n"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml1)
        }
        // Undeclared tag handle
        let yaml2 = "- !h!foo bar\n"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml2)
        }
    }

    @Test("Example 6.28 (70): Non-Specific Tags")
    func example6_28() throws {
        let yaml = "# Assuming conventional resolution:\n- \"12\"\n- 12\n- ! 12\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        // "12" → string, 12 → could be int, ! 12 → explicitly tagged as string
        #expect(seq[0] == .scalar(.init("12")))
        #expect(seq[1] == .scalar(.init("12")))
        #expect(seq[2] == .scalar(.init("12")))
    }

    @Test("Example 6.29 (71): Node Anchors")
    func example6_29() throws {
        let yaml = "First occurrence: &anchor Value\nSecond occurrence: *anchor\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["First occurrence"] == .scalar(.init("Value")))
        #expect(map["Second occurrence"] == .scalar(.init("Value")))
    }
}
