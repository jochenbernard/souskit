import SousCore
import Testing

@Suite("Normalization")
struct NormalizationTests {
    @Test(arguments: [
        (text: "Bechamel", normalized: "bechamel"),
        (text: "BECHAMEL", normalized: "bechamel"),
        (text: "Rich Tomato Sauce", normalized: "rich tomato sauce")
    ])
    func foldsCapitalization(text: String, normalized: String) {
        #expect(Normalization.normalized(text) == normalized)
    }

    @Test(arguments: [
        (text: "B\u{E9}chamel", normalized: "bechamel"),
        (text: "B\u{C9}CHAMEL", normalized: "bechamel"),
        (text: "Cr\u{E8}me Br\u{FB}l\u{E9}e", normalized: "creme brulee"),
        (text: "Jalape\u{F1}o", normalized: "jalapeno"),
        (text: "Be\u{301}chamel", normalized: "bechamel")
    ])
    func foldsAccents(text: String, normalized: String) {
        #expect(Normalization.normalized(text) == normalized)
    }

    @Test(arguments: [
        (text: "  Sauce  ", normalized: "sauce"),
        (text: "\tSauce\n", normalized: "sauce"),
        (text: "   ", normalized: ""),
        (text: "", normalized: "")
    ])
    func trimsTheWhitespaceAroundAName(text: String, normalized: String) {
        #expect(Normalization.normalized(text) == normalized)
    }

    @Test
    func keepsTheWhitespaceWithinAName() {
        #expect(Normalization.normalized("baby  spinach") == "baby  spinach")
        #expect(Normalization.normalized("baby spinach") != Normalization.normalized("baby  spinach"))
    }

    @Test
    func dropsTheWhitespaceAfterAConnectiveAlongWithIt() {
        #expect(Normalization.normalized("of  sauce") == "sauce")
        #expect(Normalization.normalized("of  sauce") == Normalization.normalized("of sauce"))
    }

    @Test
    func statesTheWordsItDrops() {
        #expect(Normalization.leadingConnectives == ["a", "an", "of", "the"])
    }

    @Test(arguments: [
        (text: "of parmesan", normalized: "parmesan"),
        (text: "the sauce", normalized: "sauce"),
        (text: "a pinch", normalized: "pinch"),
        (text: "an onion", normalized: "onion"),
        (text: "of the sauce", normalized: "sauce"),
        (text: "of  the  sauce", normalized: "sauce"),
        (text: "Of The Sauce", normalized: "sauce"),
        (text: "of\tthe\tsauce", normalized: "sauce")
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
        (text: "sauce of the day", normalized: "sauce of the day"),
        (text: "leg of lamb", normalized: "leg of lamb")
    ])
    func dropsNothingButALeadingConnectiveWord(text: String, normalized: String) {
        #expect(Normalization.normalized(text) == normalized)
    }

    @Test(arguments: [
        "  Of The B\u{E9}chamel  ",
        "baby  spinach",
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
