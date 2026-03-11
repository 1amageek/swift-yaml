import Testing
@testable import YAML

@Suite("Indentation Edge Cases", .tags(.regression, .indentation))
struct IndentationEdgeCaseTests {

    @Test("Multiple dedents at once (6 -> 0)")
    func multipleDedents() throws {
        let yaml = """
        a:
          b:
            c: deep
        d: top
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 2)
        guard case .scalar(let k0) = m[0].key, case .scalar(let k1) = m[1].key else {
            Issue.record("Expected scalar keys"); return
        }
        #expect(k0.string == "a")
        #expect(k1.string == "d")

        // Verify the deep nesting
        guard case .mapping(let b) = m[0].value,
              case .mapping(let c) = b[0].value,
              case .scalar(let cval) = c[0].value else {
            Issue.record("Expected nested mappings"); return
        }
        #expect(cval.string == "deep")
    }

    @Test("Sibling mappings at same indent")
    func siblingMappings() throws {
        let yaml = """
        first:
          a: 1
          b: 2
        second:
          c: 3
          d: 4
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 2)

        guard case .mapping(let first) = m[0].value,
              case .mapping(let second) = m[1].value else {
            Issue.record("Expected nested mappings"); return
        }
        #expect(first.count == 2)
        #expect(second.count == 2)
    }

    @Test("4-space indentation")
    func fourSpaceIndent() throws {
        let yaml = "parent:\n    child: value"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let inner) = m[0].value else {
            Issue.record("Expected nested mapping"); return
        }
        guard case .scalar(let v) = inner[0].value else {
            Issue.record("Expected scalar"); return
        }
        #expect(v.string == "value")
    }

    @Test("1-space indentation")
    func oneSpaceIndent() throws {
        let yaml = "parent:\n child: value"
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let inner) = m[0].value else {
            Issue.record("Expected nested mapping"); return
        }
        #expect(inner.count == 1)
    }

    @Test("Block sequence then back to mapping")
    func sequenceThenMapping() throws {
        let yaml = """
        items:
          - a
          - b
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
        #expect(seq.count == 2)

        guard case .scalar(let name) = m[1].value else {
            Issue.record("Expected scalar"); return
        }
        #expect(name.string == "test")
    }

    @Test("Multiple block sequences at same level")
    func multipleSequences() throws {
        let yaml = """
        fruits:
          - apple
          - banana
        colors:
          - red
          - blue
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let m) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(m.count == 2)

        guard case .sequence(let fruits) = m[0].value,
              case .sequence(let colors) = m[1].value else {
            Issue.record("Expected sequences"); return
        }
        #expect(fruits.count == 2)
        #expect(colors.count == 2)
    }

    @Test("Keys after nested mapping containing block sequence")
    func keysAfterNestedBlockMappingWithSequence() throws {
        let yaml = """
        - id: app
          connections:
            mcp_servers:
            - service_ref: mcp-node/calc
          mount_path: /agents/py
          watch_mode: internal
        """
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        guard case .mapping(let m) = seq[0] else {
            Issue.record("Expected mapping"); return
        }

        #expect(m["mount_path"] != nil, "mount_path should be a sibling of connections")
        #expect(m["watch_mode"] != nil, "watch_mode should be a sibling of connections")
        #expect(m.count == 4, "Should have id, connections, mount_path, watch_mode")
    }

    @Test("Workspace YAML pattern: service with connections and trailing keys")
    func workspaceYAMLPattern() throws {
        let yaml = """
        repos:
        - name: agent
          services:
          - id: app
            kind: agent
            port: 0
            run:
            - python3
            - server.py
            connections:
              mcp_servers:
              - service_ref: mcp-node/calc
            mount_path: /agents/py
            watch_mode: internal
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let root) = node,
              case .sequence(let repos) = root["repos"],
              case .mapping(let repo) = repos[0],
              case .sequence(let services) = repo["services"],
              case .mapping(let svc) = services[0] else {
            Issue.record("Expected workspace structure"); return
        }

        #expect(svc["id"] != nil)
        #expect(svc["kind"] != nil)
        #expect(svc["mount_path"] != nil, "mount_path should be at service level")
        #expect(svc["watch_mode"] != nil, "watch_mode should be at service level")
        #expect(svc["connections"] != nil)

        guard case .mapping(let conn) = svc["connections"] else {
            Issue.record("Expected connections mapping"); return
        }
        #expect(conn.count == 1, "connections should only have mcp_servers")
    }

    @Test("Sequence at same indent as mapping key without trailing keys")
    func sequenceAtSameIndentNoTrailing() throws {
        let yaml = """
        data:
          items:
          - a
          - b
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let root) = node,
              case .mapping(let data) = root["data"],
              case .sequence(let items) = data["items"] else {
            Issue.record("Expected nested structure"); return
        }
        #expect(items.count == 2)
    }

    @Test("Sequence at same indent followed by sibling key")
    func sequenceAtSameIndentWithSibling() throws {
        let yaml = """
        data:
          items:
          - a
          - b
          count: 2
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let root) = node,
              case .mapping(let data) = root["data"] else {
            Issue.record("Expected nested structure"); return
        }
        #expect(data.count == 2)
        #expect(data["items"] != nil)
        #expect(data["count"] != nil)
    }

    @Test("Deeply nested sequence of mappings")
    func deepSequenceOfMappings() throws {
        let yaml = """
        root:
          items:
            - name: first
              sub:
                - x: 1
                - x: 2
            - name: second
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let root) = node,
              case .mapping(let inner) = root[0].value,
              case .sequence(let items) = inner[0].value else {
            Issue.record("Expected nested structure"); return
        }
        #expect(items.count == 2)

        guard case .mapping(let first) = items[0] else {
            Issue.record("Expected mapping"); return
        }
        // first has name and sub
        #expect(first.count == 2)

        guard case .sequence(let sub) = first[1].value else {
            Issue.record("Expected sub sequence"); return
        }
        #expect(sub.count == 2)
    }
}
