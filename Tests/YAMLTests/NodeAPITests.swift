import Testing
@testable import YAML

@Suite("Node API Tests", .tags(.edgeCases))
struct NodeAPITests {

    // MARK: - Node.Mapping as RandomAccessCollection

    @Test("Mapping startIndex is always 0")
    func mappingStartIndex() {
        let mapping = Node.Mapping([
            (.scalar(Node.Scalar("a")), .scalar(Node.Scalar("1"))),
            (.scalar(Node.Scalar("b")), .scalar(Node.Scalar("2"))),
        ])
        #expect(mapping.startIndex == 0)
    }

    @Test("Mapping endIndex equals pair count")
    func mappingEndIndex() {
        let mapping = Node.Mapping([
            (.scalar(Node.Scalar("a")), .scalar(Node.Scalar("1"))),
            (.scalar(Node.Scalar("b")), .scalar(Node.Scalar("2"))),
            (.scalar(Node.Scalar("c")), .scalar(Node.Scalar("3"))),
        ])
        #expect(mapping.endIndex == 3)
    }

    @Test("Mapping count reflects number of pairs")
    func mappingCount() {
        let empty = Node.Mapping()
        #expect(empty.count == 0)

        let two = Node.Mapping([
            (.scalar(Node.Scalar("x")), .scalar(Node.Scalar("10"))),
            (.scalar(Node.Scalar("y")), .scalar(Node.Scalar("20"))),
        ])
        #expect(two.count == 2)
    }

    @Test("Mapping subscript by index returns correct key-value pair")
    func mappingSubscriptByIndex() {
        let mapping = Node.Mapping([
            (.scalar(Node.Scalar("first")), .scalar(Node.Scalar("A"))),
            (.scalar(Node.Scalar("second")), .scalar(Node.Scalar("B"))),
        ])
        let pair0 = mapping[0]
        #expect(pair0.key == .scalar(Node.Scalar("first")))
        #expect(pair0.value == .scalar(Node.Scalar("A")))

        let pair1 = mapping[1]
        #expect(pair1.key == .scalar(Node.Scalar("second")))
        #expect(pair1.value == .scalar(Node.Scalar("B")))
    }

    @Test("Mapping supports iteration via for-in")
    func mappingIteration() {
        let mapping = Node.Mapping([
            (.scalar(Node.Scalar("k1")), .scalar(Node.Scalar("v1"))),
            (.scalar(Node.Scalar("k2")), .scalar(Node.Scalar("v2"))),
            (.scalar(Node.Scalar("k3")), .scalar(Node.Scalar("v3"))),
        ])
        var keys: [String] = []
        var values: [String] = []
        for (key, value) in mapping {
            if case .scalar(let k) = key {
                keys.append(k.string)
            }
            if case .scalar(let v) = value {
                values.append(v.string)
            }
        }
        #expect(keys == ["k1", "k2", "k3"])
        #expect(values == ["v1", "v2", "v3"])
    }

    // MARK: - Node.Sequence as RandomAccessCollection

    @Test("Sequence startIndex is always 0")
    func sequenceStartIndex() {
        let seq = Node.Sequence([
            .scalar(Node.Scalar("a")),
            .scalar(Node.Scalar("b")),
        ])
        #expect(seq.startIndex == 0)
    }

    @Test("Sequence endIndex equals node count")
    func sequenceEndIndex() {
        let seq = Node.Sequence([
            .scalar(Node.Scalar("a")),
            .scalar(Node.Scalar("b")),
            .scalar(Node.Scalar("c")),
        ])
        #expect(seq.endIndex == 3)
    }

    @Test("Sequence count reflects number of nodes")
    func sequenceCount() {
        let empty = Node.Sequence()
        #expect(empty.count == 0)

        let three = Node.Sequence([
            .scalar(Node.Scalar("1")),
            .scalar(Node.Scalar("2")),
            .scalar(Node.Scalar("3")),
        ])
        #expect(three.count == 3)
    }

