import Testing
@testable import YAML

@Suite("Line Ending Tests")
struct LineEndingTests {

    @Test("Windows line endings (CRLF)")
    func crlfLineEndings() throws {
        let yaml = "name: Alice\r\nage: 30\r\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 2)
        guard case .scalar(let v0) = m[0].value, case .scalar(let v1) = m[1].value else {
            Issue.record("Expected scalars"); return
        }
        #expect(v0.string == "Alice")
        #expect(v1.string == "30")
    }

    @Test("CR-only line endings")
    func crOnlyLineEndings() throws {
        let yaml = "name: Alice\rage: 30\r"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 2)
    }

    @Test("Mixed line endings")
    func mixedLineEndings() throws {
        let yaml = "a: 1\nb: 2\r\nc: 3\r"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 3)
    }

    @Test("CRLF in nested mapping")
    func crlfNested() throws {
        let yaml = "parent:\r\n  child: value\r\n  other: test\r\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let inner) = m[0].value else {
            Issue.record("Expected nested mapping"); return
        }
        #expect(inner.count == 2)
    }
}
