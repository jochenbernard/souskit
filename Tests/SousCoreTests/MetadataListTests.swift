import SousCore
import Testing

// Whether a value is a list is decided by the field, not by its punctuation, so only a
// list-valued field reads `[...]` as a list.

@Suite("Metadata lists")
struct MetadataListTests {
    @Test
    func parsesAnInlineTagList() {
        #expect(Metadata.read("tags: [italian, make-ahead]").tags == ["italian", "make-ahead"])
    }

    @Test
    func trimsWhitespaceAroundInlineListItems() {
        let tags = Metadata.read("tags: [comfort food, italian, make-ahead]").tags
        #expect(tags == ["comfort food", "italian", "make-ahead"])
    }

    @Test
    func readsBracketsAsLiteralTextForANonListField() {
        #expect(Metadata.read("note: [see the sidebar]")["note"] == "[see the sidebar]")
    }

    @Test
    func readsAnUnbracketedListValueAsASingleItem() {
        #expect(Metadata.read("tags: italian").tags == ["italian"])
    }

    @Test(arguments: [
        "tags: [italian, quick] ",
        "tags:  [italian, quick]",
        "tags: \t[italian, quick]\t"
    ])
    func readsAnInlineListWithSurroundingWhitespaceAsAList(header: String) {
        #expect(Metadata.read(header).tags == ["italian", "quick"])
    }

    @Test
    func trimsWhitespaceAroundASingleLiteralItem() {
        #expect(Metadata.read("tags: italian ").tags == ["italian"])
    }

    // Inside the brackets a backslash escapes the characters the list gives a meaning of its
    // own, so an item can hold a separator or a bracket.

    @Test
    func readsAnEscapedSeparatorAsPartOfAnItem() {
        #expect(Metadata.read("tags: [comfort food\\, italian]").tags == ["comfort food, italian"])
    }

    @Test
    func readsAnEscapedBracketAsPartOfAnItem() {
        #expect(Metadata.read("tags: [\\[sugar]").tags == ["[sugar"])
        #expect(Metadata.read("tags: [a\\]b, c]").tags == ["a]b", "c"])
    }

    @Test
    func readsAnEscapedBackslashAsOneBackslash() {
        #expect(Metadata.read("tags: [a\\\\b]").tags == ["a\\b"])
    }

    @Test
    func keepsABackslashBeforeACharacterThatIsNotEscapableInAList() {
        #expect(Metadata.read("tags: [C:\\x]").tags == ["C:\\x"])
    }

    @Test
    func doesNotCloseAnInlineListOnAnEscapedBracket() {
        // The list never closes, so the value is not a well-formed inline list and reads as
        // one literal item, escapes and all.
        #expect(Metadata.read("tags: [a\\]").tags == ["[a\\]"])
    }

    @Test(arguments: [
        "tags: [a]b]",
        "tags: [a]b",
        "tags: [a], [b]"
    ])
    func doesNotReadAValueThatContinuesPastItsClosingBracketAsAList(header: String) {
        // The list closes on the first unescaped "]", so anything after it leaves the value
        // unclosed and the whole of it is one literal item.
        let value = Metadata.read(header).tags

        #expect(value.count == 1)
        #expect(value.first?.hasPrefix("[") == true)
    }

    @Test
    func doesNotEscapeInsideABareListValue() {
        // Escaping belongs to the inline form; a bare value is literal to the end of the line.
        #expect(Metadata.read("tags: a\\, b").tags == ["a\\, b"])
    }

    @Test
    func doesNotEscapeInsideAScalarValue() {
        #expect(Metadata.read("source: C:\\photos\\x").source == "C:\\photos\\x")
    }

    @Test
    func readsAnUnbracketedListValueHoldingACommaAsOneItem() {
        #expect(Metadata.read("tags: comfort food, italian").tags == ["comfort food, italian"])
    }

    @Test
    func readsAnUnterminatedBracketAsLiteralText() {
        #expect(Metadata.read("tags: [italian").tags == ["[italian"])
    }

    @Test
    func readsAListKeyWithNoValueAsNoItems() {
        #expect(Metadata.read("tags:").tags.isEmpty)
    }

    // A list of nothing has no inline form, so it writes as the key alone whichever spelling
    // it was read from.

    @Test(arguments: ["---\ntags:\n---", "---\ntags: []\n---"])
    func writesAListOfNoItemsAsTheKeyAlone(source: String) {
        #expect(Recipe.read(source).serialized() == "---\ntags:\n---")
    }

    @Test
    func readsAnEmptyInlineListAsNoItems() {
        #expect(Metadata.read("tags: []").tags.isEmpty)
    }

    @Test(arguments: [
        "tags: [ ]",
        "tags: [,]",
        "tags: [, ,]"
    ])
    func readsAnInlineListOfNothingButSeparatorsAsNoItems(header: String) {
        #expect(Metadata.read(header).tags.isEmpty)
    }

    @Test
    func dropsEmptyItemsFromAnInlineList() {
        #expect(Metadata.read("tags: [italian, , make-ahead,]").tags == ["italian", "make-ahead"])
    }

    // A repeated list key combines its occurrences, rather than the last one overwriting
    // the earlier ones as a repeated scalar key does.

    @Test
    func warnsAboutARepeatedListKeyAndMergesItsItems() {
        let source = """
        ---
        tags: [italian]
        tags: [quick]
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.diagnostics.contains(where: { $0.kind == .repeatedListKey }))
        #expect(parsed.value.metadata.tags == ["italian", "quick"])
    }

    @Test
    func mergesItemsAcrossRepeatedListKeysWrittenInDifferentForms() {
        #expect(Metadata.read("tags: italian\ntags: [quick, make-ahead]").tags == ["italian", "quick", "make-ahead"])
    }

    @Test
    func mergesItemsAcrossRepeatedListKeysInDocumentOrder() {
        #expect(
            Metadata.read("tags: [comfort food, italian]\ntags: [make-ahead]").tags
                == ["comfort food", "italian", "make-ahead"]
        )
    }
}
