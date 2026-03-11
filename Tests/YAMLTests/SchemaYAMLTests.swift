import Testing
@testable import YAML

@Suite("Schema YAML Tests - Real database-framework YAML patterns", .tags(.regression))
struct SchemaYAMLTests {

    @Test("Simple schema with scalar index")
    func simpleSchema() throws {
        let yaml = """
        User:
          "#Directory": [app, users]
          id: string
          name: string#scalar(unique:true)
          email: string#scalar
          age: int
        """

        let node = try compose(yaml: yaml)
        guard case .mapping(let root) = node else {
            Issue.record("Expected root mapping")
            return
        }

        // Root has one key: "User"
        guard let (typeNameNode, typeDefNode) = root.first else {
            Issue.record("Expected first pair")
            return
        }
        guard case .scalar(let typeName) = typeNameNode else {
            Issue.record("Expected scalar type name")
            return
        }
        #expect(typeName.string == "User")

        // Type definition is a mapping
        guard case .mapping(let typeDef) = typeDefNode else {
            Issue.record("Expected type definition mapping")
            return
        }

        // Iterate and check keys
        var keys: [String] = []
        for (keyNode, _) in typeDef {
            if case .scalar(let s) = keyNode {
                keys.append(s.string)
            }
        }
        #expect(keys == ["#Directory", "id", "name", "email", "age"])

        // Check #Directory value is flow sequence
        let (_, dirValue) = typeDef[0]
        guard case .sequence(let dirSeq) = dirValue else {
            Issue.record("Expected directory sequence")
            return
        }
        #expect(dirSeq.count == 2)
        #expect(dirSeq[0] == .scalar(Node.Scalar("app")))
        #expect(dirSeq[1] == .scalar(Node.Scalar("users")))

        // Check field with inline index annotation
        let (_, nameValue) = typeDef[2]
        guard case .scalar(let nameScalar) = nameValue else {
            Issue.record("Expected scalar value")
            return
        }
        #expect(nameScalar.string == "string#scalar(unique:true)")
    }

    @Test("Schema with graph index block sequence")
    func graphIndex() throws {
        let yaml = """
        Edge:
          "#Directory": [graphs, social]
          id: string
          from: string
          label: string
          target: string
          weight: double
          "#Index":
            - kind: graph
              name: social_graph
              from: from
              edge: label
              to: target
              strategy: adjacency
        """

        let node = try compose(yaml: yaml)
        guard case .mapping(let root) = node else {
            Issue.record("Expected root mapping")
            return
        }

        guard let (typeNameNode, typeDefNode) = root.first else {
            Issue.record("Expected first pair")
            return
        }
        guard case .scalar(let typeName) = typeNameNode else {
            Issue.record("Expected scalar type name")
            return
        }
        #expect(typeName.string == "Edge")

        guard case .mapping(let typeDef) = typeDefNode else {
            Issue.record("Expected type definition mapping")
            return
        }

        // Find #Index entry
        var indexNode: Node? = nil
        for (keyNode, valueNode) in typeDef {
            if case .scalar(let s) = keyNode, s.string == "#Index" {
                indexNode = valueNode
            }
        }

        guard let indexValue = indexNode else {
            Issue.record("Expected #Index key")
            return
        }

        guard case .sequence(let indexSeq) = indexValue else {
            Issue.record("Expected #Index to be a sequence")
            return
        }
        #expect(indexSeq.count == 1)

        // First index entry is a mapping
        guard case .mapping(let indexMapping) = indexSeq[0] else {
            Issue.record("Expected index entry to be a mapping")
            return
        }

        // Check kind
        var indexFields: [String: String] = [:]
        for (keyNode, valueNode) in indexMapping {
            if case .scalar(let k) = keyNode, case .scalar(let v) = valueNode {
                indexFields[k.string] = v.string
            }
        }

        #expect(indexFields["kind"] == "graph")
        #expect(indexFields["name"] == "social_graph")
        #expect(indexFields["from"] == "from")
        #expect(indexFields["strategy"] == "adjacency")
    }

    @Test("Dynamic directory with mixed components")
    func dynamicDirectory() throws {
        let yaml = """
        Order:
          "#Directory":
            - orders
            - field: tenantId
          id: string
          amount: double
        """

        let node = try compose(yaml: yaml)
        guard case .mapping(let root) = node else {
            Issue.record("Expected root mapping")
            return
        }
        guard let (_, typeDefNode) = root.first else {
            Issue.record("Expected first pair")
            return
        }
        guard case .mapping(let typeDef) = typeDefNode else {
            Issue.record("Expected type definition mapping")
            return
        }

        // #Directory value
        let (_, dirValue) = typeDef[0]
        guard case .sequence(let dirSeq) = dirValue else {
            Issue.record("Expected directory sequence")
            return
        }
        #expect(dirSeq.count == 2)

        // First: plain scalar "orders"
        #expect(dirSeq[0] == .scalar(Node.Scalar("orders")))

        // Second: mapping {field: tenantId}
        guard case .mapping(let fieldMapping) = dirSeq[1] else {
            Issue.record("Expected mapping for dynamic field")
            return
        }
        #expect(fieldMapping.count == 1)
        let (fk, fv) = fieldMapping[0]
        guard case .scalar(let fkScalar) = fk, case .scalar(let fvScalar) = fv else {
            Issue.record("Expected scalar key and value")
            return
        }
        #expect(fkScalar.string == "field")
        #expect(fvScalar.string == "tenantId")
    }

    @Test("Vector index field annotation")
    func vectorIndex() throws {
        let yaml = """
        Product:
          "#Directory": [app, products]
          id: string
          name: string
          embedding: array<float>#vector(dimensions:384, metric:cosine, algorithm:hnsw)
        """

        let node = try compose(yaml: yaml)
        guard case .mapping(let root) = node else {
            Issue.record("Expected root mapping")
            return
        }
        guard let (_, typeDefNode) = root.first else {
            Issue.record("Expected first pair")
            return
        }
        guard case .mapping(let typeDef) = typeDefNode else {
            Issue.record("Expected type definition mapping")
            return
        }

        // Find embedding field
        var embeddingValue: String? = nil
        for (keyNode, valueNode) in typeDef {
            if case .scalar(let k) = keyNode, k.string == "embedding",
               case .scalar(let v) = valueNode {
                embeddingValue = v.string
            }
        }

        #expect(embeddingValue == "array<float>#vector(dimensions:384, metric:cosine, algorithm:hnsw)")
    }

    @Test("Complex types with optional and array")
    func complexTypes() throws {
        let yaml = """
        Model:
          "#Directory": [app, models]
          id: string
          name: optional<string>
          tags: array<string>
          score: optional<double>
        """

        let node = try compose(yaml: yaml)
        guard case .mapping(let root) = node else {
            Issue.record("Expected root mapping")
            return
        }
        guard let (_, typeDefNode) = root.first else {
            Issue.record("Expected first pair")
            return
        }
        guard case .mapping(let typeDef) = typeDefNode else {
            Issue.record("Expected type definition mapping")
            return
        }

        var fields: [String: String] = [:]
        for (keyNode, valueNode) in typeDef {
            if case .scalar(let k) = keyNode, case .scalar(let v) = valueNode {
                fields[k.string] = v.string
            }
        }

        #expect(fields["name"] == "optional<string>")
        #expect(fields["tags"] == "array<string>")
        #expect(fields["score"] == "optional<double>")
    }
}