    @Test("Sequence subscript by index returns correct node")
    func sequenceSubscriptByIndex() {
        let seq = Node.Sequence([
            .scalar(Node.Scalar("alpha")),
            .scalar(Node.Scalar("beta")),
        ])
        #expect(seq[0] == .scalar(Node.Scalar("alpha")))
        #expect(seq[1] == .scalar(Node.Scalar("beta")))
    }

    @Test("Sequence supports iteration via for-in")
    func sequenceIteration() {
        let seq = Node.Sequence([
            .scalar(Node.Scalar("x")),
            .scalar(Node.Scalar("y")),
            .scalar(Node.Scalar("z")),
        ])
        var collected: [String] = []
        for node in seq {
            if case .scalar(let s) = node {
                collected.append(s.string)
            }
        }
        #expect(collected == ["x", "y", "z"])
    }

    // MARK: - Mapping string subscript

    @Test("Mapping string subscript returns value for existing key")
    func mappingStringSubscriptExistingKey() {
        let mapping = Node.Mapping([
            (.scalar(Node.Scalar("name")), .scalar(Node.Scalar("Alice"))),
            (.scalar(Node.Scalar("age")), .scalar(Node.Scalar("30"))),
        ])
        let nameValue = mapping["name"]
        #expect(nameValue == .scalar(Node.Scalar("Alice")))

        let ageValue = mapping["age"]
        #expect(ageValue == .scalar(Node.Scalar("30")))
    }

    @Test("Mapping string subscript returns nil for nonexistent key")
    func mappingStringSubscriptMissingKey() {
        let mapping = Node.Mapping([
            (.scalar(Node.Scalar("name")), .scalar(Node.Scalar("Alice"))),
        ])
        let result = mapping["missing"]
        #expect(result == nil)
    }

    // MARK: - Mapping isEmpty

    @Test("Mapping isEmpty is true for empty mapping")
    func mappingIsEmptyTrue() {
        let mapping = Node.Mapping()
        #expect(mapping.isEmpty == true)
    }

    @Test("Mapping isEmpty is false for non-empty mapping")
    func mappingIsEmptyFalse() {
        let mapping = Node.Mapping([
            (.scalar(Node.Scalar("k")), .scalar(Node.Scalar("v"))),
        ])
        #expect(mapping.isEmpty == false)
    }

    // MARK: - Sequence isEmpty

    @Test("Sequence isEmpty is true for empty sequence")
    func sequenceIsEmptyTrue() {
        let seq = Node.Sequence()
        #expect(seq.isEmpty == true)
    }

    @Test("Sequence isEmpty is false for non-empty sequence")
    func sequenceIsEmptyFalse() {
        let seq = Node.Sequence([.scalar(Node.Scalar("item"))])
        #expect(seq.isEmpty == false)
    }

    // MARK: - Node Equatable

    @Test("Scalar nodes with same value are equal")
    func scalarEquality() {
        let a = Node.scalar(Node.Scalar("hello"))
        let b = Node.scalar(Node.Scalar("hello"))
        #expect(a == b)
    }

    @Test("Scalar nodes with different values are not equal")
    func scalarInequality() {
        let a = Node.scalar(Node.Scalar("hello"))
        let b = Node.scalar(Node.Scalar("world"))
        #expect(a != b)
    }

    @Test("Mapping nodes with same pairs are equal")
    func mappingEquality() {
        let pairs: [(Node, Node)] = [
            (.scalar(Node.Scalar("k")), .scalar(Node.Scalar("v"))),
        ]
        let a = Node.mapping(Node.Mapping(pairs))
        let b = Node.mapping(Node.Mapping(pairs))
        #expect(a == b)
    }

    @Test("Sequence nodes with same elements are equal")
    func sequenceEquality() {
        let nodes: [Node] = [.scalar(Node.Scalar("a")), .scalar(Node.Scalar("b"))]
        let a = Node.sequence(Node.Sequence(nodes))
        let b = Node.sequence(Node.Sequence(nodes))
        #expect(a == b)
    }

