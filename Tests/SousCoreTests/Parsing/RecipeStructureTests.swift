import SousCore
import Testing

@Suite("Recipe file structure")
struct RecipeStructureTests {
    @Test
    func parsesASingleLineOfProseAsOneStep() throws {
        let parsed = SousParser().parseRecipe("Toast the baguette and spread it with butter.")

        #expect(parsed.value.steps.count == 1)
        let step = try #require(parsed.value.steps.first)
        #expect(step.text == "Toast the baguette and spread it with butter.")
        #expect(step.ingredients.isEmpty)
        #expect(step.cookware.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func aProseOnlyFileHasNoMetadata() {
        let parsed = SousParser().parseRecipe("Toast the baguette.")

        #expect(parsed.value.metadata.title == nil)
        #expect(parsed.value.metadata.servings == nil)
        #expect(parsed.value.metadata.tags.isEmpty)
        #expect(parsed.value.metadata.entries.isEmpty)
    }

    @Test
    func parsesATitleOnlyHeaderWithNoBody() {
        let source = """
        ---
        title: Tartine Beurree
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.metadata.title == "Tartine Beurree")
        #expect(parsed.value.steps.isEmpty)
    }

    @Test
    func separatesParagraphsIntoSteps() {
        let source = """
        Toast the baguette.

        Spread with butter.
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.steps.count == 2)
        #expect(parsed.value.steps.first?.text == "Toast the baguette.")
        #expect(parsed.value.steps.last?.text == "Spread with butter.")
    }

    @Test
    func treatsConsecutiveNonBlankLinesAsOneStep() {
        let source = """
        Toast the baguette
        and spread it with butter.
        """

        #expect(Recipe.read(source).steps.count == 1)
    }

    @Test
    func normalizesWindowsLineEndings() throws {
        let source = "---\r\ntitle: Tartine Beurree\r\n---\r\n\r\nWarm a #pan#."

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.metadata.title == "Tartine Beurree")
        let step = try #require(parsed.value.steps.first)
        #expect(step.text == "Warm a #pan#.")
        #expect(step.cookware.map(\.name) == ["pan"])
    }

    @Test
    func normalizesLineEndingsWithinAMultiLineStep() throws {
        let step = try #require(Recipe.read("Add @pearl\r\nonions@ to the pan.").firstStep)
        #expect(step.text == "Add @pearl\nonions@ to the pan.")
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
        let parsed = SousParser().parseRecipe("Toast the baguette.\n   \nSpread with butter.")

        #expect(parsed.value.steps.map(\.text) == ["Toast the baguette.", "Spread with butter."])
    }

    @Test
    func keepsTheWhitespaceAroundAStepVerbatim() {
        let parsed = SousParser().parseRecipe("  Toast the baguette.  ")

        #expect(parsed.value.steps.map(\.text) == ["  Toast the baguette.  "])
    }

    @Test
    func normalizesEveryKindOfLineBreakWithinAStep() {
        let parsed = SousParser().parseRecipe("Toast the baguette\u{2028}and butter it\u{0B}while warm.")

        #expect(parsed.value.steps.map(\.text) == ["Toast the baguette\nand butter it\nwhile warm."])
    }

    @Test
    func normalizesALoneCarriageReturn() {
        let parsed = SousParser().parseRecipe("Toast the baguette.\rSpread it.\r\rServe warm.")

        #expect(parsed.value.steps.map(\.text) == ["Toast the baguette.\nSpread it.", "Serve warm."])
    }
}
