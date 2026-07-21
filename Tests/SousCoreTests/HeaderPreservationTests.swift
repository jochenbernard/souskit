import SousCore
import Testing

@Suite("Header preservation")
struct HeaderPreservationTests {
    @Test
    func preservesAHeaderLineWithNoSeparatorAsARawEntry() {
        let source = "---\ntitle: Toast\nstray line\n---"

        let metadata = SousParser().parseRecipe(source).value.metadata
        #expect(metadata.title == "Toast")
        #expect(metadata.entries.contains(where: { $0.value == .raw("stray line") }))
    }

    @Test
    func preservesABlockListItemLineAsARawEntry() {
        let source = "---\ntags:\n  - italian\n---"

        let entries = SousParser().parseRecipe(source).value.metadata.entries
        #expect(entries.contains(where: { $0.value == .raw("  - italian") }))
    }

    @Test
    func preservesANestedBlockLineAsARawEntryRatherThanAnIndentedKey() {
        let source = "---\nnutrition:\n  calories: 640 kcal\n---"

        let entries = SousParser().parseRecipe(source).value.metadata.entries
        #expect(entries.contains(where: { $0.value == .raw("  calories: 640 kcal") }))
        #expect(entries.allSatisfy({ $0.key != "  calories" }))
    }

    @Test
    func skipsABlankHeaderLineSilently() {
        let source = "---\ntitle: Toast\n\nsource: Jane\n---"

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.metadata.entries.map(\.key) == ["title", "source"])
        #expect(!parsed.diagnostics.contains(where: { $0.kind == .malformedHeaderLine }))
    }

    @Test
    func preservesARawHeaderLineOnRoundTrip() {
        let source = "---\ntitle: Toast\nstray line\n---"

        #expect(SousParser().parseRecipe(source).value.serialized() == source)
    }
}
