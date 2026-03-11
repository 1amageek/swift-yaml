import Testing
@testable import YAML

@Suite("Edge Case Tests", .tags(.regression))
struct EdgeCaseTests {

    // MARK: - Blank lines

    @Test("Blank lines between mapping entries are ignored")
    func blankLinesBetweenEntries() throws {
        let yaml = """
        User:
          "#Directory": [app, users]

          id: string
          name: string

          email: string
        """

        let node = try compose(yaml: yaml)
        guard case .mapping(let root) = node else {
            Issue.record("Expected root mapping")
            return
        }
        guard let (_, typeDef) = root.first else {
            Issue.record("Expected first pair")
            return
        }
        guard case .mapping(let fields) = typeDef else {
            Issue.record("Expected nested mapping")
            return
        }
        // #Directory + id + name + email = 4 entries
        #expect(fields.count == 4)
    }

    // MARK: - Flow collections inside block sequences

    @Test("Flow sequence as value inside block sequence mapping")
    func flowSequenceInsideBlockSequence() throws {
        let yaml = """
        config:
          "#Index":
            - kind: scalar
              name: name_age_idx
              fields: [name, age]
              unique: false
        """

        let node = try compose(yaml: yaml)
        guard case .mapping(let root) = node else {
            Issue.record("Expected root mapping")
            return
        }
        guard let (_, configValue) = root.first else {
            Issue.record("Expected first pair")
            return
        }
        guard case .mapping(let config) = configValue else {
            Issue.record("Expected config mapping")
            return
        }

        // Find #Index
        let (_, indexValue) = config[0]
        guard case .sequence(let indexSeq) = indexValue else {
            Issue.record("Expected sequence")
            return
        }
        guard case .mapping(let entry) = indexSeq[0] else {
            Issue.record("Expected mapping entry")
            return
        }

        // Check fields: [name, age]
        var fieldsValue: Node? = nil
        for (k, v) in entry {
            if case .scalar(let s) = k, s.string == "fields" {
                fieldsValue = v
            }
        }
        guard case .sequence(let fields) = fieldsValue else {
            Issue.record("Expected fields sequence")
            return
        }
        #expect(fields.count == 2)
        #expect(fields[0] == .scalar(Node.Scalar("name")))
        #expect(fields[1] == .scalar(Node.Scalar("age")))

        // Check unique: false
        var uniqueValue: String? = nil
        for (k, v) in entry {
            if case .scalar(let s) = k, s.string == "unique",
               case .scalar(let val) = v {
                uniqueValue = val.string
            }
        }
        #expect(uniqueValue == "false")
    }

    // MARK: - Quoted strings

