import SousCore
import Testing

@Suite("Metadata lists")
struct MetadataListTests {
    @Test
    func parsesAnInlineTagList() {
        #expect(Metadata.read("tags: [french, make-ahead]").tags == ["french", "make-ahead"])
    }

    @Test
    func trimsWhitespaceAroundInlineListItems() {
        let tags = Metadata.read("tags: [comfort food, french, make-ahead]").tags
        #expect(tags == ["comfort food", "french", "make-ahead"])
    }

    @Test
    func readsBracketsAsLiteralTextForANonListField() {
        #expect(Metadata.read("note: [see the sidebar]")["note"] == "[see the sidebar]")
    }

    @Test
    func readsAnUnbracketedListValueAsASingleItem() {
        #expect(Metadata.read("tags: french").tags == ["french"])
    }

    @Test(arguments: [
        "tags: [french, quick] ",
        "tags:  [french, quick]",
        "tags: \t[french, quick]\t"
    ])
    func readsAnInlineListWithSurroundingWhitespaceAsAList(header: String) {
        #expect(Metadata.read(header).tags == ["french", "quick"])
    }

    @Test
    func trimsWhitespaceAroundASingleLiteralItem() {
        #expect(Metadata.read("tags: french ").tags == ["french"])
    }

    @Test
    func readsAnEscapedSeparatorAsPartOfAnItem() {
        #expect(Metadata.read("tags: [comfort food\\, french]").tags == ["comfort food, french"])
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
        #expect(Metadata.read("tags: [a\\]").tags == ["[a\\]"])
    }

    @Test(arguments: [
        "tags: [a]b]",
        "tags: [a]b",
        "tags: [a], [b]"
    ])
    func doesNotReadAValueThatContinuesPastItsClosingBracketAsAList(header: String) {
        let value = Metadata.read(header).tags

        #expect(value.count == 1)
        #expect(value.first?.hasPrefix("[") == true)
    }

    @Test
    func doesNotEscapeInsideABareListValue() {
        #expect(Metadata.read("tags: a\\, b").tags == ["a\\, b"])
    }

    @Test
    func doesNotEscapeInsideAScalarValue() {
        #expect(Metadata.read("source: C:\\photos\\x").source == "C:\\photos\\x")
    }

    @Test
    func readsAnUnbracketedListValueHoldingACommaAsOneItem() {
        #expect(Metadata.read("tags: comfort food, french").tags == ["comfort food, french"])
    }

    @Test
    func readsAnUnterminatedBracketAsLiteralText() {
        #expect(Metadata.read("tags: [french").tags == ["[french"])
    }

    @Test
    func readsAValueWhoseBracketsOpenPastItsFirstCharacterAsASingleItem() {
        #expect(Metadata.read("tags: comfort food [french]").tags == ["comfort food [french]"])
    }

    @Test
    func readsAListKeyWithNoValueAsNoItems() {
        #expect(Metadata.read("tags:").tags.isEmpty)
    }

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
        #expect(Metadata.read("tags: [french, , make-ahead,]").tags == ["french", "make-ahead"])
    }

    @Test
    func warnsAboutARepeatedListKeyAndMergesItsItems() {
        let source = """
        ---
        tags: [french]
        tags: [quick]
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.diagnostics.contains(where: { $0.kind == .repeatedListKey }))
        #expect(parsed.value.metadata.tags == ["french", "quick"])
    }

    @Test
    func mergesItemsAcrossRepeatedListKeysWrittenInDifferentForms() {
        #expect(Metadata.read("tags: french\ntags: [quick, make-ahead]").tags == ["french", "quick", "make-ahead"])
    }

    @Test
    func mergesItemsAcrossRepeatedListKeysInDocumentOrder() {
        #expect(
            Metadata.read("tags: [comfort food, french]\ntags: [make-ahead]").tags
                == ["comfort food", "french", "make-ahead"]
        )
    }
}
