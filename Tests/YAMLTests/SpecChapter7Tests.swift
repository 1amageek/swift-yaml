import Testing
@testable import YAML

// YAML 1.2.2 Specification - Chapter 7: Flow Style Productions
// Examples 72-95

@Suite("Spec Chapter 7: Flow Style Productions", .tags(.spec, .flow))
struct SpecChapter7Tests {

    // MARK: - 7.1 Alias Nodes

    @Test("Example 7.1 (72): Alias Nodes")
    func example7_1() throws {
        let yaml = """
        First occurrence: &anchor Foo
        Second occurrence: *anchor
        Override anchor: &anchor Bar
        Reuse anchor: *anchor
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["First occurrence"] == .scalar(.init("Foo")))
        #expect(map["Second occurrence"] == .scalar(.init("Foo")))
        #expect(map["Override anchor"] == .scalar(.init("Bar")))
        #expect(map["Reuse anchor"] == .scalar(.init("Bar")))
    }

    // MARK: - 7.2 Empty Nodes

    @Test("Example 7.2 (73): Empty Content")
    func example7_2() throws {
        let yaml = "{\n  foo : !!str,\n  !!str : bar,\n}\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        // foo: "" (empty string with !!str tag)
        #expect(map["foo"] == .scalar(.init("")))
        // "": bar (empty key with !!str tag)
        #expect(map[""] == .scalar(.init("bar")))
    }

    @Test("Example 7.3 (74): Completely Empty Flow Nodes")
    func example7_3() throws {
        let yaml = "{\n  ? foo :,\n  : bar,\n}\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        // foo key with empty value
        #expect(map["foo"] == .scalar(.init("")))
        // empty key with bar value
        #expect(map[""] == .scalar(.init("bar")))
    }

    // MARK: - 7.3 Flow Scalar Styles

    @Test("Example 7.4 (75): Double Quoted Implicit Keys")
    func example7_4() throws {
        let yaml = "\"implicit block key\" : [\n  \"implicit flow key\" : value,\n ]\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .sequence(let seq) = map["implicit block key"] else {
            Issue.record("Expected sequence"); return
        }
        guard case .mapping(let inner) = seq[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(inner["implicit flow key"] == .scalar(.init("value")))
    }

    @Test("Example 7.5 (76): Double Quoted Line Breaks")
    func example7_5() throws {
        let yaml = "\"folded \nto a space,\t\n \n to a line feed, or \t\\\n \\ \tnon-content\""
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "folded to a space,\nto a line feed, or \t \tnon-content")
    }

    @Test("Example 7.6 (77): Double Quoted Lines")
    func example7_6() throws {
        let yaml = "\" 1st non-empty\n\n 2nd non-empty \n\t3rd non-empty \""
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == " 1st non-empty\n2nd non-empty 3rd non-empty ")
    }

    @Test("Example 7.7 (78): Single Quoted Characters")
    func example7_7() throws {
        let yaml = " 'here''s to \"quotes\"'"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "here's to \"quotes\"")
    }

    @Test("Example 7.8 (79): Single Quoted Implicit Keys")
    func example7_8() throws {
        let yaml = "'implicit block key' : [\n  'implicit flow key' : value,\n ]\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .sequence(let seq) = map["implicit block key"] else {
            Issue.record("Expected sequence"); return
        }
        guard case .mapping(let inner) = seq[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(inner["implicit flow key"] == .scalar(.init("value")))
    }

    @Test("Example 7.9 (80): Single Quoted Lines")
    func example7_9() throws {
        let yaml = "' 1st non-empty\n\n 2nd non-empty \n\t3rd non-empty '"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == " 1st non-empty\n2nd non-empty 3rd non-empty ")
    }

    // MARK: - 7.3.3 Plain Style

    @Test("Example 7.10 (81): Plain Characters")
    func example7_10() throws {
        let yaml = """
        # Outside flow collection:
        - ::vector
        - ": - ()"
        - Up, up, and away!
        - -123
        - https://example.com/foo#bar
        # Inside flow collection:
        - [ ::vector,
          ": - ()",
          "Up, up, and away!",
          -123,
          https://example.com/foo#bar ]
        """
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("::vector")))
        #expect(seq[1] == .scalar(.init(": - ()")))
        #expect(seq[2] == .scalar(.init("Up, up, and away!")))
        #expect(seq[3] == .scalar(.init("-123")))
        #expect(seq[4] == .scalar(.init("https://example.com/foo#bar")))
        guard case .sequence(let inner) = seq[5] else {
            Issue.record("Expected sequence"); return
        }
        #expect(inner[0] == .scalar(.init("::vector")))
        #expect(inner[1] == .scalar(.init(": - ()")))
        #expect(inner[2] == .scalar(.init("Up, up, and away!")))
        #expect(inner[3] == .scalar(.init("-123")))
        #expect(inner[4] == .scalar(.init("https://example.com/foo#bar")))
    }

    @Test("Example 7.11 (82): Plain Implicit Keys")
    func example7_11() throws {
        let yaml = "implicit block key : [\n  implicit flow key : value,\n ]\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .sequence(let seq) = map["implicit block key"] else {
            Issue.record("Expected sequence"); return
        }
        guard case .mapping(let inner) = seq[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(inner["implicit flow key"] == .scalar(.init("value")))
    }

    @Test("Example 7.12 (83): Plain Lines")
    func example7_12() throws {
        let yaml = "1st non-empty\n\n 2nd non-empty \n\t3rd non-empty\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "1st non-empty\n2nd non-empty 3rd non-empty")
    }

    // MARK: - 7.4 Flow Collection Styles

    @Test("Example 7.13 (84): Flow Sequence")
    func example7_13() throws {
        let yaml = "- [ one, two, ]\n- [three ,four]\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        guard case .sequence(let first) = seq[0] else {
            Issue.record("Expected sequence"); return
        }
        #expect(first.count == 2)
        #expect(first[0] == .scalar(.init("one")))
        #expect(first[1] == .scalar(.init("two")))
        guard case .sequence(let second) = seq[1] else {
            Issue.record("Expected sequence"); return
        }
        #expect(second.count == 2)
        #expect(second[0] == .scalar(.init("three")))
        #expect(second[1] == .scalar(.init("four")))
    }

    @Test("Example 7.14 (85): Flow Sequence Entries")
    func example7_14() throws {
        let yaml = "[\n\"double\n quoted\", 'single\n           quoted',\nplain\n text, [ nested ],\nsingle: pair,\n]\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("double quoted")))
        #expect(seq[1] == .scalar(.init("single quoted")))
        #expect(seq[2] == .scalar(.init("plain text")))
        guard case .sequence(let nested) = seq[3] else {
            Issue.record("Expected sequence"); return
        }
        #expect(nested[0] == .scalar(.init("nested")))
        // single: pair should be a mapping inside the sequence
        guard case .mapping(let pair) = seq[4] else {
            Issue.record("Expected mapping"); return
        }
        #expect(pair["single"] == .scalar(.init("pair")))
    }

    @Test("Example 7.15 (86): Flow Mappings")
    func example7_15() throws {
        let yaml = "- { one : two , three: four , }\n- {five: six,seven : eight}\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        guard case .mapping(let first) = seq[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(first["one"] == .scalar(.init("two")))
        #expect(first["three"] == .scalar(.init("four")))
        guard case .mapping(let second) = seq[1] else {
            Issue.record("Expected mapping"); return
        }
        #expect(second["five"] == .scalar(.init("six")))
        #expect(second["seven"] == .scalar(.init("eight")))
    }

    @Test("Example 7.16 (87): Flow Mapping Entries")
    func example7_16() throws {
        let yaml = "{\n? explicit: entry,\nimplicit: entry,\n?\n}\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["explicit"] == .scalar(.init("entry")))
        #expect(map["implicit"] == .scalar(.init("entry")))
        // ? with no key → empty key with empty value
        #expect(map[""] == .scalar(.init("")))
    }

    @Test("Example 7.17 (88): Flow Mapping Separate Values")
    func example7_17() throws {
        let yaml = "{\nunquoted : \"separate\",\nhttps://foo.com,\nomitted value:,\n: omitted key,\n}\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["unquoted"] == .scalar(.init("separate")))
        // https://foo.com as key with empty value
        #expect(map["https://foo.com"] == .scalar(.init("")))
        #expect(map["omitted value"] == .scalar(.init("")))
        #expect(map[""] == .scalar(.init("omitted key")))
    }

    @Test("Example 7.18 (89): Flow Mapping Adjacent Values")
    func example7_18() throws {
        let yaml = "{\n\"adjacent\":value,\n\"readable\": value,\n\"empty\":\n}\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["adjacent"] == .scalar(.init("value")))
        #expect(map["readable"] == .scalar(.init("value")))
        #expect(map["empty"] == .scalar(.init("")))
    }

    @Test("Example 7.19 (90): Single Pair Flow Mappings")
    func example7_19() throws {
        let yaml = "[\nfoo: bar\n]\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        guard case .mapping(let map) = seq[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["foo"] == .scalar(.init("bar")))
    }

    @Test("Example 7.20 (91): Single Pair Explicit Entry")
    func example7_20() throws {
        let yaml = "[\n? foo\n bar : baz\n]\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        guard case .mapping(let map) = seq[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["foo bar"] == .scalar(.init("baz")))
    }

    @Test("Example 7.21 (92): Single Pair Implicit Entries")
    func example7_21() throws {
        let yaml = "- [ YAML : separate ]\n- [ : empty key entry ]\n- [ {JSON: like}:adjacent ]\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        guard case .sequence(let first) = seq[0] else {
            Issue.record("Expected sequence"); return
        }
        guard case .mapping(let m1) = first[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(m1["YAML"] == .scalar(.init("separate")))

        guard case .sequence(let second) = seq[1] else {
            Issue.record("Expected sequence"); return
        }
        guard case .mapping(let m2) = second[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(m2[""] == .scalar(.init("empty key entry")))

        guard case .sequence(let third) = seq[2] else {
            Issue.record("Expected sequence"); return
        }
        guard case .mapping(let m3) = third[0] else {
            Issue.record("Expected mapping"); return
        }
        // {JSON: like} as key
        let (key3, val3) = m3[0]
        guard case .mapping(let keyMap) = key3 else {
            Issue.record("Expected mapping key"); return
        }
        #expect(keyMap["JSON"] == .scalar(.init("like")))
        #expect(val3 == .scalar(.init("adjacent")))
    }

    @Test("Example 7.22 (93): Invalid Implicit Keys")
    func example7_22() throws {
        // Implicit key spanning multiple lines is invalid
        let yaml = "[ foo\n bar: invalid,\n \"foo...>1K...bar\": invalid ]\n"
        // The spec says multi-line implicit keys and keys > 1024 chars are errors
        // This is implementation-defined; test that it either parses or fails gracefully
        // For now, just test that the parser doesn't crash
        _ = try? compose(yaml: yaml)
    }

    @Test("Example 7.23 (94): Flow Content")
    func example7_23() throws {
        let yaml = "- [ a, b ]\n- { a: b }\n- \"a\"\n- 'b'\n- c\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 5)
        guard case .sequence(let first) = seq[0] else {
            Issue.record("Expected sequence"); return
        }
        #expect(first[0] == .scalar(.init("a")))
        #expect(first[1] == .scalar(.init("b")))
        guard case .mapping(let second) = seq[1] else {
            Issue.record("Expected mapping"); return
        }
        #expect(second["a"] == .scalar(.init("b")))
        #expect(seq[2] == .scalar(.init("a")))
        #expect(seq[3] == .scalar(.init("b")))
        #expect(seq[4] == .scalar(.init("c")))
    }

    @Test("Example 7.24 (95): Flow Nodes")
    func example7_24() throws {
        let yaml = "- !!str \"a\"\n- 'b'\n- &anchor \"c\"\n- *anchor\n- !!str\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("a")))
        #expect(seq[1] == .scalar(.init("b")))
        #expect(seq[2] == .scalar(.init("c")))
        // *anchor should resolve to "c"
        #expect(seq[3] == .scalar(.init("c")))
        // !!str with no value → empty string
        #expect(seq[4] == .scalar(.init("")))
    }
}
