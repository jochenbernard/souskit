import SousCore
import Testing

// The public types are values: two parses of the same source are interchangeable, and the
// conditional conformances on `Parsed` follow the value it carries.

@Suite("Value semantics")
struct ValueSemanticsTests {
    @Test
    func comparesTwoParsesOfTheSameSource() {
        let parser = SousParser()
        let source = "---\ntitle: Toast\n---\n\nFry @garlic@ in a #pan#."
        let first = parser.parseRecipe(source)
        let second = parser.parseRecipe(source)

        #expect(first == second)
    }

    @Test
    func distinguishesParsesOfDifferentSources() {
        let parser = SousParser()

        #expect(parser.parseRecipe("Fry @garlic@.") != parser.parseRecipe("Fry @onion@."))
    }

    @Test
    func distinguishesParsesThatDifferOnlyInTheirDiagnostics() {
        let parser = SousParser()

        #expect(parser.parseRecipe("Fry @garlic@.") != parser.parseRecipe("Fry @garlic@ and @onion."))
    }

    @Test
    func hashesEqualRecipesAlike() {
        let parser = SousParser()
        let recipes: Set<Recipe> = [
            parser.parseRecipe("Fry @garlic@.").value,
            parser.parseRecipe("Fry @garlic@.").value
        ]

        #expect(recipes.count == 1)
    }

    @Test
    func hashesEqualParseResultsAlike() {
        let parser = SousParser()
        let results: Set<Parsed<Recipe>> = [
            parser.parseRecipe("Fry @garlic until fragrant."),
            parser.parseRecipe("Fry @garlic until fragrant.")
        ]

        #expect(results.count == 1)
    }
}
