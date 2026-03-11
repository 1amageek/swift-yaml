import Testing
@testable import YAML

// YAML 1.2.2 Specification - Chapter 10: Recommended Schemas
// Examples 124-132

@Suite("Spec Chapter 10: Recommended Schemas", .tags(.spec, .scalar))
struct SpecChapter10Tests {

    // MARK: - 10.1 Failsafe Schema

    @Test("Example 10.1 (124): !!map Examples")
    func example10_1() throws {
        let yaml = "Block style: !!map\n  Clark : Evans\n  Ingy  : döt Net\n  Oren  : Ben-Kiki\n\nFlow style: !!map { Clark: Evans, Ingy: döt Net, Oren: Ben-Kiki }\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .mapping(let blockMap) = map["Block style"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(blockMap["Clark"] == .scalar(.init("Evans")))
        #expect(blockMap["Ingy"] == .scalar(.init("döt Net")))
        #expect(blockMap["Oren"] == .scalar(.init("Ben-Kiki")))
        guard case .mapping(let flowMap) = map["Flow style"] else {
            Issue.record("Expected mapping"); return
        }
        #expect(flowMap["Clark"] == .scalar(.init("Evans")))
    }

    @Test("Example 10.2 (125): !!seq Examples")
    func example10_2() throws {
        let yaml = "Block style: !!seq\n- Clark Evans\n- Ingy döt Net\n- Oren Ben-Kiki\n\nFlow style: !!seq [ Clark Evans, Ingy döt Net, Oren Ben-Kiki ]\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .sequence(let blockSeq) = map["Block style"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(blockSeq[0] == .scalar(.init("Clark Evans")))
        #expect(blockSeq[1] == .scalar(.init("Ingy döt Net")))
        guard case .sequence(let flowSeq) = map["Flow style"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(flowSeq[0] == .scalar(.init("Clark Evans")))
    }

    @Test("Example 10.3 (126): !!str Examples")
    func example10_3() throws {
        let yaml = "Block style: !!str |-\n  String: just a theory.\n\nFlow style: !!str \"String: just a theory.\"\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let blockStr) = map["Block style"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(blockStr.string == "String: just a theory.")
        guard case .scalar(let flowStr) = map["Flow style"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(flowStr.string == "String: just a theory.")
    }

    // MARK: - 10.2 JSON Schema

    @Test("Example 10.4 (127): JSON null")
    func example10_4() throws {
        let yaml = "!!null null: value for null key\nkey with null value: !!null null\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        // The key "null" (tagged !!null) maps to "value for null key"
        #expect(map["null"] == .scalar(.init("value for null key")))
        // "key with null value" maps to "null" (tagged !!null)
        #expect(map["key with null value"] == .scalar(.init("null")))
    }

    @Test("Example 10.5 (128): JSON bool")
    func example10_5() throws {
        let yaml = "YAML is a superset of JSON: !!bool true\nPluto is a planet: !!bool false\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["YAML is a superset of JSON"] == .scalar(.init("true")))
        #expect(map["Pluto is a planet"] == .scalar(.init("false")))
    }

    @Test("Example 10.6 (129): JSON int")
    func example10_6() throws {
        let yaml = "negative: !!int -12\nzero: !!int 0\npositive: !!int 34\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["negative"] == .scalar(.init("-12")))
        #expect(map["zero"] == .scalar(.init("0")))
        #expect(map["positive"] == .scalar(.init("34")))
    }

    @Test("Example 10.7 (130): JSON float")
    func example10_7() throws {
        let yaml = "negative: !!float -1\nzero: !!float 0\npositive: !!float 2.3e4\ninfinity: !!float .inf\nnot a number: !!float .nan\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["negative"] == .scalar(.init("-1")))
        #expect(map["zero"] == .scalar(.init("0")))
        #expect(map["positive"] == .scalar(.init("2.3e4")))
        #expect(map["infinity"] == .scalar(.init(".inf")))
        #expect(map["not a number"] == .scalar(.init(".nan")))
    }

    // MARK: - 10.3 Core Schema

    @Test("Example 10.8 (131): Core null")
    func example10_8() throws {
        let yaml = "A null: null\nAlso a null: # Empty\nNot a null: \"\"\nBooleans: [ true, True, false, FALSE ]\nIntegers: [ 0, 0o7, 0x3A, -19 ]\nFloats: [ 0., -0.0, .5, +12e03, -2E+05 ]\nAlso floats: [ .inf, -.Inf, +.INF, .NAN ]\n"
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        // Null values
        #expect(map["A null"] == .scalar(.init("null")))
        #expect(map["Also a null"] == .scalar(.init("")))
        #expect(map["Not a null"] == .scalar(.init("")))

        // Booleans
        guard case .sequence(let bools) = map["Booleans"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(bools[0] == .scalar(.init("true")))
        #expect(bools[1] == .scalar(.init("True")))
        #expect(bools[2] == .scalar(.init("false")))
        #expect(bools[3] == .scalar(.init("FALSE")))

        // Integers
        guard case .sequence(let ints) = map["Integers"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(ints[0] == .scalar(.init("0")))
        #expect(ints[1] == .scalar(.init("0o7")))
        #expect(ints[2] == .scalar(.init("0x3A")))
        #expect(ints[3] == .scalar(.init("-19")))

        // Floats
        guard case .sequence(let floats) = map["Floats"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(floats[0] == .scalar(.init("0.")))
        #expect(floats[1] == .scalar(.init("-0.0")))
        #expect(floats[2] == .scalar(.init(".5")))
        #expect(floats[3] == .scalar(.init("+12e03")))
        #expect(floats[4] == .scalar(.init("-2E+05")))

        // Also floats
        guard case .sequence(let alsoFloats) = map["Also floats"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(alsoFloats[0] == .scalar(.init(".inf")))
        #expect(alsoFloats[1] == .scalar(.init("-.Inf")))
        #expect(alsoFloats[2] == .scalar(.init("+.INF")))
        #expect(alsoFloats[3] == .scalar(.init(".NAN")))
    }

    @Test("Example 10.9 (132): Core Tag Resolution")
    func example10_9() throws {
        let yaml = """
        A null: null
        Also a null: # Empty
        Not a null: ""
        Booleans: [ true, True, false, FALSE ]
        Integers: [ 0, 0o7, 0x3A, -19 ]
        Floats: [ 0., -0.0, .5, +12e03, -2E+05 ]
        Also floats: [ .inf, -.Inf, +.INF, .NAN ]
        """
        // This is the same as 10.8 but tests that the parser correctly parses
        // all these values as plain scalars
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map.count == 7)
    }

    // MARK: - Additional Schema Tests

    @Test("Null representations")
    func nullRepresentations() throws {
        let yaml = """
        empty:
        tilde: ~
        null_word: null
        Null_word: Null
        NULL_word: NULL
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["empty"] == .scalar(.init("")))
        #expect(map["tilde"] == .scalar(.init("~")))
        #expect(map["null_word"] == .scalar(.init("null")))
        #expect(map["Null_word"] == .scalar(.init("Null")))
        #expect(map["NULL_word"] == .scalar(.init("NULL")))
    }

    @Test("Boolean representations")
    func booleanRepresentations() throws {
        let yaml = """
        - true
        - True
        - TRUE
        - false
        - False
        - FALSE
        """
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("true")))
        #expect(seq[1] == .scalar(.init("True")))
        #expect(seq[2] == .scalar(.init("TRUE")))
        #expect(seq[3] == .scalar(.init("false")))
        #expect(seq[4] == .scalar(.init("False")))
        #expect(seq[5] == .scalar(.init("FALSE")))
    }

    @Test("Integer representations")
    func integerRepresentations() throws {
        let yaml = """
        - 0
        - +12345
        - -12345
        - 0o14
        - 0xC
        """
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("0")))
        #expect(seq[1] == .scalar(.init("+12345")))
        #expect(seq[2] == .scalar(.init("-12345")))
        #expect(seq[3] == .scalar(.init("0o14")))
        #expect(seq[4] == .scalar(.init("0xC")))
    }

    @Test("Float representations")
    func floatRepresentations() throws {
        let yaml = """
        - 1.23015e+3
        - 12.3015e+02
        - 1230.15
        - .inf
        - -.inf
        - .Inf
        - .nan
        - .NaN
        - .NAN
        """
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq[0] == .scalar(.init("1.23015e+3")))
        #expect(seq[1] == .scalar(.init("12.3015e+02")))
        #expect(seq[2] == .scalar(.init("1230.15")))
        #expect(seq[3] == .scalar(.init(".inf")))
        #expect(seq[4] == .scalar(.init("-.inf")))
        #expect(seq[5] == .scalar(.init(".Inf")))
        #expect(seq[6] == .scalar(.init(".nan")))
        #expect(seq[7] == .scalar(.init(".NaN")))
        #expect(seq[8] == .scalar(.init(".NAN")))
    }
}
