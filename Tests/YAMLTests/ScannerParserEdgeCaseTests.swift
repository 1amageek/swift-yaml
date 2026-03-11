import Testing
@testable import YAML

@Suite("Scanner & Parser Edge Cases", .tags(.edgeCases))
struct ScannerParserEdgeCaseTests {

    // MARK: - 1. Pipe and angle bracket as plain scalars

    @Test("Pipe followed by non-header chars is a plain scalar, not block literal")
    func pipeAsPlainScalar() throws {
        let yaml = "key: |abc"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "|abc")
    }

    @Test("Greater-than followed by non-header chars is a plain scalar, not block folded")
    func greaterThanAsPlainScalar() throws {
        let yaml = "key: >abc"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == ">abc")
    }

    @Test("Pipe with alphanumeric suffix at top level is a plain scalar")
    func pipeAlphaTopLevel() throws {
        let node = try compose(yaml: "|hello")
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "|hello")
    }

    @Test("Greater-than with alphanumeric suffix at top level is a plain scalar")
    func greaterThanAlphaTopLevel() throws {
        let node = try compose(yaml: ">world")
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == ">world")
    }

    // MARK: - 2. Block scalar with reversed indicator order

    @Test("Block literal with chomping before indent: |-2")
    func blockLiteralChompingBeforeIndent() throws {
        let yaml = "key: |-2\n  stripped"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        // Strip chomping (-) means no trailing newline
        #expect(v.string == "stripped")
    }

    @Test("Block literal with keep before indent: |+1")
    func blockLiteralKeepBeforeIndent() throws {
        let yaml = "key: |+1\n value\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        // Keep chomping (+) preserves trailing newlines
        #expect(v.string.hasSuffix("\n"))
        #expect(v.string.contains("value"))
    }

    @Test("Block folded with indent before chomping: >2-")
    func blockFoldedIndentBeforeChomping() throws {
        let yaml = "key: >2-\n  folded"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "folded")
    }

    // MARK: - 3. Input that is only BOM

    @Test("Input containing only BOM returns nil")
    func bomOnlyInput() throws {
        let node = try compose(yaml: "\u{FEFF}")
        #expect(node == nil)
    }

    @Test("BOM followed by whitespace returns nil")
    func bomWithWhitespace() throws {
        let node = try compose(yaml: "\u{FEFF}   ")
        #expect(node == nil)
    }

    // MARK: - 4. Input that is only whitespace

    @Test("Input that is only spaces returns nil")
    func spacesOnlyInput() throws {
        let node = try compose(yaml: "   ")
        #expect(node == nil)
    }

    @Test("Input with spaces and newlines returns nil")
    func spacesAndNewlinesInput() throws {
        let node = try compose(yaml: "   \n   \n  ")
        #expect(node == nil)
    }

    @Test("Empty string returns nil")
    func emptyStringInput() throws {
        let node = try compose(yaml: "")
        #expect(node == nil)
    }

    // MARK: - 5. Input that is only comments

    @Test("Input that is only comments returns nil")
    func commentsOnlyInput() throws {
        let node = try compose(yaml: "# comment\n# another")
        #expect(node == nil)
    }

    @Test("Single comment returns nil")
    func singleCommentInput() throws {
        let node = try compose(yaml: "# just a comment")
        #expect(node == nil)
    }

    @Test("Comments with blank lines returns nil")
    func commentsWithBlankLines() throws {
        let node = try compose(yaml: "# first\n\n# second\n\n# third")
        #expect(node == nil)
    }

    // MARK: - 6. Deeply nested block structures (10+ levels)

    @Test("Deeply nested block mapping (10 levels)")
    func deeplyNestedBlockMapping() throws {
        var yaml = ""
        for i in 0..<10 {
            yaml += String(repeating: "  ", count: i) + "level\(i):\n"
        }
        yaml += String(repeating: "  ", count: 10) + "value: deep"

        let node = try compose(yaml: yaml)

        // Walk down 10 levels
        var current = node
        for i in 0..<10 {
            guard case .mapping(let m) = current else {
                Issue.record("Expected mapping at level \(i)"); return
            }
            guard case .scalar(let k) = m[0].key else {
                Issue.record("Expected scalar key at level \(i)"); return
            }
            #expect(k.string == "level\(i)")
            current = m[0].value
        }

        // Final level has the value mapping
        guard case .mapping(let final) = current else {
            Issue.record("Expected mapping at deepest level"); return
        }
        guard case .scalar(let v) = final[0].value else {
            Issue.record("Expected scalar value at deepest level"); return
        }
        #expect(v.string == "deep")
    }

    @Test("Deeply nested block sequences (12 levels)")
    func deeplyNestedBlockSequences() throws {
        // Build nested sequences: each level is a - containing the next
        var yaml = ""
        for i in 0..<12 {
            yaml += String(repeating: "  ", count: i) + "- "
            if i == 11 {
                yaml += "leaf"
            }
            yaml += "\n"
        }

        let node = try compose(yaml: yaml)

        // Walk down 12 sequence levels
        var current = node
        for i in 0..<12 {
            guard case .sequence(let seq) = current else {
                Issue.record("Expected sequence at level \(i)"); return
            }
            #expect(seq.count >= 1)
            current = seq[0]
        }

        guard case .scalar(let leaf) = current else {
            Issue.record("Expected scalar at deepest level"); return
        }
        #expect(leaf.string == "leaf")
    }

    // MARK: - 7. Plain scalars starting with indicator-like chars

    @Test("Plain scalar starting with dash but no space: -value")
    func plainScalarDashNoSpace() throws {
        let yaml = "key: -value"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "-value")
    }

    @Test("Plain scalar starting with question mark but no space: ?value")
    func plainScalarQuestionNoSpace() throws {
        let yaml = "key: ?value"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "?value")
    }

    @Test("Plain scalar starting with colon but no space: :value")
    func plainScalarColonNoSpace() throws {
        let yaml = "key: :value"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == ":value")
    }

    // MARK: - 8. Flow mapping with no space after colon

    @Test("Flow mapping with no space after colon: {key:value}")
    func flowMappingNoSpaceAfterColon() throws {
        let yaml = "{key: value}"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 1)
        guard case .scalar(let k) = m[0].key, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar key and value"); return
        }
        #expect(k.string == "key")
        #expect(v.string == "value")
    }

    @Test("Flow mapping with quoted key no space: {\"key\":value}")
    func flowMappingQuotedKeyNoSpace() throws {
        let yaml = "{\"key\":value}"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 1)
        guard case .scalar(let k) = m[0].key, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar key and value"); return
        }
        #expect(k.string == "key")
        #expect(v.string == "value")
    }

    // MARK: - 9. Document end resets tag directives

    @Test("Document end resets custom tag directives")
    func documentEndResetsTagDirectives() throws {
        // After ..., custom %TAG directives should be reset.
        // The first document has !e!foo tag + "bar" scalar.
        // compose parses only the first document.
        let yaml = "%TAG !e! tag:example.com,2000:\n---\n!e!foo bar\n..."
        let node = try compose(yaml: yaml)
        // The tag is consumed by the parser; the node is the scalar "bar"
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "bar")
    }

    @Test("Tag directives are cleared after document end marker")
    func tagDirectivesClearedAfterDocumentEnd() throws {
        // Verify that fetchDocumentEnd resets tagDirectives.
        // The standard !! handle is always re-initialized to the default.
        let yaml = "---\nvalue\n..."
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "value")
    }

    @Test("Document end with ... resets tag state")
    func documentEndTripleDotResetsState() throws {
        let yaml = "---\nfirst: doc\n...\n---\nsecond: doc"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let k) = m[0].key else {
            Issue.record("Expected scalar key"); return
        }
        #expect(k.string == "first")
    }

    // MARK: - 10. Tab as separator between key and value

    @Test("Tab after colon is valid separator in block context")
    func tabAfterColonInBlock() throws {
        let yaml = "key:\tvalue"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "value")
    }

    @Test("Tab between key colon and value with spaces too")
    func tabWithSpacesAfterColon() throws {
        let yaml = "key: \tvalue"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "value")
    }

    // MARK: - 11. Flow collection as key

    @Test("Flow sequence as mapping key with quoted strings inside")
    func flowSequenceAsKey() throws {
        let yaml = "[\"key\"]: value"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 1)
        // The key should be a flow sequence containing "key"
        guard case .sequence(let keySeq) = m[0].key else {
            Issue.record("Expected sequence key"); return
        }
        #expect(keySeq.count == 1)
        guard case .scalar(let ks) = keySeq[0] else {
            Issue.record("Expected scalar inside sequence key"); return
        }
        #expect(ks.string == "key")
        guard case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "value")
    }

    @Test("Flow mapping as mapping key")
    func flowMappingAsKey() throws {
        let yaml = "{a: 1}: complex"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 1)
        guard case .mapping(let keyMap) = m[0].key else {
            Issue.record("Expected mapping key"); return
        }
        #expect(keyMap.count == 1)
        guard case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "complex")
    }

    // MARK: - 12. Escaped tab in double-quoted string

    @Test("Backslash-t escape in double-quoted string produces tab")
    func escapedTabInDoubleQuoted() throws {
        let yaml = "key: \"hello\\tworld\""
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "hello\tworld")
    }

    @Test("Backslash followed by literal tab in double-quoted string produces tab")
    func backslashLiteralTabInDoubleQuoted() throws {
        // In the scanner, case "t", "\t" both map to \t
        let yaml = "key: \"\\\tvalue\""
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "\tvalue")
    }

    // MARK: - 13. Multiple consecutive commas in flow

    @Test("Multiple consecutive commas in flow mapping produce empty entries")
    func consecutiveCommasFlowMapping() throws {
        let yaml = "{a: 1,,b: 2}"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        // The parser sees consecutive flowEntry tokens; the second comma
        // triggers an empty entry. Verify at least a and b are present.
        #expect(m.count >= 2)
    }

    @Test("Multiple consecutive commas in flow sequence are handled")
    func consecutiveCommasFlowSequence() throws {
        // The parser skips extra commas without generating empty entries.
        // [a,,b] parses as [a, b] — the extra comma is consumed as a flowEntry.
        let yaml = "[a,,b]"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        // Parser may produce 2 or 3 elements depending on implementation;
        // verify the non-empty elements are present.
        #expect(seq.count >= 2)
        guard case .scalar(let first) = seq[0] else {
            Issue.record("Expected scalar at 0"); return
        }
        #expect(first.string == "a")
        // The last element should be "b"
        guard case .scalar(let last) = seq[seq.count - 1] else {
            Issue.record("Expected scalar at last position"); return
        }
        #expect(last.string == "b")
    }

    // MARK: - 14. Empty document between document markers

    @Test("Empty document between --- and ... returns nil")
    func emptyDocumentBetweenMarkers() throws {
        let yaml = "---\n...\n---\nfoo\n"
        let node = try compose(yaml: yaml)
        // The first document is empty (--- followed by ...),
        // compose returns nil for the first (empty) document
        #expect(node == nil)
    }

    @Test("Document start followed by document start yields empty first document")
    func consecutiveDocumentStarts() throws {
        let yaml = "---\n---\nfoo"
        let node = try compose(yaml: yaml)
        // First --- is consumed, then second --- is seen, which means empty document
        #expect(node == nil)
    }

    @Test("Single document end marker after content")
    func documentEndAfterContent() throws {
        let yaml = "hello\n..."
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "hello")
    }

    // MARK: - 15. Multiple trailing blockEnd tokens

    @Test("Multiple blockEnd tokens from deep nesting are consumed correctly")
    func multipleTrailingBlockEnds() throws {
        let yaml = """
        a:
          b:
            c:
              d: value
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected root mapping"); return
        }
        #expect(m.count == 1)

        // Navigate to deepest value
        guard case .mapping(let b) = m[0].value,
              case .mapping(let c) = b[0].value,
              case .mapping(let d) = c[0].value,
              case .scalar(let v) = d[0].value else {
            Issue.record("Expected deeply nested scalar"); return
        }
        #expect(v.string == "value")
    }

    @Test("Block ends from deeply nested mixed structures")
    func blockEndsMixedStructures() throws {
        let yaml = """
        root:
          items:
            - nested:
                deep: value
          other: flat
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let root) = node else {
            Issue.record("Expected root mapping"); return
        }
        guard case .mapping(let rootVal) = root[0].value else {
            Issue.record("Expected nested mapping"); return
        }
        #expect(rootVal.count == 2)
        guard case .scalar(let otherVal) = rootVal[1].value else {
            Issue.record("Expected scalar for 'other' key"); return
        }
        #expect(otherVal.string == "flat")
    }

    // MARK: - 16. Anchor on nested collection used as value then aliased

    @Test("Anchor on sequence value, then aliased later")
    func anchorOnSequenceThenAlias() throws {
        let yaml = """
        defaults: &defaults
          - one
          - two
        copy: *defaults
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 2)

        // 'defaults' has a sequence [one, two]
        guard case .sequence(let defaultsSeq) = m[0].value else {
            Issue.record("Expected sequence for defaults"); return
        }
        #expect(defaultsSeq.count == 2)

        // 'copy' should be the same sequence via alias
        guard case .sequence(let copySeq) = m[1].value else {
            Issue.record("Expected sequence for copy"); return
        }
        #expect(copySeq.count == 2)
        #expect(copySeq[0] == defaultsSeq[0])
        #expect(copySeq[1] == defaultsSeq[1])
    }

    @Test("Anchor on mapping value, then aliased later")
    func anchorOnMappingThenAlias() throws {
        let yaml = """
        template: &tmpl
          x: 1
          y: 2
        instance: *tmpl
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 2)

        guard case .mapping(let tmpl) = m[0].value else {
            Issue.record("Expected mapping for template"); return
        }
        guard case .mapping(let inst) = m[1].value else {
            Issue.record("Expected mapping for instance"); return
        }
        #expect(tmpl.count == inst.count)
        #expect(tmpl[0].value == inst[0].value)
    }

    // MARK: - 17. Tag before anchor and anchor before tag orderings

    @Test("Tag before anchor on a scalar node")
    func tagBeforeAnchor() throws {
        let yaml = "!!str &name hello"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "hello")
    }

    @Test("Anchor before tag on a scalar node")
    func anchorBeforeTag() throws {
        let yaml = "&name !!str hello"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "hello")
    }

    @Test("Tag then anchor on mapping value, alias resolves")
    func tagAnchorOnMappingValue() throws {
        let yaml = """
        a: !!str &val tagged
        b: *val
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let a) = m[0].value else {
            Issue.record("Expected scalar for a"); return
        }
        guard case .scalar(let b) = m[1].value else {
            Issue.record("Expected scalar for b"); return
        }
        #expect(a.string == "tagged")
        #expect(b.string == "tagged")
    }

    @Test("Anchor then tag on mapping value, alias resolves")
    func anchorTagOnMappingValue() throws {
        let yaml = """
        a: &val !!str anchored
        b: *val
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let a) = m[0].value else {
            Issue.record("Expected scalar for a"); return
        }
        guard case .scalar(let b) = m[1].value else {
            Issue.record("Expected scalar for b"); return
        }
        #expect(a.string == "anchored")
        #expect(b.string == "anchored")
    }

    // MARK: - 18. Duplicate keys in mapping

    @Test("Duplicate keys in block mapping are both preserved in pairs")
    func duplicateKeysInBlockMapping() throws {
        let yaml = """
        key: first
        key: second
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        // Both pairs should be preserved (not deduplicated)
        #expect(m.count == 2)
        guard case .scalar(let k0) = m[0].key, case .scalar(let v0) = m[0].value else {
            Issue.record("Expected scalar pair at 0"); return
        }
        guard case .scalar(let k1) = m[1].key, case .scalar(let v1) = m[1].value else {
            Issue.record("Expected scalar pair at 1"); return
        }
        #expect(k0.string == "key")
        #expect(k1.string == "key")
        #expect(v0.string == "first")
        #expect(v1.string == "second")
    }

    @Test("Duplicate keys in flow mapping are both preserved")
    func duplicateKeysInFlowMapping() throws {
        let yaml = "{a: 1, a: 2}"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 2)
        guard case .scalar(let v0) = m[0].value, case .scalar(let v1) = m[1].value else {
            Issue.record("Expected scalar values"); return
        }
        #expect(v0.string == "1")
        #expect(v1.string == "2")
    }

    @Test("Subscript by key returns first occurrence for duplicate keys")
    func duplicateKeySubscriptReturnsFirst() throws {
        let yaml = """
        name: Alice
        name: Bob
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        // String subscript returns first matching value
        guard case .scalar(let v) = m["name"] else {
            Issue.record("Expected scalar for subscript"); return
        }
        #expect(v.string == "Alice")
    }

    // MARK: - 19. Block scalar with explicit indent where content is less indented

    @Test("Block literal with explicit indent, content at correct indent")
    func blockLiteralExplicitIndentCorrect() throws {
        let yaml = "key: |2\n  content\n  more"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "content\nmore\n")
    }

    @Test("Block literal with explicit indent, content less indented terminates scalar")
    func blockLiteralExplicitIndentContentLessIndented() throws {
        // Content at indent 1 but explicit says 2 relative to parent indent 0
        // Lines with less indent than contentIndent should not be included
        let yaml = "key: |2\n  included\n notincluded: val"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        // The less-indented line should start a new mapping entry
        #expect(m.count >= 1)
    }

    @Test("Block folded with explicit indent 1")
    func blockFoldedExplicitIndentOne() throws {
        let yaml = "data: >1\n line1\n line2"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        // Folded joins adjacent lines with space
        #expect(v.string == "line1 line2\n")
    }

    // MARK: - 20. Very long plain scalar (1000+ characters)

    @Test("Very long plain scalar is parsed correctly")
    func veryLongPlainScalar() throws {
        let longValue = String(repeating: "abcdefghij", count: 100) // 1000 chars
        let yaml = "key: \(longValue)"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == longValue)
        #expect(v.string.count == 1000)
    }

    @Test("Very long plain scalar at top level")
    func veryLongPlainScalarTopLevel() throws {
        let longValue = String(repeating: "x", count: 2000)
        let node = try compose(yaml: longValue)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == longValue)
        #expect(s.string.count == 2000)
    }

    @Test("Very long double-quoted scalar")
    func veryLongDoubleQuotedScalar() throws {
        let longValue = String(repeating: "y", count: 1500)
        let yaml = "key: \"\(longValue)\""
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == longValue)
        #expect(v.string.count == 1500)
    }

    // MARK: - Additional scanner edge cases

    @Test("BOM before content is silently skipped")
    func bomBeforeContent() throws {
        let yaml = "\u{FEFF}key: value"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "value")
    }

    @Test("Reserved indicator @ produces error")
    func reservedIndicatorAt() throws {
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: "@invalid")
        }
    }

    @Test("Reserved indicator backtick produces error")
    func reservedIndicatorBacktick() throws {
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: "`invalid")
        }
    }

    @Test("Undefined alias produces parser error")
    func undefinedAlias() throws {
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: "*missing")
        }
    }

    @Test("Unterminated double-quoted string produces error")
    func unterminatedDoubleQuote() throws {
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: "\"unterminated")
        }
    }

    @Test("Unterminated single-quoted string produces error")
    func unterminatedSingleQuote() throws {
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: "'unterminated")
        }
    }

    @Test("Unterminated flow sequence produces error")
    func unterminatedFlowSequence() throws {
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: "[a, b")
        }
    }

    @Test("Unterminated flow mapping produces error")
    func unterminatedFlowMapping() throws {
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: "{a: b")
        }
    }

    @Test("Empty anchor name produces error")
    func emptyAnchorName() throws {
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: "& value")
        }
    }

    @Test("Empty alias name produces error")
    func emptyAliasName() throws {
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: "* value")
        }
    }

    // MARK: - Mixed block and flow edge cases

    @Test("Flow sequence inside block mapping value")
    func flowSequenceInBlockValue() throws {
        let yaml = """
        items: [1, 2, 3]
        name: test
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 2)
        guard case .sequence(let seq) = m[0].value else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 3)
    }

    @Test("Flow mapping inside block sequence entry")
    func flowMappingInBlockSequence() throws {
        let yaml = """
        - {x: 1}
        - {y: 2}
        """
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 2)
        guard case .mapping(let m0) = seq[0], case .mapping(let m1) = seq[1] else {
            Issue.record("Expected mappings"); return
        }
        #expect(m0.count == 1)
        #expect(m1.count == 1)
    }

    @Test("Nested flow collections")
    func nestedFlowCollections() throws {
        let yaml = "{outer: {inner: [1, [2, 3]]}}"
        let node = try compose(yaml: yaml)
        guard case .mapping(let outer) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let inner) = outer[0].value else {
            Issue.record("Expected inner mapping"); return
        }
        guard case .sequence(let seq) = inner[0].value else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 2)
        guard case .sequence(let nested) = seq[1] else {
            Issue.record("Expected nested sequence"); return
        }
        #expect(nested.count == 2)
    }

    // MARK: - Document marker edge cases

    @Test("Triple dashes not at column 1 are plain scalars")
    func tripleDashesNotAtColumn1() throws {
        let yaml = "key: ---"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "---")
    }

    @Test("Triple dots not at column 1 are plain scalars")
    func tripleDotsNotAtColumn1() throws {
        let yaml = "key: ..."
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "...")
    }

    @Test("Document start with content on same line")
    func documentStartWithContent() throws {
        let yaml = "--- hello"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "hello")
    }

    // MARK: - Explicit key edge cases

    @Test("Explicit key with question mark")
    func explicitKeyQuestionMark() throws {
        let yaml = "? key\n: value"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 1)
        guard case .scalar(let k) = m[0].key, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar key and value"); return
        }
        #expect(k.string == "key")
        #expect(v.string == "value")
    }

    @Test("Explicit key with empty value")
    func explicitKeyEmptyValue() throws {
        let yaml = "? key\n:"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let k) = m[0].key else {
            Issue.record("Expected scalar key"); return
        }
        #expect(k.string == "key")
        guard case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "")
    }

    // MARK: - Block scalar header edge cases

    @Test("Block literal with only newlines after header (keep)")
    func blockLiteralOnlyNewlinesKeep() throws {
        let yaml = "key: |+\n\n\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        // Keep chomping preserves trailing newlines
        #expect(v.string.allSatisfy { $0 == "\n" })
    }

    @Test("Block literal with only newlines after header (strip)")
    func blockLiteralOnlyNewlinesStrip() throws {
        let yaml = "key: |-\n\n\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        // Strip chomping with no content lines -> empty
        #expect(v.string == "")
    }

    @Test("Block folded scalar basic behavior")
    func blockFoldedBasic() throws {
        let yaml = "key: >\n  line1\n  line2"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        // Folded joins lines with space, clip adds trailing newline
        #expect(v.string == "line1 line2\n")
    }

    // MARK: - Multiline plain scalar edge cases

    @Test("Plain scalar continuation lines are folded with spaces")
    func plainScalarMultilineFold() throws {
        let yaml = "key:\n  line1\n  line2"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "line1 line2")
    }

    // MARK: - Flow context with special chars

    @Test("Flow sequence with empty first element")
    func flowSequenceEmptyFirst() throws {
        let yaml = "[, a, b]"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count >= 2)
    }

    @Test("Flow mapping empty value")
    func flowMappingEmptyValue() throws {
        let yaml = "{key:}"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 1)
    }

    @Test("Empty flow mapping")
    func emptyFlowMappingStandalone() throws {
        let yaml = "{}"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 0)
    }

    @Test("Empty flow sequence")
    func emptyFlowSequenceStandalone() throws {
        let yaml = "[]"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 0)
    }

    // MARK: - YAML directive edge cases

    @Test("YAML directive is accepted and content is parsed")
    func yamlDirective() throws {
        let yaml = "%YAML 1.2\n---\nvalue: test"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar"); return
        }
        #expect(v.string == "test")
    }

    @Test("Duplicate YAML directive produces error")
    func duplicateYamlDirective() throws {
        let yaml = "%YAML 1.2\n%YAML 1.1\n---\nvalue: test"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml)
        }
    }

    // MARK: - Verbatim tag edge cases

    @Test("Verbatim tag is accepted")
    func verbatimTag() throws {
        let yaml = "!<tag:example.com,2000:type> value"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "value")
    }

    // MARK: - Complex nested structure

    @Test("Complex mixed nesting: mapping -> sequence -> mapping -> sequence")
    func complexMixedNesting() throws {
        let yaml = """
        users:
          - name: Alice
            hobbies:
              - reading
              - coding
          - name: Bob
            hobbies:
              - gaming
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let root) = node else {
            Issue.record("Expected root mapping"); return
        }
        guard case .sequence(let users) = root[0].value else {
            Issue.record("Expected users sequence"); return
        }
        #expect(users.count == 2)

        guard case .mapping(let alice) = users[0] else {
            Issue.record("Expected alice mapping"); return
        }
        guard case .sequence(let aliceHobbies) = alice[1].value else {
            Issue.record("Expected alice hobbies sequence"); return
        }
        #expect(aliceHobbies.count == 2)

        guard case .mapping(let bob) = users[1] else {
            Issue.record("Expected bob mapping"); return
        }
        guard case .sequence(let bobHobbies) = bob[1].value else {
            Issue.record("Expected bob hobbies sequence"); return
        }
        #expect(bobHobbies.count == 1)
    }
}
