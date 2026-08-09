import SousCore
import Testing

@Suite("Value semantics")
struct ValueSemanticsTests {
    /// One parser shared across tests, so its use from another isolation domain is exercised.
    private static let parser = SousParser()

    @Test
    func sharesOneParserAcrossIsolationDomains() async {
        let recipe = await Task.detached { Self.parser.parseRecipe("Fry @garlic@ in a #pan#.").value }.value

        #expect(recipe.ingredients.map(\.name) == ["garlic"])
        #expect(recipe.cookware.map(\.name) == ["pan"])
    }

    @Test
    func comparesTwoParsesOfTheSameSource() {
        let source = "---\ntitle: Tartine\n---\n\nFry @garlic@ in a #pan#."
        let first = Self.parser.parseRecipe(source)
        let second = Self.parser.parseRecipe(source)

        #expect(first == second)
    }

    @Test
    func distinguishesParsesOfDifferentSources() {
        #expect(Self.parser.parseRecipe("Fry @garlic@.") != Self.parser.parseRecipe("Fry @onion@."))
    }

    @Test
    func distinguishesParsesThatDifferOnlyInTheirDiagnostics() {
        #expect(Self.parser.parseRecipe("Fry @garlic@.") != Self.parser.parseRecipe("Fry @garlic@ and @onion."))
    }

    @Test
    func hashesEqualRecipesAlike() {
        let recipes: Set<Recipe> = [
            Self.parser.parseRecipe("Fry @garlic@.").value,
            Self.parser.parseRecipe("Fry @garlic@.").value
        ]

        #expect(recipes.count == 1)
    }

    @Test
    func hashesEqualParseResultsAlike() {
        let results: Set<Parsed<Recipe>> = [
            Self.parser.parseRecipe("Fry @garlic until fragrant."),
            Self.parser.parseRecipe("Fry @garlic until fragrant.")
        ]

        #expect(results.count == 1)
    }
}
