import SousCore
import Testing

@Suite("Normalization")
struct NormalizationTests {
    @Test(arguments: [
        (text: "Bechamel", normalized: "bechamel"),
        (text: "BECHAMEL", normalized: "bechamel"),
        (text: "Court-Bouillon", normalized: "court-bouillon")
    ])
    func foldsCapitalization(text: String, normalized: String) {
        #expect(Normalization.normalized(text) == normalized)
    }

    @Test(arguments: [
        (text: "B\u{E9}chamel", normalized: "bechamel"),
        (text: "B\u{C9}CHAMEL", normalized: "bechamel"),
        (text: "Cr\u{EA}pes", normalized: "crepes"),
        (text: "Cro\u{FB}tons", normalized: "croutons"),
        (text: "Proven\u{E7}ale", normalized: "provencale"),
        (text: "Be\u{301}chamel", normalized: "bechamel")
    ])
    func foldsAccents(text: String, normalized: String) {
        #expect(Normalization.normalized(text) == normalized)
    }

    @Test(arguments: [
        (text: "  Bechamel  ", normalized: "bechamel"),
        (text: "\tBechamel\n", normalized: "bechamel"),
        (text: "   ", normalized: ""),
        (text: "", normalized: "")
    ])
    func trimsTheWhitespaceAroundAName(text: String, normalized: String) {
        #expect(Normalization.normalized(text) == normalized)
    }

    @Test
    func keepsTheWhitespaceWithinAName() {
        #expect(Normalization.normalized("pearl  onions") == "pearl  onions")
        #expect(Normalization.normalized("pearl onions") != Normalization.normalized("pearl  onions"))
    }

    @Test(arguments: [
        "  Of The B\u{E9}chamel  ",
        "pearl  onions",
        "",
        "of",
        "caf\u{FEFF}\u{0301}\u{0301}",
        "e\u{0301}\u{0301}\u{0301}",
        "\u{2028}\u{1F3FF}\u{0486}",
        "of \u{1F3FF}\u{0486}"
    ])
    func normalizingANormalizedNameChangesNothing(text: String) {
        let normalized = Normalization.normalized(text)

        #expect(Normalization.normalized(normalized) == normalized)
    }
}
