import Testing
@testable import YAML

// YAML 1.2.2 Specification - Chapter 2: Language Overview
// Examples 1-28

@Suite("Spec Chapter 2: Language Overview", .tags(.spec))
struct SpecChapter2Tests {

    // MARK: - 2.1 Collections

    @Test("Example 2.1: Sequence of Scalars (ball players)")
    func example2_1() throws {
        let yaml = """
        - Mark McGwire
        - Sammy Sosa
        - Ken Griffey
        """
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 3)
        #expect(seq[0] == .scalar(.init("Mark McGwire")))
        #expect(seq[1] == .scalar(.init("Sammy Sosa")))
        #expect(seq[2] == .scalar(.init("Ken Griffey")))
    }

    @Test("Example 2.2: Mapping Scalars to Scalars (player statistics)")
    func example2_2() throws {
        let yaml = """
        hr:  65    # Home runs
        avg: 0.278 # Batting average
        rbi: 147   # Runs Batted In
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map.count == 3)
        #expect(map["hr"] == .scalar(.init("65")))
        #expect(map["avg"] == .scalar(.init("0.278")))
        #expect(map["rbi"] == .scalar(.init("147")))
    }

    @Test("Example 2.3: Mapping Scalars to Sequences (ball clubs in each league)")
    func example2_3() throws {
        let yaml = """
        american:
        - Boston Red Sox
        - Detroit Tigers
        - New York Yankees
        national:
        - New York Mets
        - Chicago Cubs
        - Atlanta Braves
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map.count == 2)
        guard case .sequence(let american) = map["american"] else {
            Issue.record("Expected sequence for american"); return
        }
        #expect(american.count == 3)
        #expect(american[0] == .scalar(.init("Boston Red Sox")))
        guard case .sequence(let national) = map["national"] else {
            Issue.record("Expected sequence for national"); return
        }
        #expect(national.count == 3)
        #expect(national[0] == .scalar(.init("New York Mets")))
    }

    @Test("Example 2.4: Sequence of Mappings (players' statistics)")
    func example2_4() throws {
        let yaml = """
        -
          name: Mark McGwire
          hr:   65
          avg:  0.278
        -
          name: Sammy Sosa
          hr:   63
          avg:  0.288
        """
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 2)
        guard case .mapping(let first) = seq[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(first["name"] == .scalar(.init("Mark McGwire")))
        #expect(first["hr"] == .scalar(.init("65")))
        #expect(first["avg"] == .scalar(.init("0.278")))
        guard case .mapping(let second) = seq[1] else {
            Issue.record("Expected mapping"); return
        }
        #expect(second["name"] == .scalar(.init("Sammy Sosa")))
        #expect(second["hr"] == .scalar(.init("63")))
    }

    @Test("Example 2.5: Sequence of Sequences")
    func example2_5() throws {
        let yaml = """
        - [name        , hr, avg  ]
        - [Mark McGwire, 65, 0.278]
        - [Sammy Sosa  , 63, 0.288]
        """
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 3)
        guard case .sequence(let header) = seq[0] else {
            Issue.record("Expected sequence"); return
        }
        #expect(header.count == 3)
        #expect(header[0] == .scalar(.init("name")))
        #expect(header[1] == .scalar(.init("hr")))
        #expect(header[2] == .scalar(.init("avg")))
        guard case .sequence(let row1) = seq[1] else {
            Issue.record("Expected sequence"); return
        }
        #expect(row1[0] == .scalar(.init("Mark McGwire")))
        #expect(row1[1] == .scalar(.init("65")))
        #expect(row1[2] == .scalar(.init("0.278")))
    }

    @Test("Example 2.6: Mapping of Mappings")
    func example2_6() throws {
        let yaml = """
        Mark McGwire: {hr: 65, avg: 0.278}
        Sammy Sosa: {
            hr: 63,
            avg: 0.288,
         }
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map.count == 2)
        guard case .mapping(let mcgwire) = map["Mark McGwire"] else {
            Issue.record("Expected mapping for Mark McGwire"); return
        }
        #expect(mcgwire["hr"] == .scalar(.init("65")))
        #expect(mcgwire["avg"] == .scalar(.init("0.278")))
        guard case .mapping(let sosa) = map["Sammy Sosa"] else {
            Issue.record("Expected mapping for Sammy Sosa"); return
        }
        #expect(sosa["hr"] == .scalar(.init("63")))
        #expect(sosa["avg"] == .scalar(.init("0.288")))
    }

    // MARK: - 2.2 Structures

    @Test("Example 2.7: Two Documents in a Stream (each with a leading comment)")
    func example2_7() throws {
        let yaml = """
        # Ranking of 1998 home runs
        ---
        - Mark McGwire
        - Sammy Sosa
        - Ken Griffey
        """
        // Test first document only (multi-document support is separate)
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 3)
        #expect(seq[0] == .scalar(.init("Mark McGwire")))
    }

    @Test("Example 2.8: Play by Play Feed from a Game")
    func example2_8() throws {
        let yaml = """
        ---
        time: 20:03:20
        player: Sammy Sosa
        action: strike (miss)
        ...
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["time"] == .scalar(.init("20:03:20")))
        #expect(map["player"] == .scalar(.init("Sammy Sosa")))
        #expect(map["action"] == .scalar(.init("strike (miss)")))
    }

    @Test("Example 2.9: Single Document with Two Comments")
    func example2_9() throws {
        let yaml = """
        ---
        hr: # 1998 hr ranking
        - Mark McGwire
        - Sammy Sosa
        # 1998 rbi ranking
        rbi:
        - Sammy Sosa
        - Ken Griffey
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map.count == 2)
        guard case .sequence(let hr) = map["hr"] else {
            Issue.record("Expected sequence for hr"); return
        }
        #expect(hr.count == 2)
        #expect(hr[0] == .scalar(.init("Mark McGwire")))
        guard case .sequence(let rbi) = map["rbi"] else {
            Issue.record("Expected sequence for rbi"); return
        }
        #expect(rbi.count == 2)
        #expect(rbi[0] == .scalar(.init("Sammy Sosa")))
    }

    @Test("Example 2.10: Node for 'Sammy Sosa' appears twice (anchors and aliases)")
    func example2_10() throws {
        let yaml = """
        ---
        hr:
        - Mark McGwire
        # Following node labeled SS
        - &SS Sammy Sosa
        rbi:
        - *SS # Subsequent occurrence
        - Ken Griffey
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .sequence(let hr) = map["hr"] else {
            Issue.record("Expected sequence for hr"); return
        }
        #expect(hr[1] == .scalar(.init("Sammy Sosa")))
        guard case .sequence(let rbi) = map["rbi"] else {
            Issue.record("Expected sequence for rbi"); return
        }
        // Alias *SS should resolve to "Sammy Sosa"
        #expect(rbi[0] == .scalar(.init("Sammy Sosa")))
    }

    @Test("Example 2.11: Mapping between Sequences (complex keys)")
    func example2_11() throws {
        let yaml = """
        ? - Detroit Tigers
          - Chicago cubs
        : - 2001-07-23

        ? [ New York Yankees,
            Atlanta Braves ]
        : [ 2001-07-02, 2001-08-12,
            2001-08-14 ]
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map.count == 2)
        // Complex keys: sequences as mapping keys
        let (key1, val1) = map[0]
        guard case .sequence(let keySeq1) = key1 else {
            Issue.record("Expected sequence key"); return
        }
        #expect(keySeq1[0] == .scalar(.init("Detroit Tigers")))
        #expect(keySeq1[1] == .scalar(.init("Chicago cubs")))
        guard case .sequence(let valSeq1) = val1 else {
            Issue.record("Expected sequence value"); return
        }
        #expect(valSeq1[0] == .scalar(.init("2001-07-23")))
    }

    @Test("Example 2.12: Compact Nested Mapping")
    func example2_12() throws {
        let yaml = """
        ---
        # Products purchased
        - item    : Super Hoop
          quantity: 1
        - item    : Basketball
          quantity: 4
        - item    : Big Shoes
          quantity: 1
        """
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 3)
        guard case .mapping(let first) = seq[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(first["item"] == .scalar(.init("Super Hoop")))
        #expect(first["quantity"] == .scalar(.init("1")))
        guard case .mapping(let second) = seq[1] else {
            Issue.record("Expected mapping"); return
        }
        #expect(second["item"] == .scalar(.init("Basketball")))
        #expect(second["quantity"] == .scalar(.init("4")))
    }

    // MARK: - 2.3 Scalars

    @Test("Example 2.13: In literals, newlines are preserved")
    func example2_13() throws {
        let yaml = """
        # ASCII Art
        --- |
          \\//||\\/||
          // ||  ||__
        """
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "\\//||\\/||\n// ||  ||__\n")
    }

    @Test("Example 2.14: In the folded scalars, newlines become spaces")
    func example2_14() throws {
        let yaml = """
        --- >
          Mark McGwire's
          year was crippled
          by a knee injury.
        """
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        #expect(s.string == "Mark McGwire's year was crippled by a knee injury.\n")
    }

    @Test("Example 2.15: Folded newlines are preserved for more indented and blank lines")
    func example2_15() throws {
        let yaml = """
        --- >
         Sammy Sosa completed another
         fine season with great stats.

           63 Home Runs
           0.288 Batting Average

         What a year!
        """
        let node = try compose(yaml: yaml)
        guard case .scalar(let s) = node else {
            Issue.record("Expected scalar"); return
        }
        let expected = "Sammy Sosa completed another fine season with great stats.\n\n  63 Home Runs\n  0.288 Batting Average\n\nWhat a year!\n"
        #expect(s.string == expected)
    }

    @Test("Example 2.16: Indentation determines scope")
    func example2_16() throws {
        let yaml = """
        name: Mark McGwire
        accomplishment: >
          Mark set a major league
          home run record in 1998.
        stats: |
          65 Home Runs
          0.278 Batting Average
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["name"] == .scalar(.init("Mark McGwire")))
        guard case .scalar(let accomplishment) = map["accomplishment"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(accomplishment.string == "Mark set a major league home run record in 1998.\n")
        guard case .scalar(let stats) = map["stats"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(stats.string == "65 Home Runs\n0.278 Batting Average\n")
    }

    @Test("Example 2.17: Quoted Scalars")
    func example2_17() throws {
        let yaml = """
        unicode: "Sosa did fine.\\u263A"
        control: "\\b1998\\t1999\\t2000\\n"
        hex esc: "\\x0d\\x0a is \\r\\n"

        single: '"Howdy!" he cried.'
        quoted: ' # Not a ''comment''.'
        tie-fighter: '|\\-*-/|'
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let unicode) = map["unicode"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(unicode.string == "Sosa did fine.\u{263A}")

        guard case .scalar(let control) = map["control"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(control.string == "\u{08}1998\t1999\t2000\n")

        guard case .scalar(let hexEsc) = map["hex esc"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(hexEsc.string == "\r\n is \r\n")

        guard case .scalar(let single) = map["single"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(single.string == "\"Howdy!\" he cried.")

        guard case .scalar(let quoted) = map["quoted"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(quoted.string == " # Not a 'comment'.")

        guard case .scalar(let tieFighter) = map["tie-fighter"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(tieFighter.string == "|\\-*-/|")
    }

    @Test("Example 2.18: Multi-line Flow Scalars")
    func example2_18() throws {
        let yaml = """
        plain:
          This unquoted scalar
          spans many lines.

        quoted: "So does this
          quoted scalar.\\n"
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        guard case .scalar(let plain) = map["plain"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(plain.string == "This unquoted scalar spans many lines.")

        guard case .scalar(let quoted) = map["quoted"] else {
            Issue.record("Expected scalar"); return
        }
        #expect(quoted.string == "So does this quoted scalar.\n")
    }

    // MARK: - 2.4 Tags

    @Test("Example 2.19: Integers")
    func example2_19() throws {
        let yaml = """
        canonical: 12345
        decimal: +12345
        octal: 0o14
        hexadecimal: 0xC
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["canonical"] == .scalar(.init("12345")))
        #expect(map["decimal"] == .scalar(.init("+12345")))
        #expect(map["octal"] == .scalar(.init("0o14")))
        #expect(map["hexadecimal"] == .scalar(.init("0xC")))
    }

    @Test("Example 2.20: Floating Point")
    func example2_20() throws {
        let yaml = """
        canonical: 1.23015e+3
        exponential: 12.3015e+02
        fixed: 1230.15
        negative infinity: -.inf
        not a number: .nan
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["canonical"] == .scalar(.init("1.23015e+3")))
        #expect(map["exponential"] == .scalar(.init("12.3015e+02")))
        #expect(map["fixed"] == .scalar(.init("1230.15")))
        #expect(map["negative infinity"] == .scalar(.init("-.inf")))
        #expect(map["not a number"] == .scalar(.init(".nan")))
    }

    @Test("Example 2.21: Miscellaneous")
    func example2_21() throws {
        let yaml = """
        null:
        booleans: [ true, false ]
        string: '012345'
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        // "null:" key with empty value
        #expect(map["null"] == .scalar(.init("")))
        guard case .sequence(let booleans) = map["booleans"] else {
            Issue.record("Expected sequence"); return
        }
        #expect(booleans[0] == .scalar(.init("true")))
        #expect(booleans[1] == .scalar(.init("false")))
        #expect(map["string"] == .scalar(.init("012345")))
    }

    @Test("Example 2.22: Timestamps")
    func example2_22() throws {
        let yaml = """
        canonical: 2001-12-15T02:59:43.1Z
        iso8601: 2001-12-14t21:59:43.10-05:00
        spaced: 2001-12-14 21:59:43.10 -5
        date: 2002-12-14
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["canonical"] == .scalar(.init("2001-12-15T02:59:43.1Z")))
        #expect(map["iso8601"] == .scalar(.init("2001-12-14t21:59:43.10-05:00")))
        #expect(map["spaced"] == .scalar(.init("2001-12-14 21:59:43.10 -5")))
        #expect(map["date"] == .scalar(.init("2002-12-14")))
    }

    @Test("Example 2.23: Various Explicit Tags")
    func example2_23() throws {
        let yaml = """
        ---
        not-date: !!str 2002-04-28

        picture: !!binary |
         R0lGODlhDAAMAIQAAP//9/X
         17unp5WZmZgAAAOfn515eXv
         Pz7Y6OjuDg4J+fn5OTk6enp
         56enmleECcgggoBADs=

        application specific tag: !something |
         The semantics of the tag
         above may be different for
         different documents.
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        // Tags !!str, !!binary, !something should be recognized
        #expect(map["not-date"] == .scalar(.init("2002-04-28")))
    }

    @Test("Example 2.24: Global Tags")
    func example2_24() throws {
        let yaml = """
        %TAG ! tag:clarkevans.com,2002:
        --- !shape
          # Use the ! handle for presenting
          # tag:clarkevans.com,2002:circle
        - !circle
          center: &ORIGIN {x: 73, y: 129}
          radius: 7
        - !line
          start: *ORIGIN
          finish: { x: 89, y: 102 }
        - !label
          start: *ORIGIN
          color: 0xFFEEBB
          text: Pretty vector drawing.
        """
        // This requires %TAG directive, tags, anchors, aliases
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 3)
        guard case .mapping(let circle) = seq[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(circle["radius"] == .scalar(.init("7")))
    }

    @Test("Example 2.25: Unordered Sets")
    func example2_25() throws {
        let yaml = """
        # Sets are represented as a
        # Mapping where each key is
        # associated with a null value
        --- !!set
        ? Mark McGwire
        ? Sammy Sosa
        ? Ken Griffey
        """
        // Requires complex mapping keys (? key syntax) and tags
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map.count == 3)
    }

    @Test("Example 2.26: Ordered Mappings")
    func example2_26() throws {
        let yaml = """
        # Ordered maps are represented as
        # A sequence of mappings, with
        # each mapping having one key
        --- !!omap
        - Mark McGwire: 65
        - Sammy Sosa: 63
        - Ken Griffey: 58
        """
        let node = try compose(yaml: yaml)
        guard case .sequence(let seq) = node else {
            Issue.record("Expected sequence"); return
        }
        #expect(seq.count == 3)
        guard case .mapping(let first) = seq[0] else {
            Issue.record("Expected mapping"); return
        }
        #expect(first["Mark McGwire"] == .scalar(.init("65")))
    }

    @Test("Example 2.27: Invoice")
    func example2_27() throws {
        let yaml = """
        --- !<tag:clarkevans.com,2002:invoice>
        invoice: 34843
        date   : 2001-01-23
        bill-to: &id001
          given  : Chris
          family : Dumars
          address:
            lines: |
              458 Walkman Dr.
              Suite #292
            city    : Royal Oak
            state   : MI
            postal  : 48046
        ship-to: *id001
        product:
        - sku         : BL394D
          quantity    : 4
          description : Basketball
          price       : 450.00
        - sku         : BL4438H
          quantity    : 1
          description : Super Hoop
          price       : 2392.00
        tax  : 251.42
        total: 4443.52
        comments:
          Late afternoon is best.
          Backup contact is Nancy
          Billsmer @ 338-4338.
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["invoice"] == .scalar(.init("34843")))
        #expect(map["date"] == .scalar(.init("2001-01-23")))

        // bill-to mapping
        guard case .mapping(let billTo) = map["bill-to"] else {
            Issue.record("Expected mapping for bill-to"); return
        }
        #expect(billTo["given"] == .scalar(.init("Chris")))
        #expect(billTo["family"] == .scalar(.init("Dumars")))
        guard case .mapping(let address) = billTo["address"] else {
            Issue.record("Expected mapping for address"); return
        }
        guard case .scalar(let lines) = address["lines"] else {
            Issue.record("Expected scalar for lines"); return
        }
        #expect(lines.string == "458 Walkman Dr.\nSuite #292\n")
        #expect(address["city"] == .scalar(.init("Royal Oak")))

        // ship-to should be alias to bill-to (anchor/alias)
        guard case .mapping(let shipTo) = map["ship-to"] else {
            Issue.record("Expected mapping for ship-to"); return
        }
        #expect(shipTo["given"] == .scalar(.init("Chris")))

        // product sequence
        guard case .sequence(let products) = map["product"] else {
            Issue.record("Expected sequence for product"); return
        }
        #expect(products.count == 2)

        #expect(map["tax"] == .scalar(.init("251.42")))
        #expect(map["total"] == .scalar(.init("4443.52")))

        // Multi-line plain scalar
        guard case .scalar(let comments) = map["comments"] else {
            Issue.record("Expected scalar for comments"); return
        }
        #expect(comments.string == "Late afternoon is best. Backup contact is Nancy Billsmer @ 338-4338.")
    }

    @Test("Example 2.28: Log File")
    func example2_28() throws {
        // Test only the first document of the log file
        let yaml = """
        ---
        Time: 2001-11-23 15:01:42 -5
        User: ed
        Warning:
          This is an error message
          for the log file
        """
        let node = try compose(yaml: yaml)
        guard case .mapping(let map) = node else {
            Issue.record("Expected mapping"); return
        }
        #expect(map["Time"] == .scalar(.init("2001-11-23 15:01:42 -5")))
        #expect(map["User"] == .scalar(.init("ed")))
        guard case .scalar(let warning) = map["Warning"] else {
            Issue.record("Expected scalar for Warning"); return
        }
        #expect(warning.string == "This is an error message for the log file")
    }
}