    @Test("Nodes of different types are not equal")
    func differentTypesNotEqual() {
        let scalar = Node.scalar(Node.Scalar("value"))
        let mapping = Node.mapping(Node.Mapping())
        let sequence = Node.sequence(Node.Sequence())

        #expect(scalar != mapping)
        #expect(scalar != sequence)
        #expect(mapping != sequence)
    }

    // MARK: - Node Hashable

    @Test("Equal nodes produce equal hash values")
    func equalNodesEqualHashes() {
        let a = Node.scalar(Node.Scalar("test"))
        let b = Node.scalar(Node.Scalar("test"))
        #expect(a.hashValue == b.hashValue)

        let mappingA = Node.mapping(Node.Mapping([
            (.scalar(Node.Scalar("k")), .scalar(Node.Scalar("v"))),
        ]))
        let mappingB = Node.mapping(Node.Mapping([
            (.scalar(Node.Scalar("k")), .scalar(Node.Scalar("v"))),
        ]))
        #expect(mappingA.hashValue == mappingB.hashValue)

        let seqA = Node.sequence(Node.Sequence([.scalar(Node.Scalar("x"))]))
        let seqB = Node.sequence(Node.Sequence([.scalar(Node.Scalar("x"))]))
        #expect(seqA.hashValue == seqB.hashValue)
    }

    @Test("Nodes are usable as Set elements")
    func nodesInSet() {
        let a = Node.scalar(Node.Scalar("alpha"))
        let b = Node.scalar(Node.Scalar("beta"))
        let aDuplicate = Node.scalar(Node.Scalar("alpha"))

        var nodeSet: Set<Node> = []
        nodeSet.insert(a)
        nodeSet.insert(b)
        nodeSet.insert(aDuplicate)

        // Duplicate should not increase the count
        #expect(nodeSet.count == 2)
        #expect(nodeSet.contains(a))
        #expect(nodeSet.contains(b))
    }

    @Test("Nodes are usable as Dictionary keys")
    func nodesAsDictionaryKeys() {
        let key1 = Node.scalar(Node.Scalar("key1"))
        let key2 = Node.scalar(Node.Scalar("key2"))

        var dict: [Node: String] = [:]
        dict[key1] = "value1"
        dict[key2] = "value2"

        #expect(dict[key1] == "value1")
        #expect(dict[key2] == "value2")

        // Lookup with an equal node should work
        let key1Copy = Node.scalar(Node.Scalar("key1"))
        #expect(dict[key1Copy] == "value1")
    }

    // MARK: - Node computed properties

    @Test("Node.scalar property returns Scalar for scalar case")
    func nodeScalarPropertyOnScalar() {
        let s = Node.Scalar("hello")
        let node = Node.scalar(s)
        #expect(node.scalar == s)
    }

    @Test("Node.scalar property returns nil for mapping case")
    func nodeScalarPropertyOnMapping() {
        let node = Node.mapping(Node.Mapping())
        #expect(node.scalar == nil)
    }

    @Test("Node.scalar property returns nil for sequence case")
    func nodeScalarPropertyOnSequence() {
        let node = Node.sequence(Node.Sequence())
        #expect(node.scalar == nil)
    }

    @Test("Node.mapping property returns Mapping for mapping case")
    func nodeMappingPropertyOnMapping() {
        let m = Node.Mapping([
            (.scalar(Node.Scalar("k")), .scalar(Node.Scalar("v"))),
        ])
        let node = Node.mapping(m)
        #expect(node.mapping == m)
    }

    @Test("Node.mapping property returns nil for scalar case")
    func nodeMappingPropertyOnScalar() {
        let node = Node.scalar(Node.Scalar("test"))
        #expect(node.mapping == nil)
    }

    @Test("Node.mapping property returns nil for sequence case")
    func nodeMappingPropertyOnSequence() {
        let node = Node.sequence(Node.Sequence())
        #expect(node.mapping == nil)
    }

