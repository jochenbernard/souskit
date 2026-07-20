import SousCore
import Testing

@Suite("Reading rules and escaping")
struct ReadingRulesTests {
    @Test
    func doesNotOpenASpanWhenTheSigilIsFollowedByWhitespace() throws {
        let parsed = SousParser().parseRecipe("Bake @ 180C until done.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func doesNotTreatALineBeginningWithHashSpaceAsCookware() throws {
        let parsed = SousParser().parseRecipe("# not cookware")

        let step = try #require(parsed.value.steps.first)
        #expect(step.cookware.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func opensACookwareSpanAtTheStartOfALine() throws {
        let parsed = SousParser().parseRecipe("#large pot# of salted water.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.cookware.map(\.name) == ["large pot"])
    }

    @Test(arguments: ["Add a \\@ symbol here.", "Use a \\# symbol here.", "Write a \\{ brace here."])
    func doesNotOpenASpanForAnEscapedSigil(source: String) throws {
        let parsed = SousParser().parseRecipe(source)

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.isEmpty)
        #expect(step.cookware.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func recoversFromAnUnclosedIngredientSpan() throws {
        let parsed = SousParser().parseRecipe("Fry @garlic until fragrant.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.isEmpty)
        #expect(parsed.diagnostics.contains(where: { $0.kind == .unclosedSpan }))
    }

    @Test
    func recoversFromAnUnclosedCookwareSpan() throws {
        let parsed = SousParser().parseRecipe("Use a #pan to fry the eggs.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.cookware.isEmpty)
        #expect(parsed.diagnostics.contains(where: { $0.kind == .unclosedSpan }))
    }

    @Test
    func recoversFromAnUnclosedAmountFence() throws {
        let parsed = SousParser().parseRecipe("Cook @{200 g pasta@ now.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.isEmpty)
        #expect(parsed.diagnostics.contains(where: { $0.kind == .unclosedSpan }))
    }

    @Test
    func reportsAnUnclosedSpanAsAWarning() throws {
        let parsed = SousParser().parseRecipe("Fry @garlic until fragrant.")

        let diagnostic = try #require(parsed.diagnostics.first(where: { $0.kind == .unclosedSpan }))
        #expect(diagnostic.severity == .warning)
    }
}
