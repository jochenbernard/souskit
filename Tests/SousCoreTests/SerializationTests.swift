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
        """
    ])
    func reproducesTheSourceExactly(source: String) {
        #expect(SousParser().parseRecipe(source).value.serialized() == source)
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

        #expect(SousParser().parseRecipe(source).value.serialized() == source)
    }

    @Test(arguments: [
        "Add a \\@ symbol here.",
        "Write a \\{ brace here.",
        "All five: \\@ \\# \\~ \\> \\{ done.",
        "Add @\\{not a fence@ now.",
        "Use a #8\\# pan#.",
        "Mix @{200 g} flour@ and \\@ the rest."
    ])
    func reproducesEscapedCharactersExactly(source: String) {
        #expect(SousParser().parseRecipe(source).value.serialized() == source)
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
        "Cook @{200 g}pasta@."
    ])
    func normalizingLayoutIsStable(source: String) {
        let parser = SousParser()
        let normalized = parser.parseRecipe(source).value.serialized()

        #expect(parser.parseRecipe(normalized).value.serialized() == normalized)
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
