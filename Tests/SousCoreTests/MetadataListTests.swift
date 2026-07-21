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

    @Test(arguments: [
        "---\ntags: [italian, quick] \n---",
        "---\ntags:  [italian, quick]\n---",
        "---\ntags: \t[italian, quick]\t\n---"
    ])
    func readsAnInlineListWithSurroundingWhitespaceAsAList(source: String) {
        #expect(SousParser().parseRecipe(source).value.metadata.tags == ["italian", "quick"])
    }

    @Test
    func trimsWhitespaceAroundASingleLiteralItem() {
        #expect(SousParser().parseRecipe("---\ntags: italian \n---").value.metadata.tags == ["italian"])
    }

    // Inside the brackets a backslash escapes the characters the list gives a meaning of its
    // own, so an item can hold a separator or a bracket.

    @Test
    func readsAnEscapedSeparatorAsPartOfAnItem() {
        let source = """
        ---
        tags: [comfort food\\, italian]
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.tags == ["comfort food, italian"])
    }

    @Test
    func readsAnEscapedBracketAsPartOfAnItem() {
        #expect(SousParser().parseRecipe("---\ntags: [\\[sugar]\n---").value.metadata.tags == ["[sugar"])
        #expect(SousParser().parseRecipe("---\ntags: [a\\]b, c]\n---").value.metadata.tags == ["a]b", "c"])
    }

    @Test
    func readsAnEscapedBackslashAsOneBackslash() {
        #expect(SousParser().parseRecipe("---\ntags: [a\\\\b]\n---").value.metadata.tags == ["a\\b"])
    }

    @Test
    func keepsABackslashBeforeACharacterThatIsNotEscapableInAList() {
        #expect(SousParser().parseRecipe("---\ntags: [C:\\x]\n---").value.metadata.tags == ["C:\\x"])
    }

    @Test
    func doesNotCloseAnInlineListOnAnEscapedBracket() {
        // The list never closes, so the value is not a well-formed inline list and reads as
        // one literal item, escapes and all.
        #expect(SousParser().parseRecipe("---\ntags: [a\\]\n---").value.metadata.tags == ["[a\\]"])
    }

    @Test(arguments: [
        "---\ntags: [a]b]\n---",
        "---\ntags: [a]b\n---",
        "---\ntags: [a], [b]\n---"
    ])
    func doesNotReadAValueThatContinuesPastItsClosingBracketAsAList(source: String) {
        // The list closes on the first unescaped "]", so anything after it leaves the value
        // unclosed and the whole of it is one literal item.
        let value = SousParser().parseRecipe(source).value.metadata.tags

        #expect(value.count == 1)
        #expect(value.first?.hasPrefix("[") == true)
    }

    @Test
    func doesNotEscapeInsideABareListValue() {
        // Escaping belongs to the inline form; a bare value is literal to the end of the line.
        #expect(SousParser().parseRecipe("---\ntags: a\\, b\n---").value.metadata.tags == ["a\\, b"])
    }

    @Test
    func doesNotEscapeInsideAScalarValue() {
        #expect(SousParser().parseRecipe("---\nsource: C:\\photos\\x\n---").value.metadata.source == "C:\\photos\\x")
    }

    @Test
    func readsAnUnbracketedListValueHoldingACommaAsOneItem() {
        let source = """
        ---
        tags: comfort food, italian
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.tags == ["comfort food, italian"])
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
    func mergesItemsAcrossRepeatedListKeysWrittenInDifferentForms() {
        let source = """
        ---
        tags: italian
        tags: [quick, make-ahead]
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.tags == ["italian", "quick", "make-ahead"])
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
