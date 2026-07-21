import SousCore
import Testing

// Whether a value is a list is decided by the field, not by its punctuation, so only a
// list-valued field reads `[...]` as a list.

@Suite("Metadata lists")
struct MetadataListTests {
    @Test
    func parsesAnInlineTagList() {
        let source = """
        ---
        tags: [italian, make-ahead]
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.tags == ["italian", "make-ahead"])
    }

    @Test
    func trimsWhitespaceAroundInlineListItems() {
        let source = """
        ---
        tags: [comfort food, italian, make-ahead]
        ---
        """

        let tags = SousParser().parseRecipe(source).value.metadata.tags
        #expect(tags == ["comfort food", "italian", "make-ahead"])
    }

    @Test
    func readsBracketsAsLiteralTextForANonListField() {
        let source = """
        ---
        note: [see the sidebar]
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata["note"] == "[see the sidebar]")
    }

    @Test
    func readsAnUnbracketedListValueAsASingleItem() {
        let source = """
        ---
        tags: italian
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.tags == ["italian"])
    }

    @Test
    func readsAnUnterminatedBracketAsLiteralText() {
        let source = """
        ---
        tags: [italian
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.tags == ["[italian"])
    }

    @Test
    func readsAListKeyWithNoValueAsNoItems() {
        let source = """
        ---
        tags:
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.tags.isEmpty)
    }

    @Test
    func readsAnEmptyInlineListAsNoItems() {
        let source = """
        ---
        tags: []
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.tags.isEmpty)
    }

    @Test(arguments: [
        "---\ntags: [ ]\n---",
        "---\ntags: [,]\n---",
        "---\ntags: [, ,]\n---"
    ])
    func readsAnInlineListOfNothingButSeparatorsAsNoItems(source: String) {
        #expect(SousParser().parseRecipe(source).value.metadata.tags.isEmpty)
    }

    @Test
    func dropsEmptyItemsFromAnInlineList() {
        let source = """
        ---
        tags: [italian, , make-ahead,]
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.tags == ["italian", "make-ahead"])
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
    func mergesItemsAcrossRepeatedListKeysInDocumentOrder() {
        let source = """
        ---
        tags: [comfort food, italian]
        tags: [make-ahead]
        ---
        """

        #expect(
            SousParser().parseRecipe(source).value.metadata.tags
                == ["comfort food", "italian", "make-ahead"]
        )
    }
}
