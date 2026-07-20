import SousCore
import Testing

@Suite("Metadata header")
struct MetadataTests {
    @Test
    func parsesTheRecognizedScalarFields() {
        let source = """
        ---
        title: Herb Omelette
        language: en
        version: 1.0
        servings: 4
        source: https://example.com/omelette
        ---
        """

        let metadata = SousParser().parseRecipe(source).value.metadata
        #expect(metadata.title == "Herb Omelette")
        #expect(metadata.language == "en")
        #expect(metadata.version == "1.0")
        #expect(metadata.servings == 4)
        #expect(metadata.source == "https://example.com/omelette")
    }

    @Test
    func splitsAKeyOnlyAtTheFirstColonFollowedByASpace() {
        let source = """
        ---
        source: https://example.com/recipes/1
        ---
        """

        let metadata = SousParser().parseRecipe(source).value.metadata
        #expect(metadata.source == "https://example.com/recipes/1")
    }

    @Test
    func keepsValuesAsLiteralTextWithoutCoercion() {
        let source = """
        ---
        version: 1.0
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.version == "1.0")
    }

    @Test
    func parsesTheServingsAsAnInteger() {
        let source = """
        ---
        servings: 6
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.servings == 6)
    }

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
    func preservesAnUnrecognizedKey() {
        let source = """
        ---
        chef: Alice
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata["chef"] == "Alice")
    }

    @Test
    func warnsAboutAnUnrecognizedKey() {
        let source = """
        ---
        chef: Alice
        ---
        """

        let diagnostics = SousParser().parseRecipe(source).diagnostics
        #expect(diagnostics.contains(where: { $0.kind == .unknownHeaderKey }))
    }

    @Test
    func doesNotWarnAboutRecognizedKeys() {
        let source = """
        ---
        title: Toast
        servings: 1
        ---
        """

        #expect(SousParser().parseRecipe(source).diagnostics.isEmpty)
    }

    @Test
    func warnsAboutARepeatedScalarKeyAndKeepsTheLastValue() {
        let source = """
        ---
        title: First
        title: Second
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.metadata.title == "Second")
        #expect(parsed.diagnostics.contains(where: { $0.kind == .repeatedScalarKey }))
    }

    @Test
    func preservesEveryEntryIncludingRepeats() {
        let source = """
        ---
        title: First
        title: Second
        ---
        """

        let entries = SousParser().parseRecipe(source).value.metadata.entries
        #expect(entries.map(\.key) == ["title", "title"])
    }

    @Test
    func warnsAboutARepeatedUnrecognizedKeyAndKeepsTheLastValue() {
        let source = """
        ---
        chef: Alice
        chef: Bob
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.diagnostics.contains(where: { $0.kind == .repeatedScalarKey }))
        #expect(parsed.value.metadata["chef"] == "Bob")
    }

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

    @Test
    func recoversFromAnUnterminatedHeader() {
        let source = """
        ---
        title: Buttered Toast
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.metadata.title == "Buttered Toast")
        #expect(parsed.diagnostics.contains(where: { $0.kind == .unterminatedHeader }))
    }

    @Test
    func treatsAFileWithoutALeadingFenceAsHavingNoHeader() {
        let source = """
        Toast the bread.
        ---
        title: X
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.title == nil)
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
    func returnsTheLastValueForARepeatedKeyFromTheSubscript() {
        let source = """
        ---
        title: First
        title: Second
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata["title"] == "Second")
    }

    @Test
    func ignoresALeadingByteOrderMark() {
        let source = "\u{FEFF}---\ntitle: Buttered Toast\n---"

        #expect(SousParser().parseRecipe(source).value.metadata.title == "Buttered Toast")
    }

    @Test
    func readsAKeyEndingTheLineAsAnEmptyValue() throws {
        let source = """
        ---
        title:
        ---
        """

        let title = try #require(SousParser().parseRecipe(source).value.metadata.title)
        #expect(title.isEmpty)
    }

    @Test
    func leavesNonNumericServingsUnsetButPreserved() {
        let source = """
        ---
        servings: six
        ---
        """

        let metadata = SousParser().parseRecipe(source).value.metadata
        #expect(metadata.servings == nil)
        #expect(metadata["servings"] == "six")
    }

    @Test
    func skipsAHeaderLineWithNoKeyValueSeparator() {
        let source = """
        ---
        title: Toast
        stray line
        ---
        """

        let metadata = SousParser().parseRecipe(source).value.metadata
        #expect(metadata.title == "Toast")
        #expect(metadata.entries.map(\.key) == ["title"])
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

    @Test
    func parsesAnEmptyHeader() {
        let source = """
        ---
        ---
        """

        let metadata = SousParser().parseRecipe(source).value.metadata
        #expect(metadata.title == nil)
        #expect(metadata.entries.isEmpty)
    }
}
