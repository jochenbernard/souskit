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

    // A single space separates the fence from the name and belongs to neither. Nothing else
    // is stripped, so any further whitespace is part of the name.

    @Test
    func keepsWhitespaceBeyondTheOneSeparatingSpaceInTheName() throws {
        let parsed = SousParser().parseRecipe("Cook @{200 g}  pasta@.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.name == " pasta")
        #expect(parsed.value.serialized() == "Cook @{200 g}  pasta@.")
    }

    @Test
    func doesNotTakeAWhitespaceOtherThanASpaceAsTheSeparator() throws {
        let parsed = SousParser().parseRecipe("Cook @{200 g}\tpasta@.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.name == "\tpasta")
    }

    @Test
    func extractsSeveralIngredientsFromOneStep() throws {
        let parsed = SousParser().parseRecipe("Fry @garlic@ and add @baby spinach@.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.map(\.name) == ["garlic", "baby spinach"])
    }

    @Test
    func readsALiteralSigilInsideAFenceAsPartOfTheAmount() throws {
        let parsed = SousParser().parseRecipe("Add @{a@b} sauce@ now.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.name == "sauce")
        #expect(ingredient.amount?.kind.impreciseText == "a@b")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func letsAnUnclosedFenceReachTheNextClosingBrace() throws {
        // A sigil is inert between the braces, so the fence closes on the next "}" in the
        // paragraph rather than on the sigil that comes before it.
        let parsed = SousParser().parseRecipe("Add @{200 g pasta@ and @{100 g} sauce@.")

        let step = try #require(parsed.value.steps.first)
        let ingredient = try #require(step.ingredients.first)
        #expect(step.ingredients.count == 1)
        #expect(ingredient.name == "sauce")
        #expect(ingredient.amount?.text == "200 g pasta@ and @{100 g")
        #expect(parsed.diagnostics.isEmpty)
    }
}
