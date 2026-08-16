import SousCore
import Testing

@Suite("Recipe file structure")
struct RecipeStructureTests {
    @Test
    func parsesASingleLineOfProseAsOneStep() throws {
        let parsed = SousParser().parseRecipe("Whisk the vinegar and beat in the oil.")

        #expect(parsed.value.steps.count == 1)
        let step = try #require(parsed.value.steps.first)
        #expect(step.text == "Whisk the vinegar and beat in the oil.")
        #expect(step.ingredients.isEmpty)
        #expect(step.cookware.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func aProseOnlyFileHasNoMetadata() {
        let parsed = SousParser().parseRecipe("Whisk the vinegar.")

        #expect(parsed.value.metadata.title == nil)
        #expect(parsed.value.metadata.servings == nil)
        #expect(parsed.value.metadata.tags.isEmpty)
        #expect(parsed.value.metadata.entries.isEmpty)
    }

    @Test
    func parsesATitleOnlyHeaderWithNoBody() {
        let source = """
        ---
        title: Vinaigrette
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.metadata.title == "Vinaigrette")
        #expect(parsed.value.steps.isEmpty)
    }

    @Test
    func separatesParagraphsIntoSteps() {
        let source = """
        Whisk the vinegar.

        Beat in the oil.
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.steps.count == 2)
        #expect(parsed.value.steps.first?.text == "Whisk the vinegar.")
        #expect(parsed.value.steps.last?.text == "Beat in the oil.")
    }

    @Test
    func treatsConsecutiveNonBlankLinesAsOneStep() {
        let source = """
        Whisk the vinegar
        and beat in the oil.
        """

        #expect(Recipe.read(source).steps.count == 1)
    }

    @Test
    func normalizesWindowsLineEndings() throws {
        let source = "---\r\ntitle: Vinaigrette\r\n---\r\n\r\nWarm a #casserole#."

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.metadata.title == "Vinaigrette")
        let step = try #require(parsed.value.steps.first)
        #expect(step.text == "Warm a #casserole#.")
        #expect(step.cookware.map(\.name) == ["casserole"])
    }

    @Test
    func normalizesLineEndingsWithinAMultiLineStep() throws {
        let step = try #require(Recipe.read("Add @pearl\r\nonions@ to the casserole.").firstStep)
        #expect(step.text == "Add @pearl\nonions@ to the casserole.")
    }

    @Test
    func doesNotTreatUnmarkedProseAsAnnotations() throws {
        let step = try #require(Recipe.read("Add salt and pepper to taste.").firstStep)
        #expect(step.ingredients.isEmpty)
        #expect(step.cookware.isEmpty)
    }

    @Test
    func keepsIngredientsInDocumentOrder() throws {
        let step = try #require(Recipe.read("Fry @garlic@, add @pearl onions@, then @thyme@.").firstStep)
        #expect(step.ingredients.map(\.name) == ["garlic", "pearl onions", "thyme"])
    }

    @Test
    func representsAStepAsOrderedProseAndAnnotationSegments() throws {
        let parsed = SousParser().parseRecipe("Fry @garlic@ until fragrant.")

        let segments = try #require(parsed.value.steps.first?.segments)
        #expect(segments.count == 3)
        #expect(segments.first?.proseText == "Fry ")
        #expect(segments.dropFirst().first?.ingredientValue?.name == "garlic")
        #expect(segments.last?.proseText == " until fragrant.")
    }

    @Test(arguments: ["", "   ", "\n\n"])
    func readsAFileWithNoContentAsAnEmptyRecipe(source: String) {
        let parsed = SousParser().parseRecipe(source)

        #expect(parsed.value.steps.isEmpty)
        #expect(parsed.value.metadata.entries.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
        #expect(parsed.value.serialized().isEmpty)
    }

    @Test
    func separatesStepsOnALineOfOnlyWhitespace() {
        let parsed = SousParser().parseRecipe("Whisk the vinegar.\n   \nBeat in the oil.")

        #expect(parsed.value.steps.map(\.text) == ["Whisk the vinegar.", "Beat in the oil."])
    }

    @Test
    func keepsTheWhitespaceAroundAStepVerbatim() {
        let parsed = SousParser().parseRecipe("  Whisk the vinegar.  ")

        #expect(parsed.value.steps.map(\.text) == ["  Whisk the vinegar.  "])
    }

    @Test
    func normalizesEveryKindOfLineBreakWithinAStep() {
        let parsed = SousParser().parseRecipe("Whisk the vinegar\u{2028}and beat in the oil\u{0B}while it thickens.")

        #expect(parsed.value.steps.map(\.text) == ["Whisk the vinegar\nand beat in the oil\nwhile it thickens."])
    }

    @Test
    func normalizesALoneCarriageReturn() {
        let parsed = SousParser().parseRecipe("Whisk the vinegar.\rBeat in the oil.\r\rDress the salad.")

        #expect(parsed.value.steps.map(\.text) == ["Whisk the vinegar.\nBeat in the oil.", "Dress the salad."])
    }
}
