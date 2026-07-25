import SousCore
import Testing

@Suite("Recipe file structure")
struct RecipeStructureTests {
    @Test
    func parsesASingleLineOfProseAsOneStep() throws {
        let parsed = SousParser().parseRecipe("Toast the bread and spread it with butter.")

        #expect(parsed.value.steps.count == 1)
        let step = try #require(parsed.value.steps.first)
        #expect(step.text == "Toast the bread and spread it with butter.")
        #expect(step.ingredients.isEmpty)
        #expect(step.cookware.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func aProseOnlyFileHasNoMetadata() {
        let parsed = SousParser().parseRecipe("Toast the bread.")

        #expect(parsed.value.metadata.title == nil)
        #expect(parsed.value.metadata.servings == nil)
        #expect(parsed.value.metadata.tags.isEmpty)
        #expect(parsed.value.metadata.entries.isEmpty)
    }

    @Test
    func parsesATitleOnlyHeaderWithNoBody() {
        let source = """
        ---
        title: Buttered Toast
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.metadata.title == "Buttered Toast")
        #expect(parsed.value.steps.isEmpty)
    }

    @Test
    func separatesParagraphsIntoSteps() {
        let source = """
        Toast the bread.

        Spread with butter.
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.steps.count == 2)
        #expect(parsed.value.steps.first?.text == "Toast the bread.")
        #expect(parsed.value.steps.last?.text == "Spread with butter.")
    }

    @Test
    func treatsConsecutiveNonBlankLinesAsOneStep() {
        let source = """
        Toast the bread
        and spread it with butter.
        """

        #expect(Recipe.read(source).steps.count == 1)
    }

    @Test
    func normalizesWindowsLineEndings() throws {
        let source = "---\r\ntitle: Buttered Toast\r\n---\r\n\r\nWarm a #pan#."

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.metadata.title == "Buttered Toast")
        let step = try #require(parsed.value.steps.first)
        #expect(step.text == "Warm a #pan#.")
        #expect(step.cookware.map(\.name) == ["pan"])
    }

    @Test
    func normalizesLineEndingsWithinAMultiLineStep() throws {
        let step = try #require(Recipe.read("Add @baby\r\nspinach@ to the pan.").firstStep)
        #expect(step.text == "Add @baby\nspinach@ to the pan.")
    }

    @Test
    func doesNotTreatUnmarkedProseAsAnnotations() throws {
        let step = try #require(Recipe.read("Add salt and pepper to taste.").firstStep)
        #expect(step.ingredients.isEmpty)
        #expect(step.cookware.isEmpty)
    }

    @Test
    func keepsIngredientsInDocumentOrder() throws {
        let step = try #require(Recipe.read("Fry @garlic@, add @baby spinach@, then @chili flakes@.").firstStep)
        #expect(step.ingredients.map(\.name) == ["garlic", "baby spinach", "chili flakes"])
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
        let parsed = SousParser().parseRecipe("Toast the bread.\n   \nSpread with butter.")

        #expect(parsed.value.steps.map(\.text) == ["Toast the bread.", "Spread with butter."])
    }

    @Test
    func keepsTheWhitespaceAroundAStepVerbatim() {
        let parsed = SousParser().parseRecipe("  Toast the bread.  ")

        #expect(parsed.value.steps.map(\.text) == ["  Toast the bread.  "])
    }

    @Test
    func normalizesEveryKindOfLineBreakWithinAStep() {
        // A line separator and a vertical tab are line breaks too, so a step carries them
        // as line feeds, exactly as it does a Windows line ending.
        let parsed = SousParser().parseRecipe("Toast the bread\u{2028}and butter it\u{0B}while warm.")

        #expect(parsed.value.steps.map(\.text) == ["Toast the bread\nand butter it\nwhile warm."])
    }

    @Test
    func normalizesALoneCarriageReturn() {
        // The line ending an older editor writes is a line break like any other, so a step
        // carries it as a line feed and a blank line built from one still separates steps.
        let parsed = SousParser().parseRecipe("Toast the bread.\rSpread it.\r\rServe warm.")

        #expect(parsed.value.steps.map(\.text) == ["Toast the bread.\nSpread it.", "Serve warm."])
    }
}
