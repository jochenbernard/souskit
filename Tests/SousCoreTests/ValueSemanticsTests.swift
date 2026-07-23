import SousCore
import Testing

// The public types are values: two parses of the same source are interchangeable, and the
// conditional conformances on `Parsed` follow the value it carries.

@Suite("Value semantics")
struct ValueSemanticsTests {
    /// A parser holds nothing, so one can back a whole application. Declaring it here is the
    /// test: a type that is not sendable cannot be stored like this under strict concurrency.
    private static let parser = SousParser()

    @Test
    func sharesOneParserAcrossIsolationDomains() async {
        let recipe = await Task.detached { Self.parser.parseRecipe("Fry @garlic@ in a #pan#.").value }.value

        #expect(recipe.ingredients.map(\.name) == ["garlic"])
        #expect(recipe.cookware.map(\.name) == ["pan"])
    }

    @Test
    func comparesTwoParsesOfTheSameSource() {
        let source = "---\ntitle: Toast\n---\n\nFry @garlic@ in a #pan#."
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
