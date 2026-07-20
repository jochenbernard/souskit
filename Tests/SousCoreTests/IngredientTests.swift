import SousCore
import Testing

@Suite("Ingredients")
struct IngredientTests {
    @Test
    func parsesASingleWordName() throws {
        let parsed = SousParser().parseRecipe("Fry @garlic@ until fragrant.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.name == "garlic")
        #expect(ingredient.amount == nil)
    }

    @Test
    func parsesAMultiWordName() throws {
        let parsed = SousParser().parseRecipe("Add @baby spinach@.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.name == "baby spinach")
    }

    @Test
    func capturesTheNameVerbatimIncludingLeadingConnectives() throws {
        let parsed = SousParser().parseRecipe("Grate @{1 kg} of parmesan@ over the top.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.name == "of parmesan")
    }

    @Test
    func anIngredientWithoutAFenceHasNoAmount() throws {
        let parsed = SousParser().parseRecipe("Season with @salt@.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.amount == nil)
    }

    @Test
    func allowsNoSpaceBetweenTheAmountFenceAndTheName() throws {
        let parsed = SousParser().parseRecipe("Cook @{200 g}pasta@.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.name == "pasta")
    }

    @Test
    func extractsSeveralIngredientsFromOneStep() throws {
        let parsed = SousParser().parseRecipe("Fry @garlic@ and add @baby spinach@.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.map(\.name) == ["garlic", "baby spinach"])
    }
}
