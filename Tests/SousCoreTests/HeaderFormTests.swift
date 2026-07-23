import SousCore
import Testing

// The header's shape: whether a file has one at all, where its fences may sit, and how a
// line is split into a key and a value. What the values then mean is covered by the
// metadata suites.

@Suite("Header form")
struct HeaderFormTests {
    @Test
    func parsesAnEmptyHeader() {
        let source = """
        ---
        ---
        """

        let metadata = Recipe.read(source).metadata
        #expect(metadata.title == nil)
        #expect(metadata.entries.isEmpty)
    }

    @Test
    func treatsAFileWithoutALeadingFenceAsHavingNoHeader() {
        let source = """
        Toast the bread.
        ---
        title: X
        ---
        """

        #expect(Recipe.read(source).metadata.title == nil)
    }

    @Test
    func treatsAnIndentedOpeningFenceAsBodyText() {
        // The opening fence must be the file's first line, with nothing before it.
        let parsed = SousParser().parseRecipe(" ---\ntitle: Toast\n---")

        #expect(parsed.value.metadata.entries.isEmpty)
        #expect(parsed.value.steps.count == 1)
    }

    @Test
    func ignoresALeadingByteOrderMark() {
        // The mark is not content, so a header still counts as starting the file.
        let source = "\u{FEFF}---\ntitle: Buttered Toast\n---"

        #expect(Recipe.read(source).metadata.title == "Buttered Toast")
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
    func recoversFromAnUnterminatedHeader() {
        let source = """
        ---
        title: Buttered Toast
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.metadata.title == "Buttered Toast")
        #expect(parsed.diagnostics.contains(where: { $0.kind == .unterminatedHeader }))
    }

    // A key ends at the first colon followed by a space or the end of the line.

    @Test
    func splitsOnlyAtTheFirstSeparator() {
        #expect(Recipe.read("---\ntitle: a: b\n---").metadata.title == "a: b")
    }

    @Test
    func splitsAtTheFirstColonFollowedByASpaceRatherThanTheFirstColon() {
        // A colon with nothing after it is ordinary text, so the key runs on past it.
        let parsed = SousParser().parseRecipe("---\na:b: c\n---")

        #expect(parsed.value.metadata.entries.map(\.key) == ["a:b"])
        #expect(parsed.value.metadata["a:b"] == "c")
    }

    @Test
    func doesNotSplitAtAColonThatIsNotFollowedByASpace() {
        let source = """
        ---
        source: https://example.com/recipes/1
        ---
        """

        #expect(Recipe.read(source).metadata.source == "https://example.com/recipes/1")
    }

    @Test
    func readsAKeyEndingTheLineAsAnEmptyValue() throws {
        let source = """
        ---
        title:
        ---
        """

        let title = try #require(Recipe.read(source).metadata.title)
        #expect(title.isEmpty)
    }

    @Test
    func removesExactlyOneSpaceAfterTheSeparator() {
        #expect(Recipe.read("---\ntitle:  Toast\n---").metadata.title == " Toast")
    }

    @Test
    func readsALineThatOpensWithTheSeparatorAsAnEmptyKey() {
        let parsed = SousParser().parseRecipe("---\n: Alice\n---")

        #expect(parsed.value.metadata.entries.map(\.key) == [""])
        #expect(parsed.value.metadata[""] == "Alice")
        #expect(parsed.diagnostics.contains(where: { $0.kind == .unknownHeaderKey }))
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
}
