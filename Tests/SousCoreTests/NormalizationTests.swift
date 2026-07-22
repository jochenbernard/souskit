import SousCore
import Testing

// One routine matches every name the language compares, so a group a reference resolves to is
// a group a consumer looking the same name up finds. It folds capitalization and accents,
// trims the whitespace around the name, and drops each leading connective word.
//
// Nothing else is changed. The whitespace within a name still tells two names apart, and a
// connective that is not leading is part of the name.

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
        // Bechamel, Creme Brulee, and Jalapeno, each written with the accents it carries.
        (text: "B\u{E9}chamel", normalized: "bechamel"),
        (text: "B\u{C9}CHAMEL", normalized: "bechamel"),
        (text: "Cr\u{E8}me Br\u{FB}l\u{E9}e", normalized: "creme brulee"),
        (text: "Jalape\u{F1}o", normalized: "jalapeno"),
        // The same letter written as a base letter and a combining mark folds the same way.
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

    // Leading connectives

    @Test
    func statesTheWordsItDrops() {
        #expect(Normalization.leadingConnectives == ["a", "an", "of", "the"])
    }

    @Test(arguments: [
        (text: "of parmesan", normalized: "parmesan"),
        (text: "the sauce", normalized: "sauce"),
        (text: "a pinch", normalized: "pinch"),
        (text: "an onion", normalized: "onion"),
        // A name is stripped for as long as it opens with a connective.
        (text: "of the sauce", normalized: "sauce"),
        (text: "of  the  sauce", normalized: "sauce"),
        // The words are matched after capitalization and accents are folded.
        (text: "Of The Sauce", normalized: "sauce"),
        (text: "of\tthe\tsauce", normalized: "sauce"),
        // A name that is nothing but connectives states no name at all.
        (text: "of", normalized: ""),
        (text: "of the", normalized: "")
    ])
    func dropsEachLeadingConnective(text: String, normalized: String) {
        #expect(Normalization.normalized(text) == normalized)
    }

    // A connective is a whole word, so a name only opens with one when whitespace or the end
    // of the name follows it.

    @Test(arguments: [
        (text: "office", normalized: "office"),
        (text: "theme", normalized: "theme"),
        (text: "anchovies", normalized: "anchovies"),
        (text: "of-the-day", normalized: "of-the-day"),
        // A connective that is not leading belongs to the name.
        (text: "sauce of the day", normalized: "sauce of the day"),
        (text: "leg of lamb", normalized: "leg of lamb")
    ])
    func dropsNothingButALeadingConnectiveWord(text: String, normalized: String) {
        #expect(Normalization.normalized(text) == normalized)
    }

    @Test(arguments: ["  Of The B\u{E9}chamel  ", "baby  spinach", "", "of"])
    func normalizingANormalizedNameChangesNothing(text: String) {
        let normalized = Normalization.normalized(text)

        #expect(Normalization.normalized(normalized) == normalized)
    }
}
