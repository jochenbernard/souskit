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
        "Whisk the vinegar and beat in the oil.",
        "Fry @garlic@ until fragrant, then add @pearl onions@.",
        "Bring a #stockpot# of @{2 l} fish stock@ to a simmer and poach @{1.5 kg} rockfish@.",
        "Add @{1-2 tbsp} olive oil@ and @{a pinch} salt@.",
        """
        Whisk the vinegar.

        Beat in the oil.
        """,
        """
        ---
        title: Moules Marinieres
        servings: 2
        ---

        Soften @{2} shallots@ in @{50 g} butter@ in a #heavy pot#.
        """,
        "Mix @salt@@thyme@ in.",
        "Simmer gently for ~40 min~, then rest ~overnight~.",
        "Bake ~8-10 min~ and rest ~1 h 30 min~.",
        "Chill ~over\\~night~ now.",
        "Wait \\~40 min here.",
        "Stir in @{=1 tsp} saffron@.",
        "Season with @salt@:staple and @black pepper@:staple.",
        "Scatter @thyme@? over the top.",
        "Scatter @thyme@?y over the top.",
        "Weigh it down with @{500 g} baking beans@:non-food.",
        "Add @{=10 g} salt@:staple now.",
        "Add @baking beans@:staple:non-food now.",
        "Add @salt@:staple?y here.",
        "Add @beef stock@:homemade now.",
        "Add @beef stock@:homemade?2 now.",
        "Is it @salt@\\? Yes.",
        "Serve @potatoes@\\:about 200 g each.",
        "@potatoes@\\:about 200 g each.",
        "Season with @salt@:staple\\?y.",
        "Add @beef stock@:homemade\\:more now.",
        "Season with @salt@: to taste.",
        "Use a #{200 g} frying pan#.",
        "Add @{} salt@.",
        "Add @{200 g} {a} flour@ now.",
        "Add @a{b@ now.",
        "Add @{2 \\z g} flour@.",
        "Season with salt @",
        "Season to taste \\",
        "## Filling\nBrown the beef.",
        "## a\\zb",
        "## ",
        "## \nx@salt@",
        "@## a@ now.",
        "Layer the >{300 g} bechamel> in a dish.",
        "Write a { brace here.",
        "Read the \\note here.",
        "Note the path C:\\Users, then add @garlic@.",
        "Use a #8\\ tin#.",
        "Path C:\\\\@garlic@ now.",
        "Add @flour\\\\@ now.",
        "  Whisk the vinegar.  ",
        "---\n: Camille\n---",
        "---\ntitle: a: b\n---",
        "---\nprep-time: 15 min\n---",
        "---\ntitle:\n---",
        "---\nnutrition:\n  calories: 3300 kcal\n---",
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
        "\\#\\#tin\\# here.",
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
        (source: "Add @baking beans@:non-food:staple now.", written: "Add @baking beans@:staple:non-food now."),
        (source: "Add @salt@:optional now.", written: "Add @salt@? now."),
        (source: "Add @salt@:staple:staple now.", written: "Add @salt@:staple now."),
        (source: "Add @salt@?:staple now.", written: "Add @salt@:staple? now."),
        (source: "Add @beef stock@:homemade:staple now.", written: "Add @beef stock@:staple:homemade now.")
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
        title: Vinaigrette
        chef: Camille
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
        "Use a #8\\# tin#.",
        "Add @a\\@b@ now.",
        "Email \\@user today.",
        "Weigh a \\#5 tin here."
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

    @Test(arguments: NormalizedLayouts.sources)
    func normalizingLayoutIsStable(source: String) {
        let parser = SousParser()
        let normalized = parser.parseRecipe(source).value.serialized()

        #expect(parser.parseRecipe(normalized).value.serialized() == normalized)
    }

    @Test(arguments: NormalizedLayouts.sources)
    func normalizingLayoutKeepsTheContent(source: String) {
        expectTheRecipeSurvivesARoundTrip(source)
    }

    @Test(arguments: [
        "---\n---\n\n---",
        "---\n---\n\n---\nBring the water to a boil.",
        "---\n---\n\n--- ",
        "---\n---\n\n---\n\nBeat in the oil."
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
        "\u{FEFF}\u{FEFF}\n\nBeat in the oil."
    ])
    func keepsABodyThatOpensWithAByteOrderMarkInTheBody(source: String) {
        let (recipe, reRead) = roundTrip(source)

        #expect(reRead == recipe)
    }

    @Test
    func doesNotSeparateABodyFenceLineFromAHeaderThatPrecedesIt() {
        let source = "---\ntitle: Vinaigrette\n---\n\n---\nBring the water to a boil."

        #expect(Recipe.read(source).serialized() == source)
    }

    @Test
    func reReadingTheOutputYieldsTheSameRecipe() {
        let source = """
        ---
        title: Gratin Dauphinois
        servings: 6
        tags: [comfort food, french]
        ---


        Slice @{1.2 kg}potatoes@ into a #gratin dish#.


        Pour over @{500 ml} cream@ and bake.
        """

        let (recipe, reRead) = roundTrip(source)

        #expect(reRead.metadata == recipe.metadata)
        #expect(reRead.steps.count == recipe.steps.count)
        #expect(reRead.ingredients == recipe.ingredients)
        #expect(reRead.cookware == recipe.cookware)
    }
}
