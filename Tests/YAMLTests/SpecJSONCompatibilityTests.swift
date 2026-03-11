import Testing
@testable import YAML

// YAML 1.2.2 Specification - JSON Compatibility tests
// YAML 1.2 is a superset of JSON

@Suite("Spec: JSON Compatibility", .tags(.spec, .flow))
struct SpecJSONCompatibilityTests {

    @Test("JSON object")
    func jsonObject() throws {
        let yaml = "{\"key\": \"value\", \"number\": 42}\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["key"] == .scalar(.init("value")))
        #expect(map["number"] == .scalar(.init("42")))
    }

    @Test("JSON array")
    func jsonArray() throws {
        let yaml = "[\"one\", \"two\", \"three\"]\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("one")))
        #expect(seq[1] == .scalar(.init("two")))
        #expect(seq[2] == .scalar(.init("three")))
    }

    @Test("JSON nested object")
    func jsonNestedObject() throws {
        let yaml = "{\"outer\": {\"inner\": \"value\"}}\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let inner) = map["outer"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(inner["inner"] == .scalar(.init("value")))
    }

    @Test("JSON array of objects")
    func jsonArrayOfObjects() throws {
        let yaml = "[{\"a\": 1}, {\"b\": 2}]\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        guard case .mapping(let first) = seq[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(first["a"] == .scalar(.init("1")))
        guard case .mapping(let second) = seq[1] else {
            Issue.record("Expected mapping"); return
        }
        #expect(second["b"] == .scalar(.init("2")))
    }

    @Test("JSON string with escapes")
    func jsonStringEscapes() throws {
        let yaml = "\"tab:\\there\\nnewline\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "tab:\there\nnewline")
    }

    @Test("JSON string with unicode escape")
    func jsonUnicodeEscape() throws {
        let yaml = "\"\\u0048\\u0065\\u006C\\u006C\\u006F\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "Hello")
    }

    @Test("JSON null, true, false as YAML scalars")
    func jsonPrimitives() throws {
        let yaml = "[null, true, false]\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("null")))
        #expect(seq[1] == .scalar(.init("true")))
        #expect(seq[2] == .scalar(.init("false")))
    }

    @Test("JSON integers and floats")
    func jsonNumbers() throws {
        let yaml = "[0, -1, 3.14, 2.5e10, -1.2E-3]\n"
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("0")))
        #expect(seq[1] == .scalar(.init("-1")))
        #expect(seq[2] == .scalar(.init("3.14")))
        #expect(seq[3] == .scalar(.init("2.5e10")))
        #expect(seq[4] == .scalar(.init("-1.2E-3")))
    }

    @Test("JSON empty object and array")
    func jsonEmpty() throws {
        let yaml = "{\"obj\": {}, \"arr\": []}\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let obj) = map["obj"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(obj.count == 0)
        guard case .sequence(let arr) = map["arr"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(arr.count == 0)
    }

    @Test("JSON multi-line (pretty printed)")
    func jsonMultiLine() throws {
        let yaml = "{\n  \"name\": \"John\",\n  \"age\": 30,\n  \"items\": [\n    \"a\",\n    \"b\"\n  ]\n}\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["name"] == .scalar(.init("John")))
        #expect(map["age"] == .scalar(.init("30")))
        guard case .sequence(let items) = map["items"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(items[0] == .scalar(.init("a")))
        #expect(items[1] == .scalar(.init("b")))
    }

    @Test("JSON string with solidus escape")
    func jsonSolidusEscape() throws {
        let yaml = "\"\\/path\\/to\\/file\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "/path/to/file")
    }

    @Test("JSON string with backslash")
    func jsonBackslash() throws {
        let yaml = "\"C:\\\\Users\\\\test\"\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "C:\\Users\\test")
    }
}
