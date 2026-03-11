import Testing
@testable import YAML

@Suite("Error Edge Case Tests", .tags(.edgeCases))
struct ErrorEdgeCaseTests {

    // MARK: - Anchor / Alias errors

    @Test("Empty anchor name with trailing whitespace")
    func emptyAnchorNameWhitespace() {
        let yaml = "& value"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Empty anchor name at end of input")
    func emptyAnchorNameAtEnd() {
        let yaml = "key: &"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Empty alias name with trailing whitespace")
    func emptyAliasNameWhitespace() {
        let yaml = "* value"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Empty alias name at end of input")
    func emptyAliasNameAtEnd() {
        let yaml = "key: *"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Empty anchor name followed by newline")
    func emptyAnchorNameNewline() {
        let yaml = "&\nvalue"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Empty alias name followed by newline")
    func emptyAliasNameNewline() {
        let yaml = "*\nvalue"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    // MARK: - Verbatim tag errors

    @Test("Unterminated verbatim tag without closing angle bracket")
    func unterminatedVerbatimTag() {
        let yaml = "!<tag:example.com value"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Unterminated verbatim tag at end of input")
    func unterminatedVerbatimTagAtEnd() {
        let yaml = "!<tag"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Invalid character (space) in verbatim tag URI")
    func invalidCharInVerbatimTagURI() {
        let yaml = "!<tag with space> value"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Invalid character (tab) in verbatim tag URI")
    func invalidTabInVerbatimTagURI() {
        let yaml = "!<tag\twith\ttab> value"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    // MARK: - Tag shorthand errors

    @Test("Tag shorthand with empty suffix at end of input")
    func tagShorthandEmptySuffix() {
        let yaml = "!e!"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Tag shorthand with empty suffix followed by whitespace")
    func tagShorthandEmptySuffixWhitespace() {
        let yaml = "!e! value"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Undeclared tag handle")
    func undeclaredTagHandle() {
        let yaml = "!foo!bar value"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    // MARK: - Unicode escape errors

    @Test("Invalid unicode scalar escape with surrogate half \\uD800")
    func invalidUnicodeSurrogateHalf() {
        let yaml = "\"\\uD800\""
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Invalid unicode scalar escape with high surrogate \\uDBFF")
    func invalidUnicodeSurrogateHighEnd() {
        let yaml = "\"\\uDBFF\""
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Invalid unicode scalar escape with low surrogate \\uDC00")
    func invalidUnicodeSurrogateLow() {
        let yaml = "\"\\uDC00\""
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    // MARK: - Incomplete hex escape errors

    @Test("Incomplete hex escape \\x with only 1 digit")
    func incompleteHexEscapeX() {
        let yaml = "\"\\x4\""
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Incomplete hex escape \\u with only 2 digits")
    func incompleteHexEscapeU() {
        let yaml = "\"\\u00\""
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Incomplete hex escape \\U with only 4 digits")
    func incompleteHexEscapeCapitalU() {
        let yaml = "\"\\U0001\""
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Hex escape \\x at end of input inside double-quoted string")
    func hexEscapeAtEndOfInput() {
        let yaml = "\"\\x"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Invalid hex character in escape sequence")
    func invalidHexCharInEscape() {
        let yaml = "\"\\xZZ\""
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    // MARK: - Unterminated escape at end of input

    @Test("Backslash at end of double-quoted string input")
    func backslashAtEndOfInput() {
        let yaml = "\"\\"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Backslash at end of double-quoted multiline string")
    func backslashAtEndOfMultilineInput() {
        let yaml = "key: \"\\"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    // MARK: - Reserved indicators

    @Test("Reserved indicator @ in block context")
    func reservedAtSignBlock() {
        let yaml = "@value"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Reserved indicator backtick in block context")
    func reservedBacktickBlock() {
        let yaml = "`value"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Reserved indicator @ in flow sequence")
    func reservedAtSignInFlowSequence() {
        let yaml = "[@]"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Reserved indicator backtick in flow sequence")
    func reservedBacktickInFlowSequence() {
        let yaml = "[`]"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Reserved indicator @ as flow mapping key")
    func reservedAtSignInFlowMapping() {
        let yaml = "{@: v}"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Reserved indicator backtick as flow mapping value")
    func reservedBacktickInFlowMapping() {
        let yaml = "{k: `}"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    // MARK: - BOM inside document

    @Test("BOM character inside document content")
    func bomInsideDocument() {
        let yaml = "key: value\n\u{FEFF}next: data"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("BOM after document start marker")
    func bomAfterDocumentStart() {
        let yaml = "---\n\u{FEFF}key: value"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    // MARK: - Unterminated quoted strings (minimal cases)

    @Test("Unterminated single-quoted string: just opening quote")
    func unterminatedSingleQuoteMinimal() {
        let yaml = "'"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Unterminated single-quoted string with content")
    func unterminatedSingleQuoteWithContent() {
        let yaml = "'hello"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Unterminated double-quoted string: just opening quote")
    func unterminatedDoubleQuoteMinimal() {
        let yaml = "\""
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Unterminated double-quoted string with content")
    func unterminatedDoubleQuoteWithContent() {
        let yaml = "\"hello"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Unterminated single-quoted string in flow sequence")
    func unterminatedSingleQuoteInFlow() {
        let yaml = "['hello"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Unterminated double-quoted string in flow mapping")
    func unterminatedDoubleQuoteInFlow() {
        let yaml = "{\"hello"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    // MARK: - Invalid escape character

    @Test("Invalid escape character \\z in double-quoted string")
    func invalidEscapeCharZ() {
        let yaml = "\"\\z\""
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Invalid escape character \\q in double-quoted string")
    func invalidEscapeCharQ() {
        let yaml = "\"\\q\""
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Invalid escape character \\1 in double-quoted string")
    func invalidEscapeCharDigit() {
        let yaml = "\"\\1\""
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    // MARK: - Duplicate %YAML directive

    @Test("Duplicate %YAML directive in same document")
    func duplicateYAMLDirective() {
        let yaml = "%YAML 1.2\n%YAML 1.2\n---\nkey: value"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Duplicate %YAML directive with different versions")
    func duplicateYAMLDirectiveDifferentVersions() {
        let yaml = "%YAML 1.1\n%YAML 1.2\n---\nkey: value"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    // MARK: - Unterminated flow collections (minimal)

    @Test("Flow sequence: just opening bracket")
    func unterminatedFlowSequenceMinimal() {
        let yaml = "["
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Flow mapping: just opening brace")
    func unterminatedFlowMappingMinimal() {
        let yaml = "{"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Flow sequence with content but no closing bracket")
    func unterminatedFlowSequenceWithContent() {
        let yaml = "[a, b"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Flow mapping with content but no closing brace")
    func unterminatedFlowMappingWithContent() {
        let yaml = "{a: b"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Nested unterminated flow sequence")
    func nestedUnterminatedFlowSequence() {
        let yaml = "[[a"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Nested unterminated flow mapping")
    func nestedUnterminatedFlowMapping() {
        let yaml = "{{a: b}"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    // MARK: - Empty anchor/alias in flow context

    @Test("Empty anchor in flow sequence")
    func emptyAnchorInFlowSequence() {
        let yaml = "[& ]"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Empty alias in flow mapping")
    func emptyAliasInFlowMapping() {
        let yaml = "{* : v}"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    // MARK: - Unexpected end of input in flow context

    @Test("Unexpected end of input after flow entry comma")
    func unexpectedEndAfterFlowComma() {
        let yaml = "[a,"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Unexpected end of input in nested flow mapping")
    func unexpectedEndInNestedFlowMapping() {
        let yaml = "{a: {b: c}"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    // MARK: - Combined error scenarios

    @Test("Verbatim tag with newline in URI")
    func verbatimTagWithNewline() {
        // Newline causes unterminated tag since > is never found
        let yaml = "!<tag\n> value"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Empty verbatim tag")
    func emptyVerbatimTag() {
        let yaml = "!<> value"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Verbatim tag with only exclamation mark")
    func verbatimTagExclamationOnly() {
        let yaml = "!<!> value"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Reserved indicator @ as mapping value")
    func reservedAtSignAsValue() {
        let yaml = "key: @"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Reserved indicator backtick as mapping value")
    func reservedBacktickAsValue() {
        let yaml = "key: `"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Incomplete \\u escape at end of input (no closing quote)")
    func incompleteUEscapeAtEnd() {
        let yaml = "\"\\u00"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Incomplete \\U escape at end of input (no closing quote)")
    func incompleteCapitalUEscapeAtEnd() {
        let yaml = "\"\\U000000"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Duplicate %TAG directive for same handle")
    func duplicateTagDirective() {
        let yaml = "%TAG !e! tag:example.com,2000:\n%TAG !e! tag:other.com,2000:\n---\n!e!foo bar"
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }
}
