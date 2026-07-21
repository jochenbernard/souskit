import SousCore
import Testing

// The header's shape: where its fences may sit, and how a line is split into a key and a
// value. What the values then mean is covered by the metadata suites.

@Suite("Header form")
struct HeaderFormTests {
    @Test
    func treatsAnIndentedOpeningFenceAsBodyText() {
        // The opening fence must be the file's first line, with nothing before it.
        let parsed = SousParser().parseRecipe(" ---\ntitle: Toast\n---")

        #expect(parsed.value.metadata.entries.isEmpty)
        #expect(parsed.value.steps.count == 1)
    }

    @Test
    func acceptsAFenceLineWithTrailingWhitespace() {
        let parsed = SousParser().parseRecipe("--- \ntitle: Toast\n--- \n\nToast the bread.")

        #expect(parsed.value.metadata.title == "Toast")
        #expect(parsed.value.steps.map(\.text) == ["Toast the bread."])
    }

    @Test
    func closesTheHeaderAtItsFirstClosingFence() {
        let source = "---\ntitle: First\n---\nBody.\n---\ntitle: Second\n---"

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.metadata.title == "First")
        #expect(parsed.value.steps.map(\.text) == ["Body.\n---\ntitle: Second\n---"])
    }

    @Test
    func readsALineThatOpensWithTheSeparatorAsAnEmptyKey() {
        let parsed = SousParser().parseRecipe("---\n: Alice\n---")

        #expect(parsed.value.metadata.entries.map(\.key) == [""])
        #expect(parsed.value.metadata[""] == "Alice")
        #expect(parsed.diagnostics.contains(where: { $0.kind == .unknownHeaderKey }))
    }

    @Test
    func splitsOnlyAtTheFirstSeparator() {
        #expect(SousParser().parseRecipe("---\ntitle: a: b\n---").value.metadata.title == "a: b")
    }

    @Test
    func removesExactlyOneSpaceAfterTheSeparator() {
        #expect(SousParser().parseRecipe("---\ntitle:  Toast\n---").value.metadata.title == " Toast")
    }

    @Test
    func warnsAboutAKeyThatIsNotLowercase() {
        // Keys are lowercase, so "Title" is a different key, and an unrecognized one.
        let parsed = SousParser().parseRecipe("---\nTitle: Toast\n---")

        #expect(parsed.value.metadata.title == nil)
        #expect(parsed.value.metadata["Title"] == "Toast")
        #expect(parsed.diagnostics.contains(where: { $0.kind == .unknownHeaderKey }))
    }

    @Test
    func preservesAKeyFromALaterVersion() {
        let parsed = SousParser().parseRecipe("---\nprep-time: 15 min\n---")

        #expect(parsed.value.metadata["prep-time"] == "15 min")
        #expect(parsed.diagnostics.contains(where: { $0.kind == .unknownHeaderKey }))
    }

    @Test(arguments: [
        "---\ntags: [ ]\n---",
        "---\ntags: [,]\n---",
        "---\ntags: [, ,]\n---"
    ])
    func readsAnInlineListOfNothingButSeparatorsAsNoItems(source: String) {
        #expect(SousParser().parseRecipe(source).value.metadata.tags.isEmpty)
    }
}
