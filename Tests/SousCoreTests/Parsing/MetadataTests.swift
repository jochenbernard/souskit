import SousCore
import Testing

@Suite("Metadata header")
struct MetadataTests {
    @Test
    func parsesTheRecognizedScalarFields() {
        let metadata = Metadata.read("""
        title: Quiche Lorraine
        language: en
        version: 1.0
        servings: 6
        source: https://example.com/quiche-lorraine
        """)
        #expect(metadata.title == "Quiche Lorraine")
        #expect(metadata.language == "en")
        #expect(metadata.version == "1.0")
        #expect(metadata.servings == 6)
        #expect(metadata.source == "https://example.com/quiche-lorraine")
    }

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

    @Test(arguments: ["servings: 6 ", "servings:  6", "servings: \t6\t"])
    func readsAValueTrimmedOfTheWhitespaceAroundIt(header: String) {
        let metadata = Metadata.read(header)

        #expect(metadata.servings == 6)
        #expect(metadata["servings"] == "6")
    }

    @Test(arguments: [
        (header: "title: Vinaigrette ", key: "title", value: "Vinaigrette"),
        (header: "chef: Camille ", key: "chef", value: "Camille"),
        (header: "source: https://example.com/x  ", key: "source", value: "https://example.com/x")
    ])
    func trimsTheValueOfEveryKeyRecognizedOrNot(
        header: String,
        key: String,
        value: String
    ) {
        #expect(Metadata.read(header)[key] == value)
    }

    @Test
    func writesAValueWithoutTheWhitespaceItNoLongerStates() {
        #expect(Recipe.read("---\ntitle: Vinaigrette \n---").serialized() == "---\ntitle: Vinaigrette\n---")
    }

    @Test
    func tellsApartNoTwoTitlesThatDifferOnlyByTheWhitespaceAroundThem() {
        #expect(Metadata.read("title: Vinaigrette ").title == Metadata.read("title: Vinaigrette").title)
    }

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

    @Test
    func preservesAnUnrecognizedKey() {
        let source = """
        ---
        chef: Camille
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.metadata["chef"] == "Camille")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func doesNotWarnAboutRecognizedKeys() {
        let source = """
        ---
        title: Vinaigrette
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
    func warnsAboutARepeatedUnrecognizedKeyAndKeepsTheLastValue() {
        let source = """
        ---
        chef: Camille
        chef: Bruno
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.diagnostics.contains(where: { $0.kind == .repeatedScalarKey }))
        #expect(parsed.value.metadata["chef"] == "Bruno")
    }

    @Test
    func preservesEveryEntryIncludingRepeats() {
        let entries = Metadata.read("title: First\ntitle: Second").entries
        #expect(entries.map(\.key) == ["title", "title"])
    }
}
