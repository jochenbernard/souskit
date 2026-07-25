import SousCore
import Testing

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
        let parsed = SousParser().parseRecipe(" ---\ntitle: Toast\n---")

        #expect(parsed.value.metadata.entries.isEmpty)
        #expect(parsed.value.steps.count == 1)
    }

    @Test(arguments: [
        "\n---\ntitle: Toast\n---",
        "\n\n---\ntitle: Toast\n---",
        "   \n\t\n---\ntitle: Toast\n---"
    ])
    func readsAHeaderBlankLinesStandBefore(source: String) {
        let parsed = SousParser().parseRecipe(source)

        #expect(parsed.value.metadata.title == "Toast")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func ignoresALeadingByteOrderMark() {
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

    @Test
    func splitsOnlyAtTheFirstSeparator() {
        #expect(Recipe.read("---\ntitle: a: b\n---").metadata.title == "a: b")
    }

    @Test
    func splitsAtTheFirstColonFollowedByWhitespaceRatherThanTheFirstColon() {
        let parsed = SousParser().parseRecipe("---\na:b: c\n---")

        #expect(parsed.value.metadata.entries.map(\.key) == ["a:b"])
        #expect(parsed.value.metadata["a:b"] == "c")
    }

    @Test
    func doesNotSplitAtAColonThatIsNotFollowedByWhitespace() {
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

    @Test(arguments: ["title:  Toast", "title:\tToast", "title: \t Toast"])
    func removesTheWhitespaceSeparatingAValueFromItsKey(entry: String) {
        #expect(Recipe.read("---\n\(entry)\n---").metadata.title == "Toast")
    }

    @Test(arguments: ["title : Toast", "title\t: Toast", "title  :  Toast"])
    func trimsTheWhitespaceAroundAKey(entry: String) {
        let parsed = SousParser().parseRecipe("---\n\(entry)\n---")

        #expect(parsed.value.metadata.entries.map(\.key) == ["title"])
        #expect(parsed.value.metadata.title == "Toast")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsALineThatOpensWithTheSeparatorAsAnEmptyKey() {
        let parsed = SousParser().parseRecipe("---\n: Alice\n---")

        #expect(parsed.value.metadata.entries.map(\.key) == [""])
        #expect(parsed.value.metadata[""] == "Alice")
        #expect(parsed.diagnostics.map(\.kind) == [.emptyHeaderKey])
    }

    @Test
    func warnsAboutAKeyThatIsNotLowercase() {
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
