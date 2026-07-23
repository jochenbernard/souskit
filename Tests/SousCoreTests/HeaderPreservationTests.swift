import SousCore
import Testing

@Suite("Header preservation")
struct HeaderPreservationTests {
    private static let strayLineHeader = "---\ntitle: Toast\nstray line\n---"

    @Test
    func preservesAHeaderLineWithNoSeparatorAsARawEntry() {
        let metadata = SousParser().parseRecipe(Self.strayLineHeader).value.metadata
        #expect(metadata.title == "Toast")
        #expect(metadata.entries.contains(where: { $0.value == .raw("stray line") }))
    }

    @Test
    func preservesABlockListItemLineAsARawEntry() {
        let entries = Metadata.read("tags:\n  - italian").entries
        #expect(entries.contains(where: { $0.value == .raw("  - italian") }))
    }

    @Test
    func preservesANestedBlockLineAsARawEntryRatherThanAnIndentedKey() {
        let entries = Metadata.read("nutrition:\n  calories: 640 kcal").entries
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
        #expect(SousParser().parseRecipe(Self.strayLineHeader).value.serialized() == Self.strayLineHeader)
    }
}