    @Test("Single-quoted scalar")
    func singleQuotedScalar() throws {
        let yaml = """
        name: 'hello world'
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping")
            return
        }
        let (_, value) = m[0]
        guard case .scalar(let s) = value else {
            Issue.record("Expected scalar")
            return
        }
        #expect(s.string == "hello world")
    }

    @Test("Single-quoted with escaped quote")
    func singleQuotedEscaped() throws {
        let yaml = """
        name: 'it''s a test'
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping")
            return
        }
        let (_, value) = m[0]
        guard case .scalar(let s) = value else {
            Issue.record("Expected scalar")
            return
        }
        #expect(s.string == "it's a test")
    }

    @Test("Double-quoted with escape sequences")
    func doubleQuotedEscapes() throws {
        let yaml = """
        msg: "hello\\nworld"
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping")
            return
        }
        let (_, value) = m[0]
        guard case .scalar(let s) = value else {
            Issue.record("Expected scalar")
            return
        }
        #expect(s.string == "hello\nworld")
    }

    @Test("Double-quoted with escaped quote")
    func doubleQuotedEscapedQuote() throws {
        let yaml = """
        msg: "say \\"hello\\""
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping")
            return
        }
        let (_, value) = m[0]
        guard case .scalar(let s) = value else {
            Issue.record("Expected scalar")
            return
        }
        #expect(s.string == "say \"hello\"")
    }

    // MARK: - Flow mapping

    @Test("Flow mapping")
    func flowMapping() throws {
        let yaml = """
        item: {name: test, value: 42}
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let root) = node else {
            Issue.record("Expected mapping")
            return
        }
        let (_, value) = root[0]
        guard case .mapping(let inner) = value else {
            Issue.record("Expected flow mapping")
            return
        }
        #expect(inner.count == 2)

        let (k0, v0) = inner[0]
        guard case .scalar(let key0) = k0, case .scalar(let val0) = v0 else {
            Issue.record("Expected scalars")
            return
        }
        #expect(key0.string == "name")
        #expect(val0.string == "test")
    }

    // MARK: - Empty collections

    @Test("Empty flow sequence")
    func emptyFlowSequence() throws {
        let yaml = """
        items: []
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping")
            return
        }
        let (_, value) = m[0]
        guard case .sequence(let seq) = value else {
            Issue.record("Expected sequence")
            return
        }
        #expect(seq.count == 0)
    }

    @Test("Empty flow mapping")
    func emptyFlowMapping() throws {
        let yaml = """
        data: {}
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping")
            return
        }
        let (_, value) = m[0]
        guard case .mapping(let inner) = value else {
            Issue.record("Expected mapping")
            return
        }
        #expect(inner.count == 0)
    }

    // MARK: - Nested flow collections

    @Test("Nested flow sequences")
    func nestedFlowSequences() throws {
        let yaml = """
        matrix: [[1, 2], [3, 4]]
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping")
            return
        }
        let (_, value) = m[0]
        guard case .sequence(let outer) = value else {
            Issue.record("Expected outer sequence")
            return
        }
        #expect(outer.count == 2)

        guard case .sequence(let inner0) = outer[0] else {
            Issue.record("Expected inner sequence")
            return
        }
        #expect(inner0.count == 2)
        #expect(inner0[0] == .scalar(Node.Scalar("1")))
    }

    // MARK: - Values with special characters

    @Test("Value with angle brackets")
    func angleBrackets() throws {
        let yaml = """
        type: optional<array<string>>
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping")
            return
        }
        let (_, value) = m[0]
        guard case .scalar(let s) = value else {
            Issue.record("Expected scalar")
            return
        }
        #expect(s.string == "optional<array<string>>")
    }

    @Test("Value with parentheses and colons")
    func parensAndColons() throws {
        let yaml = """
        spec: aggregation(functions:sum,avg,min,max)
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping")
            return
        }
        let (_, value) = m[0]
        guard case .scalar(let s) = value else {
            Issue.record("Expected scalar")
            return
        }
        #expect(s.string == "aggregation(functions:sum,avg,min,max)")
    }

    // MARK: - Multiple block sequences

    @Test("Multiple block sequence entries with mappings")
    func multipleSequenceEntries() throws {
        let yaml = """
        items:
          - kind: first
            name: a
          - kind: second
            name: b
          - kind: third
            name: c
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let root) = node else {
            Issue.record("Expected root mapping")
            return
        }
        let (_, value) = root[0]
        guard case .sequence(let seq) = value else {
            Issue.record("Expected sequence")
            return
        }
        #expect(seq.count == 3)

        for i in 0..<3 {
            guard case .mapping(let entry) = seq[i] else {
                Issue.record("Expected mapping at index \(i)")
                return
            }
            #expect(entry.count == 2)
        }
    }

    // MARK: - Deep nesting

    @Test("Three levels of nesting")
    func deepNesting() throws {
        let yaml = """
        level1:
          level2:
            level3:
              value: deep
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let l1) = node else {
            Issue.record("Expected mapping")
            return
        }
        guard case .mapping(let l2) = l1[0].value else {
            Issue.record("Expected mapping at level 2")
            return
        }
        guard case .mapping(let l3) = l2[0].value else {
            Issue.record("Expected mapping at level 3")
            return
        }
        guard case .mapping(let l4) = l3[0].value else {
            Issue.record("Expected mapping at level 4")
            return
        }
        let (_, val) = l4[0]
        #expect(val == .scalar(Node.Scalar("deep")))
    }

    // MARK: - Inline comments

    @Test("Comment at end of line after value")
    func inlineComment() throws {
        let yaml = """
        name: Alice # the user name
        age: 30 # in years
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping")
            return
        }
        #expect(m.count == 2)
        let (_, v0) = m[0]
        let (_, v1) = m[1]
        guard case .scalar(let s0) = v0, case .scalar(let s1) = v1 else {
            Issue.record("Expected scalars")
            return
        }
        #expect(s0.string == "Alice")
        #expect(s1.string == "30")
    }

    @Test("Full-line comment between entries")
    func fullLineComment() throws {
        let yaml = """
        name: Alice
        # this is a comment
        age: 30
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping")
            return
        }
        #expect(m.count == 2)
    }
}
