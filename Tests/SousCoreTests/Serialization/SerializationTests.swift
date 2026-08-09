import SousCore
import Testing

@Suite("Serialization round-trip")
struct SerializationTests {
    /// The recipe a source describes, alongside that recipe serialized and read back.
    private func roundTrip(_ source: String) -> (recipe: Recipe, reRead: Recipe) {
        let recipe = Recipe.read(source)

        return (recipe, recipe.reRead())
    }

    /// Expects a round trip to preserve the segments and the header, though not necessarily the
    /// source text byte for byte.
    private func expectTheRecipeSurvivesARoundTrip(
        _ source: String,
        sourceLocation: Testing.SourceLocation = #_sourceLocation
    ) {
        let (recipe, reRead) = roundTrip(source)

        #expect(reRead.steps.map(\.segments) == recipe.steps.map(\.segments), sourceLocation: sourceLocation)
        #expect(reRead.metadata == recipe.metadata, sourceLocation: sourceLocation)
    }

    @Test(arguments: [
        "Toast the baguette and spread it with butter.",
        "Fry @garlic@ until fragrant, then add @pearl onions@.",
        "Bring a #stockpot# of water to a boil and blanch @{200 g} potatoes@.",
        "Add @{1-2 tbsp} olive oil@ and @{a pinch} salt@.",
        """
        Toast the baguette.

        Spread with butter.
        """,
        """
        ---
        title: Sole Meuniere
        servings: 2
        ---

        Melt @{30 g} butter@ in a #frying pan#, fry @{2 cloves} garlic@.
        """,
        "Mix @salt@@thyme@ in.",
        "Simmer gently for ~40 min~, then rest ~overnight~.",
        "Bake ~8-10 min~ and rest ~1 h 30 min~.",
        "Chill ~over\\~night~ now.",
        "Wait \\~40 min here.",
        "Stir in @{=1 tsp} nutmeg@.",
        "Season with @salt@:staple and @black pepper@:staple.",
        "Scatter @thyme@? over the top.",
        "Scatter @thyme@?y over the top.",
        "Loosen with @{50 ml} water@:non-food if needed.",
        "Add @{=10 g} salt@:staple now.",
        "Add @water@:staple:non-food now.",
        "Add @salt@:staple?y here.",
        "Add @stock@:homemade now.",
        "Add @stock@:homemade?2 now.",
        "Is it @salt@\\? Yes.",
        "Serve @potatoes@\\:about 200 g each.",
        "Season with @salt@:staple\\?y.",
        "Add @stock@:homemade\\:more now.",
        "Season with @salt@: to taste.",
        "Use a #{200 g} frying pan#.",
        "Add @{} salt@.",
        "Season with salt @",
        "Season to taste \\",
        "## Filling\nBrown the beef.",
        "Layer the >{300 g} bechamel> in a dish.",
        "Read the \\note here.",
        "Note the path C:\\Users, then add @garlic@.",
        "Use a #8\\ pan#.",
        "Path C:\\\\@garlic@ now.",
        "Add @flour\\\\@ now.",
        "  Toast the baguette.  ",
        "---\n: Alice\n---",
        "---\ntitle: a: b\n---",
        "---\nprep-time: 15 min\n---",
        "---\ntitle:\n---",
        "---\nnutrition:\n  calories: 640 kcal\n---",
        "---\ntags: [comfort food\\, french]\n---",
        "---\ntags: [\\[sugar]\n---",
        "---\nsource: C:\\photos\\x\n---"
    ])
    func reproducesTheSourceExactly(source: String) {
        #expect(Recipe.read(source).serialized() == source)
    }

    @Test(arguments: [
        "Use @@ here.",
        "Use ## here.",
        "Use >> here.",
        "Rate it @@ out of five."
    ])
    func leavesAnInertSigilPairUnescaped(source: String) {
        #expect(Recipe.read(source).serialized() == source)
    }

    @Test(arguments: [
        "\\@\\@garlic\\@ here.",
        "\\#\\#pan\\# here.",
        "\\@\\@garlic\\@",
        "Mix \\@\\@a\\@ into @flour@.",
        "\\@\\@\\@a\\@"
    ])
    func keepsProseWithAnEscapedSigilPairOnRoundTrip(source: String) {
        let (recipe, reRead) = roundTrip(source)

        #expect(reRead.steps.map(\.segments) == recipe.steps.map(\.segments))
        #expect(reRead.ingredients == recipe.ingredients)
    }

    @Test(arguments: [
        (source: "Add @water@:non-food:staple now.", written: "Add @water@:staple:non-food now."),
        (source: "Add @salt@:optional now.", written: "Add @salt@? now."),
        (source: "Add @salt@:staple:staple now.", written: "Add @salt@:staple now."),
        (source: "Add @salt@?:staple now.", written: "Add @salt@:staple? now."),
        (source: "Add @stock@:homemade:staple now.", written: "Add @stock@:staple:homemade now.")
    ])
    func writesAFlagChainInItsCanonicalOrder(source: String, written: String) {
        #expect(Recipe.read(source).serialized() == written)
    }

    @Test
    func escapesASeparatorInAListItem() {
        let source = "---\ntags: comfort food, french\n---"

        #expect(Recipe.read(source).serialized() == "---\ntags: [comfort food\\, french]\n---")
    }

