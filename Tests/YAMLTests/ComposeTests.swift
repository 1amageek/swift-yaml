import Testing
@testable import YAML

@Suite("Compose Tests")
struct ComposeTests {

    @Test("Empty input returns nil")
    func emptyInput() throws {
        let node = try compose(yaml: "")
        #expect(node == nil)
    }

    @Test("Whitespace-only input returns nil")
    func whitespaceOnly() throws {
        let node = try compose(yaml: "   \n\n  ")
        #expect(node == nil)
    }

    @Test("Comment-only input returns nil")
    func commentOnly() throws {
        let node = try compose(yaml: "# just a comment\n")
        #expect(node == nil)
    }

    @Test("Simple key-value mapping")
    func simpleMapping() throws {
        let yaml = """
        name: Alice
        age: 30
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let mapping) = node else {
            Issue.record("Expected mapping")
            return
        }
        #expect(mapping.count == 2)

        let (key0, val0) = mapping[0]
        #expect(key0 == .scalar(Node.Scalar("name")))
        #expect(val0 == .scalar(Node.Scalar("Alice")))

        let (key1, val1) = mapping[1]
        #expect(key1 == .scalar(Node.Scalar("age")))
        #expect(val1 == .scalar(Node.Scalar("30")))
    }

    @Test("Nested mapping")
    func nestedMapping() throws {
        let yaml = """
        user:
          name: Bob
          email: bob@example.com
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let outer) = node else {
            Issue.record("Expected mapping")
            return
        }
        #expect(outer.count == 1)

        let (key, value) = outer[0]
        guard case .scalar(let keyScalar) = key else {
            Issue.record("Expected scalar key")
            return
        }
        #expect(keyScalar.string == "user")

        guard case .mapping(let inner) = value else {
            Issue.record("Expected nested mapping")
            return
        }
        #expect(inner.count == 2)
    }

    @Test("Flow sequence")
    func flowSequence() throws {
        let yaml = """
        items: [one, two, three]
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let mapping) = node else {
            Issue.record("Expected mapping")
            return
        }
        let (_, value) = mapping[0]
        guard case .sequence(let seq) = value else {
            Issue.record("Expected sequence")
            return
        }
        #expect(seq.count == 3)
        #expect(seq[0] == .scalar(Node.Scalar("one")))
        #expect(seq[1] == .scalar(Node.Scalar("two")))
        #expect(seq[2] == .scalar(Node.Scalar("three")))
    }

    @Test("Block sequence")
    func blockSequence() throws {
        let yaml = """
        items:
          - alpha
          - beta
          - gamma
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let mapping) = node else {
            Issue.record("Expected mapping")
            return
        }
        let (_, value) = mapping[0]
        guard case .sequence(let seq) = value else {
            Issue.record("Expected sequence")
            return
        }
        #expect(seq.count == 3)
        #expect(seq[0] == .scalar(Node.Scalar("alpha")))
    }

    @Test("Block sequence of mappings")
    func blockSequenceOfMappings() throws {
        let yaml = """
        items:
          - name: first
            value: 1
          - name: second
            value: 2
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let outer) = node else {
            Issue.record("Expected mapping")
            return
        }
        let (_, value) = outer[0]
        guard case .sequence(let seq) = value else {
            Issue.record("Expected sequence")
            return
        }
        #expect(seq.count == 2)

        guard case .mapping(let first) = seq[0] else {
            Issue.record("Expected mapping in sequence")
            return
        }
        #expect(first.count == 2)
    }

    @Test("Quoted keys")
    func quotedKeys() throws {
        let yaml = """
        "#Directory": [app, users]
        name: test
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let mapping) = node else {
            Issue.record("Expected mapping")
            return
        }
        let (key0, val0) = mapping[0]
        guard case .scalar(let keyScalar) = key0 else {
            Issue.record("Expected scalar key")
            return
        }
        #expect(keyScalar.string == "#Directory")

        guard case .sequence(let seq) = val0 else {
            Issue.record("Expected sequence value")
            return
        }
        #expect(seq.count == 2)
        #expect(seq[0] == .scalar(Node.Scalar("app")))
        #expect(seq[1] == .scalar(Node.Scalar("users")))
    }

    @Test("Hash in plain scalar is NOT a comment")
    func hashInPlainScalar() throws {
        let yaml = """
        email: string#scalar(unique:true)
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let mapping) = node else {
            Issue.record("Expected mapping")
            return
        }
        let (_, value) = mapping[0]
        guard case .scalar(let scalar) = value else {
            Issue.record("Expected scalar value")
            return
        }
        #expect(scalar.string == "string#scalar(unique:true)")
    }

    @Test("Hash preceded by space IS a comment")
    func hashWithSpace() throws {
        let yaml = """
        name: value # this is a comment
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let mapping) = node else {
            Issue.record("Expected mapping")
            return
        }
        let (_, value) = mapping[0]
        guard case .scalar(let scalar) = value else {
            Issue.record("Expected scalar value")
            return
        }
        #expect(scalar.string == "value")
    }

    @Test("Mapping preserves key order")
    func keyOrder() throws {
        let yaml = """
        z: 1
        a: 2
        m: 3
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let mapping) = node else {
            Issue.record("Expected mapping")
            return
        }
        let keys = mapping.map { pair in
            if case .scalar(let s) = pair.key { return s.string }
            return ""
        }
        #expect(keys == ["z", "a", "m"])
    }

    @Test("Mapping .first property")
    func mappingFirst() throws {
        let yaml = """
        User:
          name: test
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let mapping) = node else {
            Issue.record("Expected mapping")
            return
        }
        guard let (firstKey, _) = mapping.first else {
            Issue.record("Expected first pair")
            return
        }
        guard case .scalar(let s) = firstKey else {
            Issue.record("Expected scalar key")
            return
        }
        #expect(s.string == "User")
    }
}
