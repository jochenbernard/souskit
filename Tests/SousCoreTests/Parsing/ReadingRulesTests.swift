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
        let step = try #require(Recipe.read("#stockpot# of salted water.").firstStep)
        #expect(step.cookware.map(\.name) == ["stockpot"])
    }

    @Test(arguments: [
        "Add a \\@ symbol here.",
        "Use a \\# symbol here.",
        "Write a \\{ brace here.",
        "Wait \\~40 min and check.",
        "Reduce by \\>half."
    ])
    func doesNotOpenASpanForAnEscapedSigil(source: String) throws {
        let parsed = SousParser().parseRecipe(source)

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.isEmpty)
        #expect(step.cookware.isEmpty)
        #expect(step.timers.isEmpty)
        #expect(step.references.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func doesNotOpenATimerWhenTheSigilIsFollowedByWhitespace() throws {
        let parsed = SousParser().parseRecipe("Bake ~ 40 min~ until done.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.timers.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test(arguments: [
        "Simmer ~40 min gently.",
        "Fry @garlic until fragrant.",
        "Use a #casserole to brown the beef.",
        "Sift @{200 g flour@ now."
    ])
    func recoversFromAnUnclosedSpan(source: String) throws {
        let parsed = SousParser().parseRecipe(source)

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.isEmpty)
        #expect(step.cookware.isEmpty)
        #expect(step.timers.isEmpty)
        let diagnostic = try #require(parsed.diagnostics.first(where: { $0.kind == .unclosedSpan }))
        #expect(diagnostic.severity == .warning)
    }

    @Test
    func doesNotCloseATimerAcrossAParagraphBreak() {
        let source = """
        Simmer ~40

        min~ gently.
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.timers.isEmpty)
        #expect(parsed.diagnostics.map(\.kind) == [.unclosedSpan])
    }

    @Test
    func doesNotTreatALineBeginningWithADoubleHashAsCookware() throws {
        let parsed = SousParser().parseRecipe("## Filling\nBrown the beef.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.cookware.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
        #expect(parsed.value.serialized() == "## Filling\nBrown the beef.")
    }

    @Test
    func doesNotProduceAnAnnotationWithAnEmptyName() throws {
        let parsed = SousParser().parseRecipe("Use ## here, @@ there, and ~~ throughout.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.cookware.isEmpty)
        #expect(step.ingredients.isEmpty)
        #expect(step.timers.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test(arguments: [
        "---\nnutrition:\n  calories: 3300 kcal\n---",
        "---\ntags:\n  - french\n---"
    ])
    func preservesConstructsFromLaterVersions(source: String) {
        #expect(Recipe.read(source).serialized() == source)
    }

    @Test
    func treatsReservedMarkdownCharactersAsOrdinaryText() throws {
        let parsed = SousParser().parseRecipe("Use *bold*, _italic_, `code`, and [brackets] plainly.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.isEmpty)
        #expect(step.cookware.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test(arguments: ["- Chop the onion.", "> Chop the onion."])
    func treatsAReservedLineInitialMarkdownFormAsOrdinaryText(source: String) throws {
        let parsed = SousParser().parseRecipe(source)

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.isEmpty)
        #expect(step.cookware.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
        #expect(parsed.value.serialized() == source)
    }

    @Test
    func doesNotCloseASpanAcrossALineBreak() {
        let parsed = SousParser().parseRecipe("Add @pearl\nonions@ to the casserole.")

        #expect(parsed.value.ingredients.isEmpty)
        #expect(parsed.value.steps.map(\.text) == ["Add @pearl\nonions@ to the casserole."])
        #expect(parsed.diagnostics.map(\.kind) == [.unclosedSpan])
    }

    @Test
    func doesNotCloseAnAmountFenceAcrossALineBreak() {
        let parsed = SousParser().parseRecipe("Add @{200 g\nflour} butter@.")

        #expect(parsed.value.ingredients.isEmpty)
        #expect(parsed.value.steps.map(\.text) == ["Add @{200 g\nflour} butter@."])
        #expect(parsed.diagnostics.map(\.kind) == [.unclosedSpan, .unclosedSpan])
    }

    @Test
    func doesNotCloseASpanAcrossAParagraphBreak() {
        let source = """
        Add @garlic

        shallots@ to the casserole.
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.steps.map(\.text) == ["Add @garlic", "shallots@ to the casserole."])
        #expect(parsed.value.ingredients.isEmpty)
        #expect(parsed.diagnostics.map(\.kind) == [.unclosedSpan])
    }

    @Test
    func doesNotCloseAnAmountFenceAcrossAParagraphBreak() {
        let source = """
        Add @{200 g

        flour} butter@.
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.ingredients.isEmpty)
        #expect(parsed.value.steps.map(\.text) == ["Add @{200 g", "flour} butter@."])
        #expect(parsed.diagnostics.map(\.kind) == [.unclosedSpan, .unclosedSpan])
    }

    @Test
    func recoversFromAnUnclosedAmountFenceWithNoClosingSigil() throws {
        let parsed = SousParser().parseRecipe("Sift @{200 g flour")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.isEmpty)
        #expect(step.text == "Sift @{200 g flour")
        #expect(parsed.diagnostics.contains(where: { $0.kind == .unclosedSpan }))
    }

    @Test
    func unescapesAnEscapedClosingSigilInsideAnIngredientName() throws {
        let parsed = SousParser().parseRecipe("Add @a\\@b@ now.")

        let ingredient = try #require(parsed.value.firstIngredient)
        #expect(ingredient.name == "a@b")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func unescapesAnEscapedClosingSigilInsideACookwareName() throws {
        let parsed = SousParser().parseRecipe("Use a #8\\# tin#.")

        let cookware = try #require(parsed.value.firstCookware)
        #expect(cookware.name == "8# tin")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test(arguments: [
        (source: "Use \\@ here.", prose: "Use @ here."),
        (source: "Use \\# here.", prose: "Use # here."),
        (source: "Use \\~ here.", prose: "Use ~ here."),
        (source: "Use \\{ here.", prose: "Use { here."),
        (source: "Use \\} here.", prose: "Use } here."),
        (source: "Use \\: here.", prose: "Use : here."),
        (source: "Use \\? here.", prose: "Use ? here."),
        (source: "Use \\> here.", prose: "Use > here."),
        (source: "Use \\\\ here.", prose: "Use \\ here.")
    ])
    func unescapesAnEscapedCharacterInProse(source: String, prose: String) throws {
        let parsed = SousParser().parseRecipe(source)

        let step = try #require(parsed.value.steps.first)
        #expect(step.segments.first?.proseText == prose)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func resolvesAnEscapedReferenceSigilInProse() throws {
        let parsed = SousParser().parseRecipe("Reduce by \\>half.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.segments.first?.proseText == "Reduce by >half.")
        #expect(step.references.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test(arguments: [
        "Heat to \\>200C, then cool to \\>50C before adding @salt@.",
        "Layer the \\>{300 g} bechamel\\> in a dish.",
        "Reduce by \\>half."
    ])
    func writesAProseReferenceSigilBackEscaped(source: String) {
        let recipe = Recipe.read(source)
        let written = recipe.serialized()
        let reRead = SousParser().parseRecipe(written)

        #expect(reRead.value.steps.map(\.segments) == recipe.steps.map(\.segments))
        #expect(reRead.diagnostics.isEmpty)
    }

    @Test
    func dropsAnEscapeTheProseDoesNotNeed() {
        let written = Recipe.read("Spread the \\>bechamel\\> on top.").serialized()

        #expect(written == "Spread the \\>bechamel> on top.")
    }

    @Test
    func unescapesAnEscapedLeadingBraceInAnIngredientName() throws {
        let parsed = SousParser().parseRecipe("Add @\\{note}@ now.")

        let ingredient = try #require(parsed.value.firstIngredient)
        #expect(ingredient.name == "{note}")
        #expect(ingredient.amount == nil)
        #expect(parsed.diagnostics.isEmpty)
    }
}
