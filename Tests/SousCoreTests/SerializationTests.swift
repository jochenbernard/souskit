import SousCore
import Testing

@Suite("Serialization round-trip")
struct SerializationTests {
    @Test(arguments: [
        "Toast the bread and spread it with butter.",
        "Fry @garlic@ until fragrant, then add @baby spinach@.",
        "Bring a #large pot# of water to a boil and cook @{200 g} spaghetti@.",
        "Add @{1-2 tbsp} olive oil@ and @{a pinch} salt@.",
        """
        Toast the bread.

        Spread with butter.
        """,
        """
        ---
        title: Garlic Butter Pasta
        servings: 2
        ---

        Melt @{30 g} butter@ in a #pan#, fry @{2 cloves} garlic@.
        """,
        "Mix @salt@@pepper@ in.",
        "Use a #{200 g} pan#.",
        "Add @{} salt@.",
        "Season with salt @",
        "Season to taste \\",
        "Read the \\note here.",
        "Note the path C:\\Users, then add @garlic@.",
        "Use a #8\\ pan#.",
        "Path C:\\\\@garlic@ now.",
        "Add @flour\\\\@ now.",
        "  Toast the bread.  ",
        "---\n: Alice\n---",
        "---\ntitle:  Toast\n---",
        "---\ntitle: a: b\n---",
        "---\nprep-time: 15 min\n---",
        "---\ntitle:\n---",
        "---\nnutrition:\n  calories: 640 kcal\n---",
        "---\ntags: [comfort food\\, italian]\n---",
        "---\ntags: [\\[sugar]\n---",
        "---\nsource: C:\\photos\\x\n---"
    ])
    func reproducesTheSourceExactly(source: String) {
        #expect(SousParser().parseRecipe(source).value.serialized() == source)
    }

    // A pair of identical sigils reads as ordinary text only while both stay unescaped: the
    // reader closes the span the first one opens on the second one at once, and keeps both.

    @Test(arguments: [
        "Use @@ here.",
        "Use ## here.",
        "## Sauce",
        "Rate it @@ out of five."
    ])
    func leavesAnInertSigilPairUnescaped(source: String) {
        #expect(SousParser().parseRecipe(source).value.serialized() == source)
    }

    @Test(arguments: [
        "\\@\\@garlic\\@ here.",
        "\\#\\#pan\\# here.",
        "\\@\\@garlic\\@",
        "Mix \\@\\@a\\@ into @flour@.",
        "\\@\\@\\@a\\@"
    ])
    func keepsProseWithAnEscapedSigilPairOnRoundTrip(source: String) {
        let parser = SousParser()
        let recipe = parser.parseRecipe(source).value
        let reRead = parser.parseRecipe(recipe.serialized()).value

        #expect(reRead.steps.map(\.segments) == recipe.steps.map(\.segments))
        #expect(reRead.ingredients == recipe.ingredients)
    }

    // The inline form is the only one a list is written in, because escaping lets any item
    // survive it.

    @Test
    func escapesASeparatorInAListItem() {
        let source = "---\ntags: comfort food, italian\n---"

        #expect(SousParser().parseRecipe(source).value.serialized() == "---\ntags: [comfort food\\, italian]\n---")
    }

    @Test
    func escapesABracketInAListItem() {
        let source = "---\ntags: [italian\n---"

        #expect(SousParser().parseRecipe(source).value.serialized() == "---\ntags: [\\[italian]\n---")
    }

    @Test(arguments: [
        "---\ntags: comfort food, italian\n---",
        "---\ntags: [italian\n---",
        "---\ntags: a]b\n---",
        "---\ntags: [a\\]\n---",
        "---\ntags: C:\\x\n---",
        "---\ntags: [a\\\\b, c]\n---",
        "---\ntags: [a, b] \n---"
    ])
    func keepsEveryListItemOnRoundTrip(source: String) {
        let parser = SousParser()
        let recipe = parser.parseRecipe(source).value
        let reRead = parser.parseRecipe(recipe.serialized()).value

        #expect(reRead.metadata.tags == recipe.metadata.tags)
        #expect(reRead.metadata.entries == recipe.metadata.entries)
    }

    @Test
    func writesAnEmptyScalarValueWithoutATrailingSpace() {
        #expect(SousParser().parseRecipe("---\ntitle:\n---").value.serialized() == "---\ntitle:\n---")
    }

    @Test
    func preservesAnUnrecognizedHeaderKeyOnRoundTrip() {
        let source = """
        ---
        title: Toast
        chef: Alice
        ---
        """

        #expect(SousParser().parseRecipe(source).value.serialized() == source)
    }

