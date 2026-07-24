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
        let step = try #require(Recipe.read("#large pot# of salted water.").firstStep)
        #expect(step.cookware.map(\.name) == ["large pot"])
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
        "Use a #pan to fry the eggs.",
        "Cook @{200 g pasta@ now."
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
        // The first sigil opens a span its own paragraph never closes, so it is warned about.
        // The second is followed by a space, so it never opens one and has nothing to report.
        #expect(parsed.diagnostics.map(\.kind) == [.unclosedSpan])
    }

    @Test
    func doesNotTreatALineBeginningWithADoubleHashAsCookware() throws {
        // A line-initial "## " opens a group heading, which is a line-level construct rather
        // than an inline annotation, so no cookware is read from it.
        let parsed = SousParser().parseRecipe("## Sauce\nBrown the beef.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.cookware.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
        #expect(parsed.value.serialized() == "## Sauce\nBrown the beef.")
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

    // Forward compatibility: a construct a later version introduces is not understood here, so
    // it stays ordinary text and survives unchanged. Nothing this version leaves unread carries
    // a sigil of its own, so what remains is the block header form a later version adds.
    @Test(arguments: [
        "---\nnutrition:\n  calories: 3840 kcal\n---",
        "---\ntags:\n  - italian\n---"
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

    // A line-initial markdown form carries a space, so the opener rule already leaves it as
    // ordinary text. It is reserved for possible rich text after 1.0.
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
    func closesASpanOnALaterLineOfTheSameParagraph() throws {
        let parsed = SousParser().parseRecipe("Add @baby\nspinach@ to the pan.")

        let ingredient = try #require(parsed.value.firstIngredient)
        #expect(ingredient.name == "baby\nspinach")
    }

    @Test
    func doesNotCloseASpanAcrossAParagraphBreak() {
        let source = """
        Add @garlic

        spinach@ to the pan.
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.steps.count == 2)
        #expect(parsed.value.ingredients.isEmpty)
        #expect(parsed.diagnostics.contains(where: { $0.kind == .unclosedSpan }))
    }

    @Test
    func doesNotCloseAnAmountFenceAcrossAParagraphBreak() {
        // The brace a fence closes on is looked for in the span's own paragraph, so a "}"
        // in a later paragraph leaves the fence unclosed.
        let source = """
        Add @{200 g

        pasta} water@.
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.value.ingredients.isEmpty)
        #expect(parsed.value.steps.map(\.text) == ["Add @{200 g", "pasta} water@."])
        #expect(parsed.diagnostics.allSatisfy({ $0.kind == .unclosedSpan }))
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
    func unescapesAnEscapedClosingSigilInsideAnIngredientName() throws {
        let parsed = SousParser().parseRecipe("Add @a\\@b@ now.")

        let ingredient = try #require(parsed.value.firstIngredient)
        #expect(ingredient.name == "a@b")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func unescapesAnEscapedClosingSigilInsideACookwareName() throws {
        let parsed = SousParser().parseRecipe("Use a #8\\# pan#.")

        let cookware = try #require(parsed.value.firstCookware)
        #expect(cookware.name == "8# pan")
        #expect(parsed.diagnostics.isEmpty)
    }

    // A backslash produces the literal character for each character this version gives a
    // meaning to, and for nothing else.
    @Test(arguments: [
        (source: "Use \\@ here.", prose: "Use @ here."),
        (source: "Use \\# here.", prose: "Use # here."),
        (source: "Use \\~ here.", prose: "Use ~ here."),
        (source: "Use \\{ here.", prose: "Use { here."),
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

    // A reader resolves an escape only for the characters it gives a meaning to. This version
    // reads the reference sigil, so it resolves the escape before one, and the writer puts that
    // escape back wherever the sigil would otherwise open a span.

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
        "Layer the \\>{300 g} bolognese\\> in a dish.",
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
        // A sigil no non-whitespace character follows opens no span, so it needs no escape,
        // and a writer may drop one the text does not need.
        let written = Recipe.read("Spread the \\>sauce\\> on top.").serialized()

        #expect(written == "Spread the \\>sauce> on top.")
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
