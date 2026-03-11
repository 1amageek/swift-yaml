import Testing
@testable import YAML

@Suite("Scalar Edge Cases", .tags(.regression, .scalar))
struct ScalarEdgeCaseTests {

    // MARK: - Colon in values

    @Test("URL with port is a single scalar value")
    func urlWithPort() throws {
        let yaml = "url: http://example.com:8080/path"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "http://example.com:8080/path")
    }

    @Test("Time format with colons")
    func timeFormat() throws {
        let yaml = "time: 12:30:00"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "12:30:00")
    }

    @Test("Colon without trailing space is part of value")
    func colonNoSpace() throws {
        let yaml = "key: value:nospace"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "value:nospace")
    }

    // MARK: - Hash in various contexts

    @Test("Hash immediately after value (no space)")
    func hashNoSpace() throws {
        let yaml = "key: value#tag"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "value#tag")
    }

    @Test("Hash inside double-quoted string is literal")
    func hashInDoubleQuote() throws {
        let yaml = """
        key: "value # not a comment"
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "value # not a comment")
    }

    @Test("Hash inside single-quoted string is literal")
    func hashInSingleQuote() throws {
        let yaml = """
        key: 'value # not a comment'
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "value # not a comment")
    }

    @Test("URL with fragment")
    func urlWithFragment() throws {
        let yaml = "url: http://example.com/page#section"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar value"); return
        }
        #expect(v.string == "http://example.com/page#section")
    }

    // MARK: - Empty and missing values

    @Test("Key with no value")
    func keyNoValue() throws {
        let yaml = """
        key1:
        key2: value
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 2)
        // key1 has empty value
        guard case .scalar(let v1) = m[0].value else {
            Issue.record("Expected scalar for empty value"); return
        }
        #expect(v1.string == "")
    }

    // MARK: - Boolean-like and number-like scalars

    @Test("true/false are plain strings")
    func boolLikeValues() throws {
        let yaml = """
        enabled: true
        disabled: false
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let v0) = m[0].value, case .scalar(let v1) = m[1].value else {
            Issue.record("Expected scalars"); return
        }
        #expect(v0.string == "true")
        #expect(v1.string == "false")
    }

    @Test("Numbers are plain strings")
    func numericValues() throws {
        let yaml = """
        int: 42
        float: 3.14
        negative: -7
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let v0) = m[0].value,
              case .scalar(let v1) = m[1].value,
              case .scalar(let v2) = m[2].value else {
            Issue.record("Expected scalars"); return
        }
        #expect(v0.string == "42")
        #expect(v1.string == "3.14")
        #expect(v2.string == "-7")
    }

    @Test("null/~ are plain strings")
    func nullLikeValues() throws {
        let yaml = """
        a: null
        b: ~
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let v0) = m[0].value, case .scalar(let v1) = m[1].value else {
            Issue.record("Expected scalars"); return
        }
        #expect(v0.string == "null")
        #expect(v1.string == "~")
    }

    // MARK: - Trailing whitespace

    @Test("Trailing spaces on value are trimmed")
    func trailingSpaces() throws {
        let yaml = "name: Alice   "
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let v) = m[0].value else {
            Issue.record("Expected scalar"); return
        }
        #expect(v.string == "Alice")
    }

    // MARK: - Unicode

    @Test("Unicode characters in values")
    func unicodeValues() throws {
        let yaml = """
        name: 日本語テスト
        emoji: 🎉✨
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let v0) = m[0].value, case .scalar(let v1) = m[1].value else {
            Issue.record("Expected scalars"); return
        }
        #expect(v0.string == "日本語テスト")
        #expect(v1.string == "🎉✨")
    }

    @Test("Unicode in keys")
    func unicodeKeys() throws {
        let yaml = """
        名前: Alice
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node, case .scalar(let k) = m[0].key else {
            Issue.record("Expected scalar key"); return
        }
        #expect(k.string == "名前")
    }
}
