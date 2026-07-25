import SousCore
import Testing

// The scalar fields: what a value reads as, and how an unrecognized or repeated key is
// handled. Values are literal text with no type coercion, so "1.0" stays the string it was
// written as. The header's shape is covered by the header suites, and list-valued fields
// by the list suite.

@Suite("Metadata header")
struct MetadataTests {
    @Test
    func parsesTheRecognizedScalarFields() {
        let metadata = Metadata.read("""
        title: Herb Omelette
        language: en
        version: 1.0
        servings: 4
        source: https://example.com/omelette
        """)
        #expect(metadata.title == "Herb Omelette")
        #expect(metadata.language == "en")
        #expect(metadata.version == "1.0")
        #expect(metadata.servings == 4)
        #expect(metadata.source == "https://example.com/omelette")
    }

    // The servings value reads as its leading numeric quantity, in every form an amount
    // fence allows.

    @Test(arguments: [
        (value: "6", servings: 6.0),
        (value: "2.5", servings: 2.5),
        (value: "1/2", servings: 0.5),
        (value: "1 1/2", servings: 1.5)
    ])
    func parsesEveryQuantityFormOfTheServingsValue(value: String, servings: Double) {
        #expect(Metadata.read("servings: \(value)").servings == servings)
    }

    @Test
    func leavesNonNumericServingsUnsetButPreserved() {
        let metadata = Metadata.read("servings: six")
        #expect(metadata.servings == nil)
        #expect(metadata["servings"] == "six")
    }

    @Test(arguments: [
        (header: "servings: 6 ", value: "6 "),
        (header: "servings:  6", value: "6")
    ])
    func readsServingsSurroundedByWhitespaceAsANumberWhilePreservingItVerbatim(header: String, value: String) {
        let metadata = Metadata.read(header)
        #expect(metadata.servings == 6)
        #expect(metadata["servings"] == value)
    }

    // An amount-valued field is read as a fence is, so a number it states and cannot finish is
    // reported there too. Every other field is literal text, which states no number to report.

    @Test(arguments: ["servings: 3,2", "yield: 3,2 kg", "yield: [1 L, 1/0 kg]", "servings: .5"])
    func warnsAboutANumberAnAmountFieldCannotFinish(header: String) {
        let parsed = SousParser().parseRecipe("---\n\(header)\n---")

        #expect(parsed.diagnostics.map(\.kind) == [.malformedQuantity])
        #expect(parsed.value.metadata.entries.count == 1)
    }

    @Test(arguments: ["title: 3,2 kg", "source: 1/0", "servings: six", "servings: 6 people"])
    func reportsNothingForAValueStatingNoNumberItCannotFinish(header: String) {
        #expect(SousParser().parseRecipe("---\n\(header)\n---").diagnostics.isEmpty)
    }

    // An unrecognized key is preserved and warned about, never dropped.

    @Test
    func warnsAboutAnUnrecognizedKeyAndPreservesIt() {
        let source = """
        ---
        chef: Alice
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.metadata["chef"] == "Alice")
        #expect(parsed.diagnostics.contains(where: { $0.kind == .unknownHeaderKey }))
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
        let entries = Metadata.read("title: First\ntitle: Second").entries
        #expect(entries.map(\.key) == ["title", "title"])
    }
}
