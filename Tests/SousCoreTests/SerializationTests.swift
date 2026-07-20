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
}