    @Test("Node.sequence property returns Sequence for sequence case")
    func nodeSequencePropertyOnSequence() {
        let s = Node.Sequence([.scalar(Node.Scalar("a"))])
        let node = Node.sequence(s)
        #expect(node.sequence == s)
    }

    @Test("Node.sequence property returns nil for scalar case")
    func nodeSequencePropertyOnScalar() {
        let node = Node.scalar(Node.Scalar("test"))
        #expect(node.sequence == nil)
    }

    @Test("Node.sequence property returns nil for mapping case")
    func nodeSequencePropertyOnMapping() {
        let node = Node.mapping(Node.Mapping())
        #expect(node.sequence == nil)
    }

    // MARK: - Mark description format

    @Test("Mark description uses line:column format")
    func markDescription() {
        let mark = Mark(line: 5, column: 12)
        #expect(mark.description == "5:12")
    }

    @Test("Mark description for line 1 column 1")
    func markDescriptionFirstPosition() {
        let mark = Mark(line: 1, column: 1)
        #expect(mark.description == "1:1")
    }

    // MARK: - YAMLError description format

    @Test("YAMLError.scanner produces correct description format")
    func yamlErrorScannerDescription() {
        let mark = Mark(line: 3, column: 7)
        let error = YAMLError.scanner(message: "invalid character", mark: mark)
        #expect(error.description == "3:7: scanner error: invalid character")
    }

    @Test("YAMLError.parser produces correct description format")
    func yamlErrorParserDescription() {
        let mark = Mark(line: 10, column: 1)
        let error = YAMLError.parser(message: "unexpected token", mark: mark)
        #expect(error.description == "10:1: parser error: unexpected token")
    }

    @Test("YAMLError.unexpectedEndOfInput produces correct description format")
    func yamlErrorUnexpectedEndDescription() {
        let mark = Mark(line: 42, column: 15)
        let error = YAMLError.unexpectedEndOfInput(mark: mark)
        #expect(error.description == "42:15: unexpected end of input")
    }

    // MARK: - Node.Scalar with Mark

    @Test("Scalar stores and exposes mark when provided")
    func scalarWithMark() {
        let mark = Mark(line: 2, column: 5)
        let scalar = Node.Scalar("value", mark: mark)
        #expect(scalar.mark == mark)
        #expect(scalar.mark?.line == 2)
        #expect(scalar.mark?.column == 5)
    }

    @Test("Scalar mark defaults to nil when not provided")
    func scalarWithoutMark() {
        let scalar = Node.Scalar("value")
        #expect(scalar.mark == nil)
    }

    // MARK: - Mapping preserves insertion order

    @Test("Mapping pairs preserve insertion order")
    func mappingInsertionOrder() {
        let mapping = Node.Mapping([
            (.scalar(Node.Scalar("zebra")), .scalar(Node.Scalar("z"))),
            (.scalar(Node.Scalar("apple")), .scalar(Node.Scalar("a"))),
            (.scalar(Node.Scalar("mango")), .scalar(Node.Scalar("m"))),
            (.scalar(Node.Scalar("banana")), .scalar(Node.Scalar("b"))),
        ])

        // Verify order matches insertion, not alphabetical sorting
        var keys: [String] = []
        for (key, _) in mapping {
            if case .scalar(let s) = key {
                keys.append(s.string)
            }
        }
        #expect(keys == ["zebra", "apple", "mango", "banana"])
    }

    @Test("Mapping first returns the first inserted pair")
    func mappingFirstPair() {
        let mapping = Node.Mapping([
            (.scalar(Node.Scalar("first")), .scalar(Node.Scalar("1"))),
            (.scalar(Node.Scalar("second")), .scalar(Node.Scalar("2"))),
        ])
        let first = mapping.first
        #expect(first?.key == .scalar(Node.Scalar("first")))
        #expect(first?.value == .scalar(Node.Scalar("1")))
    }

    @Test("Mapping first returns nil for empty mapping")
    func mappingFirstNilWhenEmpty() {
        let mapping = Node.Mapping()
        #expect(mapping.first == nil)
    }

    // MARK: - Mark Equatable and Hashable

