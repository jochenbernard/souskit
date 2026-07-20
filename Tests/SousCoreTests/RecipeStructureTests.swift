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

        #expect(SousParser().parseRecipe(source).value.steps.count == 1)
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
    func doesNotTreatUnmarkedProseAsAnnotations() throws {
        let parsed = SousParser().parseRecipe("Add salt and pepper to taste.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.isEmpty)
        #expect(step.cookware.isEmpty)
    }

    @Test
    func keepsIngredientsInDocumentOrder() throws {
        let parsed = SousParser().parseRecipe("Fry @garlic@, add @baby spinach@, then @chili flakes@.")

        let step = try #require(parsed.value.steps.first)
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
}