    @Test
    func escapesABracketInAListItem() {
        let source = "---\ntags: [french\n---"

        #expect(Recipe.read(source).serialized() == "---\ntags: [\\[french]\n---")
    }

    @Test(arguments: [
        "---\ntags: comfort food, french\n---",
        "---\ntags: [french\n---",
        "---\ntags: a]b\n---",
        "---\ntags: [a\\]\n---",
        "---\ntags: C:\\x\n---",
        "---\ntags: [a\\\\b, c]\n---",
        "---\ntags: [a, b] \n---"
    ])
    func keepsEveryListItemOnRoundTrip(source: String) {
        let (recipe, reRead) = roundTrip(source)

        #expect(reRead.metadata.tags == recipe.metadata.tags)
        #expect(reRead.metadata.entries == recipe.metadata.entries)
    }

    @Test
    func writesAnEmptyScalarValueWithoutATrailingSpace() {
        #expect(Recipe.read("---\ntitle:\n---").serialized() == "---\ntitle:\n---")
    }

    @Test
    func preservesAnUnrecognizedHeaderKeyOnRoundTrip() {
        let source = """
        ---
        title: Tartine
        chef: Alice
        ---
        """

        #expect(Recipe.read(source).serialized() == source)
    }

    @Test
    func preservesAnUnclosedSpanAsLiteralTextOnRoundTrip() {
        let (recipe, reRead) = roundTrip("Fry @garlic until fragrant.")

        #expect(reRead.steps.map(\.segments) == recipe.steps.map(\.segments))
        #expect(reRead.ingredients.isEmpty)
    }

    @Test(arguments: [
        "Add @\\{not a fence@ now.",
        "Use a #8\\# pan#.",
        "Add @a\\@b@ now.",
        "Email \\@user today.",
        "Weigh a \\#5 sieve here."
    ])
    func reEscapesParsedEscapesForByteExactRoundTrip(source: String) {
        #expect(Recipe.read(source).serialized() == source)
    }

    @Test
    func reEscapesAProseSigilAdjacentToAnAnnotation() {
        let source = "\\@@garlic@ now."

        #expect(Recipe.read(source).serialized() == source)
    }

    @Test(arguments: [
        "Add a \\@ symbol here.",
        "Write a \\{ brace here.",
        "All of them: \\@ \\# \\~ \\{ \\: \\? \\\\ done.",
        "Mix @{200 g} flour@ and \\@ the rest.",
        "Halve the \\\\ ratio.",
        "Add @a\\\\b@ now."
    ])
    func normalizesAnUnneededEscapeButPreservesTheRecipe(source: String) {
        expectTheRecipeSurvivesARoundTrip(source)
    }

    @Test(arguments: TestSupport.normalizedLayouts)
    func normalizingLayoutIsStable(source: String) {
        let parser = SousParser()
        let normalized = parser.parseRecipe(source).value.serialized()

        #expect(parser.parseRecipe(normalized).value.serialized() == normalized)
    }

    @Test(arguments: TestSupport.normalizedLayouts)
    func normalizingLayoutKeepsTheContent(source: String) {
        expectTheRecipeSurvivesARoundTrip(source)
    }

    @Test(arguments: [
        "---\n---\n\n---",
        "---\n---\n\n---\nBring the water to a boil.",
        "---\n---\n\n--- ",
        "---\n---\n\n---\n\nSpread with butter."
    ])
    func keepsABodyThatOpensWithAFenceLineInTheBody(source: String) {
        let (recipe, reRead) = roundTrip(source)

        #expect(reRead == recipe)
    }

    @Test
    func writesAnEmptyHeaderBeforeABodyThatOpensWithAFenceLine() {
        #expect(Recipe.read("---\n---\n\n---\nBoil.").serialized() == "---\n---\n\n---\nBoil.")
    }

    @Test(arguments: [
        "\u{FEFF}",
        "\u{FEFF}x",
        "\n\u{FEFF}",
        "\u{FEFF}\u{FEFF}x",
        "\u{FEFF}\u{FEFF}\n\nSpread with butter."
    ])
    func keepsABodyThatOpensWithAByteOrderMarkInTheBody(source: String) {
        let (recipe, reRead) = roundTrip(source)

        #expect(reRead == recipe)
    }

    @Test
    func doesNotSeparateABodyFenceLineFromAHeaderThatPrecedesIt() {
        let source = "---\ntitle: Tartine\n---\n\n---\nBring the water to a boil."

        #expect(Recipe.read(source).serialized() == source)
    }

    @Test
    func reReadingTheOutputYieldsTheSameRecipe() {
        let source = """
        ---
        title: Gratin Dauphinois
        servings: 2
        tags: [french, quick]
        ---


        Slice @{200 g}potatoes@ in a #gratin dish#.


        Season with @{a pinch} salt@ and serve.
        """

        let (recipe, reRead) = roundTrip(source)

        #expect(reRead.metadata == recipe.metadata)
        #expect(reRead.steps.count == recipe.steps.count)
        #expect(reRead.ingredients == recipe.ingredients)
        #expect(reRead.cookware == recipe.cookware)
    }
}
