import Testing
@testable import YAML

// YAML 1.2.2 Specification - Directive comprehensive tests

@Suite("Spec: Directives", .tags(.spec, .tag))
struct SpecDirectiveTests {

    // MARK: - YAML Directive

    @Test("YAML 1.2 directive")
    func yamlDirective12() throws {
        let yaml = "%YAML 1.2\n---\nfoo\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "foo")
    }

    @Test("YAML 1.1 directive with warning")
    func yamlDirective11() throws {
        // Parsers should attempt to parse YAML 1.1 with a warning
        let yaml = "%YAML 1.1\n---\nfoo\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "foo")
    }

    @Test("Repeated YAML directive should error")
    func repeatedYamlDirective() throws {
        let yaml = "%YAML 1.2\n%YAML 1.2\n---\nfoo\n"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml)
        }
    }

    // MARK: - TAG Directive

    @Test("TAG directive with primary handle")
    func tagDirectivePrimary() throws {
        let yaml = "%TAG ! tag:example.com,2000:\n---\n!foo bar\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "bar")
    }

    @Test("TAG directive with named handle")
    func tagDirectiveNamed() throws {
        let yaml = "%TAG !yaml! tag:yaml.org,2002:\n---\n!yaml!str value\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "value")
    }

    @Test("Repeated TAG directive with same handle should error")
    func repeatedTagDirective() throws {
        let yaml = "%TAG ! !foo\n%TAG ! !bar\n---\nfoo\n"
        #expect(throws: YAMLError.self) {
            _ = try compose(yaml: yaml)
        }
    }

    @Test("Multiple different TAG directives")
    func multipleDifferentTagDirectives() throws {
        let yaml = "%TAG !a! tag:a.com,2000:\n%TAG !b! tag:b.com,2000:\n---\n!a!foo: !b!bar baz\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        // The scalar value should still parse correctly
        let (_, val) = map[0]
        guard case .scalar(let s) = val else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "baz")
    }

    // MARK: - Reserved Directives

    @Test("Reserved directive should be ignored with warning")
    func reservedDirective() throws {
        let yaml = "%RESERVED param1 param2\n---\nfoo\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "foo")
    }

    @Test("Multiple reserved directives")
    func multipleReservedDirectives() throws {
        let yaml = "%FOO bar\n%BAZ qux\n---\nvalue\n"
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "value")
    }
}
