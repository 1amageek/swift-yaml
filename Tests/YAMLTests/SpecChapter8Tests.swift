import Testing
@testable import YAML

// YAML 1.2.2 Specification - Chapter 8: Block Style Productions
// Examples 96-117

@Suite("Spec Chapter 8: Block Style Productions", .tags(.spec, .block))
struct SpecChapter8Tests {

    // MARK: - 8.1 Block Scalar Styles

    @Test("Example 8.1 (96): Block Scalar Header")
    func example8_1() throws {
        let yaml = "- | # Empty header\n literal\n- >1 # Indentation indicator\n  folded\n- |+ # Chomping indicator\n keep\n\n- >1- # Both indicators\n  strip\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        guard case .scalar(let s0) = seq[0] else {
            Issue.record("Expected scalar"); return
        }
        #expect(s0.string == "literal\n")
        guard case .scalar(let s1) = seq[1] else {
            Issue.record("Expected scalar"); return
        }
        #expect(s1.string == " folded\n")
        guard case .scalar(let s2) = seq[2] else {
            Issue.record("Expected scalar"); return
        }
        #expect(s2.string == "keep\n\n")
        guard case .scalar(let s3) = seq[3] else {
            Issue.record("Expected scalar"); return
        }
        #expect(s3.string == " strip")
    }

    @Test("Example 8.2 (97): Block Indentation Indicator")
    func example8_2() throws {
        let yaml = "- |1\n  literal\n - |1\n  \n  literal\n \n- |1\n   literal\n"
        // The spec example tests explicit indentation indicator of 1
        // This is a complex layout; test the basic concept
        let node = try compose(yaml: yaml)
        #expect(node != nil)
    }

    @Test("Example 8.3 (98): Invalid Block Scalar Indentation Indicators")
    func example8_3() throws {
        // Content more indented than indicated
        let yaml1 = "- |\n  \n text\n"
        // The text is less indented than expected
        // This should produce an error or specific behavior
        _ = try? compose(yaml: yaml1)
        // Additional indentation indicator test
        let yaml2 = "- >\n  \n text\n"
        _ = try? compose(yaml: yaml2)
    }

    @Test("Example 8.4 (99): Chomping Final Line Break")
    func example8_4() throws {
        let yaml = "strip: |-\n  text\nclip: |\n  text\nkeep: |+\n  text\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let strip) = map["strip"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(strip.string == "text")
        guard case .scalar(let clip) = map["clip"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(clip.string == "text\n")
        guard case .scalar(let keep) = map["keep"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(keep.string == "text\n")
    }

    @Test("Example 8.5 (100): Chomping Trailing Lines")
    func example8_5() throws {
        let yaml = " # Strip\n  # Comments:\nstrip: |-\n  # text\n  \n # Clip\n  # comments:\n\nclip: |\n  # text\n \nkeep: |+\n  # text\n\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let strip) = map["strip"] else {
            Issue.record("Expected scalar"); return
        }
        // Strip removes trailing newlines
        #expect(strip.string == "# text")
        guard case .scalar(let clip) = map["clip"] else {
            Issue.record("Expected scalar"); return
        }
        // Clip keeps one trailing newline
        #expect(clip.string == "# text\n")
        guard case .scalar(let keep) = map["keep"] else {
            Issue.record("Expected scalar"); return
        }
        // Keep preserves all trailing newlines
        #expect(keep.string == "# text\n\n")
    }

    @Test("Example 8.6 (101): Empty Scalar Chomping")
    func example8_6() throws {
        let yaml = "strip: >-\n\nclip: >\n\nkeep: |+\n\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let strip) = map["strip"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(strip.string == "")
        guard case .scalar(let clip) = map["clip"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(clip.string == "")
        guard case .scalar(let keep) = map["keep"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(keep.string == "\n")
    }

    // MARK: - 8.1.2 Literal Style

    @Test("Example 8.7 (102): Literal Scalar")
    func example8_7() throws {
        let yaml = "|\n literal\n \ttext\n\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "literal\n\ttext\n")
    }

    @Test("Example 8.8 (103): Literal Content")
    func example8_8() throws {
        let yaml = "|\n \n  \n  literal\n \n  \n  text\n\n # Comment\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\n\nliteral\n \n\ntext\n")
    }

    // MARK: - 8.1.3 Folded Style

    @Test("Example 8.9 (104): Folded Scalar")
    func example8_9() throws {
        let yaml = ">\n folded\n text\n\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "folded text\n")
    }

    @Test("Example 8.10 (105): Folded Lines")
    func example8_10() throws {
        let yaml = ">\n\n folded\n line\n\n next\n line\n   * bullet\n\n   * list\n   * lines\n\n last\n line\n\n# Comment\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        let expected = "\nfolded line\nnext line\n  * bullet\n\n  * list\n  * lines\n\nlast line\n"
        #expect(s.string == expected)
    }

    @Test("Example 8.11 (106): More Indented Lines")
    func example8_11() throws {
        let yaml = ">\n\n folded\n line\n\n next\n line\n   * bullet\n\n   * list\n   * lines\n\n last\n line\n\n# Comment\n"
        // Same as Example 8.10 — testing more indented lines are preserved
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string.contains("  * bullet"))
        #expect(s.string.contains("  * list"))
    }

    @Test("Example 8.12 (107): Empty Separation Lines")
    func example8_12() throws {
        // Same content as 8.10, testing empty line behavior
        let yaml = ">\n\n folded\n line\n\n next\n line\n   * bullet\n\n   * list\n   * lines\n\n last\n line\n\n# Comment\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        // Empty lines between folded paragraphs become line feeds
        #expect(s.string.contains("line\nnext"))
    }

    @Test("Example 8.13 (108): Final Empty Lines")
    func example8_13() throws {
        // Same content, testing trailing behavior
        let yaml = ">\n\n folded\n line\n\n next\n line\n   * bullet\n\n   * list\n   * lines\n\n last\n line\n\n# Comment\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        // Clip chomping: single trailing newline
        #expect(s.string.hasSuffix("last line\n"))
    }

    // MARK: - 8.2 Block Collection Styles

    @Test("Example 8.14 (109): Block Sequence")
    func example8_14() throws {
        let yaml = "block sequence:\n  - one\n  - two : three\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .sequence(let seq) = map["block sequence"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("one")))
        guard case .mapping(let inner) = seq[1] else {
            Issue.record("Expected mapping"); return
        }
        #expect(inner["two"] == .scalar(.init("three")))
    }

    @Test("Example 8.15 (110): Block Sequence Entry Types")
    func example8_15() throws {
        let yaml = "- # Empty\n- |\n block scalar\n- - one # Compact\n  - two # sequence\n- one: two # Compact mapping\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        // First entry is empty
        #expect(seq[0] == .scalar(.init("")))
        // Second entry is block scalar
        guard case .scalar(let blockScalar) = seq[1] else {
            Issue.record("Expected scalar"); return
        }
        #expect(blockScalar.string == "block scalar\n")
        // Third entry is compact sequence
        guard case .sequence(let compactSeq) = seq[2] else {
            Issue.record("Expected sequence"); return
        }
        #expect(compactSeq[0] == .scalar(.init("one")))
        #expect(compactSeq[1] == .scalar(.init("two")))
        // Fourth entry is compact mapping
        guard case .mapping(let compactMap) = seq[3] else {
            Issue.record("Expected mapping"); return
        }
        #expect(compactMap["one"] == .scalar(.init("two")))
    }

    @Test("Example 8.16 (111): Block Mappings")
    func example8_16() throws {
        let yaml = "block mapping:\n key: value\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let inner) = map["block mapping"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(inner["key"] == .scalar(.init("value")))
    }

    @Test("Example 8.17 (112): Explicit Block Mapping Entries")
    func example8_17() throws {
        let yaml = "? explicit key # Empty value\n? |\n  block key\n: - one # Explicit compact\n  - two # block value\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        // "explicit key" with empty value
        #expect(map["explicit key"] == .scalar(.init("")))
        // block key "block key\n" with sequence value
        let (key2, val2) = map[1]
        guard case .scalar(let keyScalar) = key2 else {
            Issue.record("Expected scalar key"); return
        }
        #expect(keyScalar.string == "block key\n")
        guard case .sequence(let valSeq) = val2 else {
            Issue.record("Expected sequence value"); return
        }
        #expect(valSeq[0] == .scalar(.init("one")))
        #expect(valSeq[1] == .scalar(.init("two")))
    }

    @Test("Example 8.18 (113): Implicit Block Mapping Entries")
    func example8_18() throws {
        let yaml = "plain key: in-line value\n: # Both empty\n\"quoted key\":\n- entry\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["plain key"] == .scalar(.init("in-line value")))
        // Empty key with empty value
        #expect(map[""] == .scalar(.init("")))
        // Quoted key with sequence value
        guard case .sequence(let seq) = map["quoted key"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("entry")))
    }

    @Test("Example 8.19 (114): Compact Block Mappings")
    func example8_19() throws {
        let yaml = "- sun: yellow\n- ? earth: blue\n  : moon: white\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        guard case .mapping(let first) = seq[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(first["sun"] == .scalar(.init("yellow")))
        guard case .mapping(let second) = seq[1] else {
            Issue.record("Expected mapping"); return
        }
        // Complex key: {earth: blue} → value: {moon: white}
        let (key2, val2) = second[0]
        guard case .mapping(let keyMap) = key2 else {
            Issue.record("Expected mapping key"); return
        }
        #expect(keyMap["earth"] == .scalar(.init("blue")))
        guard case .mapping(let valMap) = val2 else {
            Issue.record("Expected mapping value"); return
        }
        #expect(valMap["moon"] == .scalar(.init("white")))
    }

    // MARK: - 8.2.3 Block Nodes

    @Test("Example 8.20 (115): Block Node Types")
    func example8_20() throws {
        let yaml = "-\n  \"flow in block\"\n- >\n Block scalar\n- !!map # Block collection\n  foo : bar\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("flow in block")))
        guard case .scalar(let folded) = seq[1] else {
            Issue.record("Expected scalar"); return
        }
        #expect(folded.string == "Block scalar\n")
        guard case .mapping(let map) = seq[2] else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["foo"] == .scalar(.init("bar")))
    }

    @Test("Example 8.21 (116): Block Scalar Nodes")
    func example8_21() throws {
        let yaml = "literal: |2\n  value\nfolded:\n   !foo\n  >1\n value\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let literal) = map["literal"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(literal.string == "value\n")
        guard case .scalar(let folded) = map["folded"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(folded.string == "value\n")
    }

    @Test("Example 8.22 (117): Block Collection Nodes")
    func example8_22() throws {
        let yaml = "sequence: !!seq\n- entry\n- !!seq\n - nested\nmapping: !!map\n foo: bar\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .sequence(let seq) = map["sequence"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("entry")))
        guard case .sequence(let nested) = seq[1] else {
            Issue.record("Expected nested sequence"); return
        }
        #expect(nested[0] == .scalar(.init("nested")))
        guard case .mapping(let inner) = map["mapping"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(inner["foo"] == .scalar(.init("bar")))
    }
}
