import SousCore
import Testing

@Suite("Cookware")
struct CookwareTests {
    @Test
    func parsesASingleWordName() throws {
        let parsed = SousParser().parseRecipe("Warm a #pan#.")

        let cookware = try #require(parsed.value.steps.first?.cookware.first)
        #expect(cookware.name == "pan")
    }

    @Test
    func parsesAMultiWordName() throws {
        let parsed = SousParser().parseRecipe("Bring a #large pot# of water to a boil.")

        let cookware = try #require(parsed.value.steps.first?.cookware.first)
        #expect(cookware.name == "large pot")
    }

    @Test
    func extractsIngredientsAndCookwareFromTheSameStep() throws {
        let parsed = SousParser().parseRecipe("Melt @{30 g} butter@ in a #pan#.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.map(\.name) == ["butter"])
        #expect(step.cookware.map(\.name) == ["pan"])
    }
}
