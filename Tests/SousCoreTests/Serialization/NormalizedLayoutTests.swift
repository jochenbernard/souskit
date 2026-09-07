import SousCore
import Testing

@Suite("Layout normalization")
struct NormalizedLayoutTests {
    /// Nine characters, so twelve of these and the spaces between them fill 119 columns.
    private static let word = String(repeating: "a", count: 9)

    /// Twelve of ``word``, the most that fit one line.
    private static let line = Array(repeating: word, count: 12).joined(separator: " ")

    @Test(arguments: [
        (source: "Whisk the vinegar\nand beat in the oil.", written: "Whisk the vinegar and beat in the oil."),
        (source: "Add @pearl\nonions@ now.", written: "Add @pearl onions@ now."),
        (source: "## Pastry\nRub in\nthe butter.", written: "## Pastry\nRub in the butter.")
    ])
    func writesAStepThatFitsTheLineLimitOnOneLine(source: String, written: String) {
        #expect(Recipe.read(source).serialized() == written)
    }

    @Test
    func wrapsAStepAtTheLastSpaceWithinTheLineLimit() {
        let words = Array(repeating: Self.word, count: 15)

        #expect(Recipe.read(words.joined(separator: " ")).serialized()
            == "\(Self.line)\n\(words.suffix(3).joined(separator: " "))")
    }

    @Test
    func leavesAStepOfExactlyTheLineLimitOnOneLine() {
        let source = "\(String(repeating: "a", count: 118)) b"

        #expect(source.count == 120)
        #expect(Recipe.read(source).serialized() == source)
    }

    @Test
    func wrapsAStepOneCharacterPastTheLineLimit() {
        let filled = String(repeating: "a", count: 119)

        #expect(Recipe.read("\(filled) b").serialized() == "\(filled)\nb")
    }

    @Test
    func overrunsTheLineLimitForAWordNoSpaceBreaksUp() {
        let overlong = String(repeating: "a", count: 200)

        #expect(Recipe.read(overlong).serialized() == overlong)
        #expect(Recipe.read("\(overlong) b").serialized() == "\(overlong)\nb")
    }

    @Test
    func breaksAtNoSpaceThatWouldLeaveALineOfOnlyWhitespace() {
        let source = "a\(String(repeating: " ", count: 200))"

        #expect(Recipe.read(source).serialized() == source)
    }

    @Test
    func breaksAtNoWhitespaceOtherThanASpace() {
        let source = Array(repeating: Self.word, count: 15).joined(separator: "\t")

        #expect(Recipe.read(source).serialized() == source)
    }

    @Test
    func readsAWrappedLineOpeningWithAHeadingMarkerAsTheSameStep() {
        let written = Recipe.read("\(Self.line) ## x").serialized()

        #expect(written == "\(Self.line)\n## x")
        #expect(Recipe.read(written).groups.map(\.name) == [nil])
        #expect(Recipe.read(written).steps.map(\.text) == ["\(Self.line) ## x"])
    }

    @Test
    func writesAnEmptyHeaderWhenAWrapLeavesTheBodyOpeningWithAFenceLine() {
        let overlong = String(repeating: "a", count: 200)
        let written = Recipe.read("--- \(overlong)").serialized()

        #expect(written == "---\n---\n\n---\n\(overlong)")
        #expect(Recipe.read(written).steps.map(\.text) == ["--- \(overlong)"])
    }

    @Test
    func keepsEveryWrittenLineWithinTheLineLimit() {
        let source = Array(repeating: "Stir in @{2 g} salt@ well", count: 12).joined(separator: ", ")
        let recipe = Recipe.read(source)

        #expect(recipe.serialized().split(separator: "\n").allSatisfy({ $0.count <= 120 }))
        #expect(recipe.reRead() == recipe)
    }

    @Test(arguments: NormalizedLayouts.sources)
    func normalizingLayoutIsStable(source: String) {
        let parser = SousParser()
        let normalized = parser.parseRecipe(source).value.serialized()

        #expect(parser.parseRecipe(normalized).value.serialized() == normalized)
    }

    @Test(arguments: NormalizedLayouts.sources)
    func normalizingLayoutKeepsTheContent(source: String) {
        let recipe = Recipe.read(source)
        let reRead = recipe.reRead()

        #expect(reRead.steps.map(\.segments) == recipe.steps.map(\.segments))
        #expect(reRead.metadata == recipe.metadata)
    }
}
