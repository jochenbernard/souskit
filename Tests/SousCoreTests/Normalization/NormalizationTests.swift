import SousCore
import Testing

@Suite("Normalization")
struct NormalizationTests {
    @Test(arguments: [
        (text: "Bechamel", normalized: "bechamel"),
        (text: "BECHAMEL", normalized: "bechamel"),
        (text: "Sweet Shortcrust Pastry", normalized: "sweet shortcrust pastry")
    ])
    func foldsCapitalization(text: String, normalized: String) {
        #expect(Normalization.normalized(text) == normalized)
    }

    @Test(arguments: [
        (text: "B\u{E9}chamel", normalized: "bechamel"),
        (text: "B\u{C9}CHAMEL", normalized: "bechamel"),
        (text: "Cr\u{E8}me Br\u{FB}l\u{E9}e", normalized: "creme brulee"),
        (text: "Ni\u{E7}oise", normalized: "nicoise"),
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

    @Test
    func dropsTheWhitespaceAfterAConnectiveAlongWithIt() {
        #expect(Normalization.normalized("of  bechamel") == "bechamel")
        #expect(Normalization.normalized("of  bechamel") == Normalization.normalized("of bechamel"))
    }

    @Test
    func statesTheWordsItDrops() {
        #expect(Normalization.leadingConnectives == ["a", "an", "of", "the"])
    }

    @Test(arguments: [
        (text: "of gruyere", normalized: "gruyere"),
        (text: "the bechamel", normalized: "bechamel"),
        (text: "a pinch", normalized: "pinch"),
        (text: "an onion", normalized: "onion"),
        (text: "of the bechamel", normalized: "bechamel"),
        (text: "of  the  bechamel", normalized: "bechamel"),
        (text: "Of The Bechamel", normalized: "bechamel"),
        (text: "of\tthe\tbechamel", normalized: "bechamel")
    ])
    func dropsEachLeadingConnective(text: String, normalized: String) {
        #expect(Normalization.normalized(text) == normalized)
    }

    @Test(arguments: [
        (text: "of", normalized: "of"),
        (text: "The", normalized: "the"),
        (text: "of the", normalized: "of the"),
        (text: "  An  A  ", normalized: "an  a")
    ])
    func dropsNoConnectiveFromANameThatStatesNothingElse(text: String, normalized: String) {
        #expect(Normalization.normalized(text) == normalized)
    }

    @Test
    func tellsApartTwoGroupsNamedOnlyByConnectives() {
        #expect(Normalization.normalized("The") != Normalization.normalized("A"))
    }

    @Test(arguments: [
        (text: "office", normalized: "office"),
        (text: "theme", normalized: "theme"),
        (text: "anchovies", normalized: "anchovies"),
        (text: "of-the-day", normalized: "of-the-day"),
        (text: "bechamel of the day", normalized: "bechamel of the day"),
        (text: "leg of lamb", normalized: "leg of lamb")
    ])
    func dropsNothingButALeadingConnectiveWord(text: String, normalized: String) {
        #expect(Normalization.normalized(text) == normalized)
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