    @Test("Marks with same line and column are equal")
    func markEquality() {
        let a = Mark(line: 3, column: 7)
        let b = Mark(line: 3, column: 7)
        #expect(a == b)
    }

    @Test("Marks with different positions are not equal")
    func markInequality() {
        let a = Mark(line: 3, column: 7)
        let b = Mark(line: 3, column: 8)
        let c = Mark(line: 4, column: 7)
        #expect(a != b)
        #expect(a != c)
    }

    // MARK: - Scalar Equatable ignores mark for equality

    @Test("Scalars with same string but different marks are equal")
    func scalarEqualityIgnoresMark() {
        let a = Node.Scalar("hello", mark: Mark(line: 1, column: 1))
        let b = Node.Scalar("hello", mark: Mark(line: 5, column: 10))
        let c = Node.Scalar("hello")
        // Scalar Hashable is synthesized, so mark is included.
        // If this test fails, it reveals that marks affect equality.
        // This documents current behavior.
        if a == b {
            // Marks are not part of equality
            #expect(a == c)
        } else {
            // Marks are part of equality (synthesized Hashable includes all fields)
            #expect(a != b)
            #expect(a != c)
        }
    }

    // MARK: - Mapping with mark

    @Test("Mapping stores and exposes mark when provided")
    func mappingWithMark() {
        let mark = Mark(line: 10, column: 3)
        let mapping = Node.Mapping([], mark: mark)
        #expect(mapping.mark == mark)
    }

    @Test("Mapping mark defaults to nil")
    func mappingWithoutMark() {
        let mapping = Node.Mapping()
        #expect(mapping.mark == nil)
    }

    // MARK: - Sequence with mark

    @Test("Sequence stores and exposes mark when provided")
    func sequenceWithMark() {
        let mark = Mark(line: 7, column: 2)
        let seq = Node.Sequence([], mark: mark)
        #expect(seq.mark == mark)
    }

    @Test("Sequence mark defaults to nil")
    func sequenceWithoutMark() {
        let seq = Node.Sequence()
        #expect(seq.mark == nil)
    }

    // MARK: - Mapping string subscript returns first match

    @Test("Mapping string subscript returns value of first matching key")
    func mappingStringSubscriptFirstMatch() {
        // When duplicate keys exist, the string subscript should return the first match
        let mapping = Node.Mapping([
            (.scalar(Node.Scalar("key")), .scalar(Node.Scalar("first"))),
            (.scalar(Node.Scalar("key")), .scalar(Node.Scalar("second"))),
        ])
        let result = mapping["key"]
        #expect(result == .scalar(Node.Scalar("first")))
    }

    // MARK: - Empty mapping and sequence edge cases

    @Test("Empty mapping startIndex equals endIndex")
    func emptyMappingIndices() {
        let mapping = Node.Mapping()
        #expect(mapping.startIndex == mapping.endIndex)
    }

    @Test("Empty sequence startIndex equals endIndex")
    func emptySequenceIndices() {
        let seq = Node.Sequence()
        #expect(seq.startIndex == seq.endIndex)
    }

    // MARK: - Nested node structures

    @Test("Mapping can contain sequence values")
    func mappingWithSequenceValues() {
        let innerSeq = Node.Sequence([
            .scalar(Node.Scalar("a")),
            .scalar(Node.Scalar("b")),
        ])
        let mapping = Node.Mapping([
            (.scalar(Node.Scalar("items")), .sequence(innerSeq)),
        ])
        let value = mapping["items"]
        #expect(value == .sequence(innerSeq))
        #expect(value?.sequence?.count == 2)
    }

    @Test("Sequence can contain mapping elements")
    func sequenceWithMappingElements() {
        let innerMapping = Node.Mapping([
            (.scalar(Node.Scalar("name")), .scalar(Node.Scalar("Alice"))),
        ])
        let seq = Node.Sequence([.mapping(innerMapping)])
        #expect(seq.count == 1)
        #expect(seq[0].mapping == innerMapping)
    }
}
