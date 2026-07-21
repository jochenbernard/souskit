import SousCore
import Testing

// The scalar fields: what a value reads as, and how an unrecognized or repeated key is
// handled. The header's shape is covered by the header suites, and list-valued fields by
// the list suite.

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
    func keepsValuesAsLiteralTextWithoutCoercion() {
        let source = """
        ---
        version: 1.0
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.version == "1.0")
    }

    // The servings value reads as its leading numeric quantity, in every form an amount
    // fence allows.

    @Test
    func parsesTheServingsAsANumber() {
        let source = """
        ---
        servings: 6
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.servings == 6)
    }

    @Test
    func parsesADecimalServingsValue() {
        let source = """
        ---
        servings: 2.5
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.servings == 2.5)
    }

    @Test
    func parsesAFractionServingsValue() {
        let source = """
        ---
        servings: 1/2
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.servings == 0.5)
    }

    @Test
    func parsesAMixedNumberServingsValue() {
        let source = """
        ---
        servings: 1 1/2
        ---
        """

        #expect(SousParser().parseRecipe(source).value.metadata.servings == 1.5)
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
    func readsServingsSurroundedByWhitespaceAsANumberWhilePreservingItVerbatim() {
        let source = "---\nservings: 6 \n---"

        let metadata = SousParser().parseRecipe(source).value.metadata
        #expect(metadata.servings == 6)
        #expect(metadata["servings"] == "6 ")
    }

    // An unrecognized key is preserved and warned about, never dropped.

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

    // A repeated scalar key warns and keeps its last occurrence, while every occurrence
    // survives in the raw store.

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
}
