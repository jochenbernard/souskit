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
    func doesNotTreatALineBeginningWithADoubleHashAsCookware() throws {
        // "## Name" is a v0.4 group heading, so a v0.1 reader leaves it as ordinary text.
        let parsed = SousParser().parseRecipe("## Sauce\nBrown the beef.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.cookware.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
        #expect(parsed.value.serialized() == "## Sauce\nBrown the beef.")
    }

    @Test
    func doesNotProduceAnAnnotationWithAnEmptyName() throws {
        let parsed = SousParser().parseRecipe("Use ## here and @@ there.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.cookware.isEmpty)
        #expect(step.ingredients.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    // Forward compatibility: constructs from later versions are not understood by a v0.1
    // reader, so they stay ordinary text and survive unchanged.
    @Test(arguments: [
        "Simmer ~40 min~ gently.",
        "Spread the >sauce> on top.",
        "Season with @salt@:staple and stir in @{=1 tsp} soda@."
    ])
    func preservesConstructsFromLaterVersions(source: String) {
        #expect(SousParser().parseRecipe(source).value.serialized() == source)
    }

    @Test
    func treatsReservedMarkdownCharactersAsOrdinaryText() throws {
        let parsed = SousParser().parseRecipe("Use *bold*, _italic_, `code`, and [brackets] plainly.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.isEmpty)
        #expect(step.cookware.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func closesASpanOnALaterLineOfTheSameParagraph() throws {
        let parsed = SousParser().parseRecipe("Add @baby\nspinach@ to the pan.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.name == "baby\nspinach")
    }

    @Test
    func doesNotCloseASpanAcrossAParagraphBreak() {
        let source = """
        Add @garlic

        spinach@ to the pan.
        """

        let parsed = SousParser().parseRecipe(source)
        let ingredients = parsed.value.steps.flatMap(\.ingredients)
        #expect(parsed.value.steps.count == 2)
        #expect(ingredients.isEmpty)
        #expect(parsed.diagnostics.contains(where: { $0.kind == .unclosedSpan }))
    }

    @Test
    func recoversFromAnUnclosedAmountFenceWithNoClosingSigil() throws {
        let parsed = SousParser().parseRecipe("Cook @{200 g pasta")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.isEmpty)
        #expect(step.text == "Cook @{200 g pasta")
        #expect(parsed.diagnostics.contains(where: { $0.kind == .unclosedSpan }))
    }

    @Test
    func reportsAnUnclosedSpanAsAWarning() throws {
        let parsed = SousParser().parseRecipe("Fry @garlic until fragrant.")

        let diagnostic = try #require(parsed.diagnostics.first(where: { $0.kind == .unclosedSpan }))
        #expect(diagnostic.severity == .warning)
    }

    @Test
    func unescapesAnEscapedClosingSigilInsideAnIngredientName() throws {
        let parsed = SousParser().parseRecipe("Add @a\\@b@ now.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.name == "a@b")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func unescapesAnEscapedClosingSigilInsideACookwareName() throws {
        let parsed = SousParser().parseRecipe("Use a #8\\# pan#.")

        let cookware = try #require(parsed.value.steps.first?.cookware.first)
        #expect(cookware.name == "8# pan")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func unescapesAnEscapedSigilInProse() throws {
        let parsed = SousParser().parseRecipe("Use \\@ here.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.segments.first?.proseText == "Use @ here.")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func unescapesAnEscapedLeadingBraceInAnIngredientName() throws {
        let parsed = SousParser().parseRecipe("Add @\\{note}@ now.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.name == "{note}")
        #expect(ingredient.amount == nil)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func roundTripsAnEscapedSigilInsideASpan() {
        let source = "Add @a\\@b@ now."

        #expect(SousParser().parseRecipe(source).value.serialized() == source)
    }
}
