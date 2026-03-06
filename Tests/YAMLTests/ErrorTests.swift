import Testing
@testable import YAML

@Suite("Error Tests")
struct ErrorTests {

    @Test("Unterminated double-quoted string")
    func unterminatedDoubleQuote() throws {
        let yaml = """
        name: "unterminated
        """
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Unterminated single-quoted string")
    func unterminatedSingleQuote() throws {
        let yaml = """
        name: 'unterminated
        """
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Unterminated flow sequence")
    func unterminatedFlowSequence() throws {
        let yaml = """
        items: [a, b, c
        """
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }

    @Test("Unterminated flow mapping")
    func unterminatedFlowMapping() throws {
        let yaml = """
        data: {key: value
        """
        #expect(throws: YAMLError.self) {
            try compose(yaml: yaml)
        }
    }
}