    @Test
    func preservesAnUnclosedSpanAsLiteralTextOnRoundTrip() {
        let source = "Fry @garlic until fragrant."

        let parser = SousParser()
        let recipe = parser.parseRecipe(source).value
        let reRead = parser.parseRecipe(recipe.serialized()).value

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
        #expect(SousParser().parseRecipe(source).value.serialized() == source)
    }

    @Test
    func reEscapesAProseSigilAdjacentToAnAnnotation() {
        let source = "\\@@garlic@ now."

        #expect(SousParser().parseRecipe(source).value.serialized() == source)
    }

    // An escape that was not needed, such as a sigil already followed by whitespace, loses
    // its backslash on the way out. The recipe it re-reads to is unchanged.

    @Test(arguments: [
        "Add a \\@ symbol here.",
        "Write a \\{ brace here.",
        "All six: \\@ \\# \\~ \\> \\{ \\\\ done.",
        "Mix @{200 g} flour@ and \\@ the rest.",
        "Halve the \\\\ ratio.",
        "Add @a\\\\b@ now."
    ])
    func normalizesAnUnneededEscapeButPreservesTheRecipe(source: String) {
        let parser = SousParser()
        let recipe = parser.parseRecipe(source).value
        let reRead = parser.parseRecipe(recipe.serialized()).value

        #expect(reRead.steps.map(\.segments) == recipe.steps.map(\.segments))
        #expect(reRead.metadata == recipe.metadata)
    }

    // Incidental layout, such as repeated blank lines or a trailing newline, is normalized
    // rather than preserved. What must hold is that the output re-reads to the same recipe.

    @Test(arguments: [
        "Toast the bread.\n",
        "Toast the bread.\n\n",
        "\nToast the bread.",
        "First step.\n\n\nSecond step.",
        "---\n---",
        "---\ntitle: Toast\n---\nBody line.",
        "Cook @{200 g}pasta@.",
        "Toast the bread.\n   \nSpread with butter.",
        "--- \ntitle: Toast\n--- ",
        "Add @{200 g}@ now.",
        "Toast the bread\u{2028}and butter it."
    ])
    func normalizingLayoutIsStable(source: String) {
        let parser = SousParser()
        let normalized = parser.parseRecipe(source).value.serialized()

        #expect(parser.parseRecipe(normalized).value.serialized() == normalized)
    }

    @Test(arguments: [
        "Toast the bread.\n   \nSpread with butter.",
        "--- \ntitle: Toast\n--- ",
        "Add @{200 g}@ now.",
        "Toast the bread\u{2028}and butter it.",
        "---\ntags: [italian, quick] \n---",
        "---\ntags:  [italian, quick]\n---"
    ])
    func normalizingLayoutKeepsTheContent(source: String) {
        let parser = SousParser()
        let recipe = parser.parseRecipe(source).value
        let reRead = parser.parseRecipe(recipe.serialized()).value

        #expect(reRead.steps.map(\.segments) == recipe.steps.map(\.segments))
        #expect(reRead.metadata == recipe.metadata)
    }

    // A body step that opens with a fence line would read back as a metadata header, so the
    // output keeps it in the body rather than losing it.

    @Test(arguments: [
        "\n---",
        "\n---\nBring the water to a boil.",
        "\n\n--- ",
        "\n---\n\nSpread with butter."
    ])
    func keepsABodyThatOpensWithAFenceLineInTheBody(source: String) {
        let parser = SousParser()
        let recipe = parser.parseRecipe(source).value

        #expect(parser.parseRecipe(recipe.serialized()).value == recipe)
    }

    @Test
    func doesNotSeparateABodyFenceLineFromAHeaderThatPrecedesIt() {
        let source = "---\ntitle: Toast\n---\n\n---\nBring the water to a boil."

        #expect(SousParser().parseRecipe(source).value.serialized() == source)
    }

    @Test
    func reReadingTheOutputYieldsTheSameRecipe() {
        let source = """
        ---
        title: Garlic Pasta
        servings: 2
        tags: [italian, quick]
        ---


        Cook @{200 g}pasta@ in a #large pot#.


        Season with @{a pinch} salt@ and serve.
        """

        let parser = SousParser()
        let recipe = parser.parseRecipe(source).value
        let reRead = parser.parseRecipe(recipe.serialized()).value
        let ingredients = recipe.steps.flatMap(\.ingredients)
        let reReadIngredients = reRead.steps.flatMap(\.ingredients)
        let cookware = recipe.steps.flatMap(\.cookware)
        let reReadCookware = reRead.steps.flatMap(\.cookware)

        #expect(reRead.metadata == recipe.metadata)
        #expect(reRead.steps.count == recipe.steps.count)
        #expect(reReadIngredients == ingredients)
        #expect(reReadCookware == cookware)
    }
}
