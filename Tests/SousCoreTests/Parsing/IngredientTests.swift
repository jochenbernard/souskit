import SousCore
import Testing

@Suite("Ingredients")
struct IngredientTests {
    @Test
    func parsesASingleWordName() throws {
        let ingredient = try #require(Recipe.read("Fry @garlic@ until fragrant.").firstIngredient)
        #expect(ingredient.name == "garlic")
        #expect(ingredient.amount == nil)
    }

    @Test
    func parsesAMultiWordName() throws {
        let ingredient = try #require(Recipe.read("Add @baby spinach@.").firstIngredient)
        #expect(ingredient.name == "baby spinach")
    }

    @Test
    func capturesTheNameVerbatimIncludingLeadingConnectives() throws {
        let ingredient = try #require(Recipe.read("Grate @{1 kg} of parmesan@ over the top.").firstIngredient)
        #expect(ingredient.name == "of parmesan")
    }

    @Test
    func anIngredientWithoutAFenceHasNoAmount() throws {
        let ingredient = try #require(Recipe.read("Season with @salt@.").firstIngredient)
        #expect(ingredient.amount == nil)
    }

    @Test
    func allowsNoSpaceBetweenTheAmountFenceAndTheName() throws {
        let ingredient = try #require(Recipe.read("Cook @{200 g}pasta@.").firstIngredient)
        #expect(ingredient.name == "pasta")
    }

    @Test(arguments: [
        "@{200 g}  pasta@",
        "@{200 g}\tpasta@",
        "@{200 g} pasta @",
        "@pasta @"
    ])
    func trimsTheWhitespaceAroundAName(span: String) {
        let parsed = SousParser().parseRecipe("Cook \(span).")

        #expect(parsed.value.ingredients.map(\.name) == ["pasta"])
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func writesTheSeparationTheNameNoLongerCarries() {
        #expect(Recipe.read("Cook @{200 g}  pasta@.").serialized() == "Cook @{200 g} pasta@.")
    }

    @Test(arguments: [
        "Cook @{200 g}@.",
        "Cook @{200 g}   @.",
        "Cook @{2 cloves garlic}@.",
        "Spread the >{2}> now."
    ])
    func warnsAboutASpanStatingAnAmountAndNamingNothing(source: String) {
        let parsed = SousParser().parseRecipe(source)

        #expect(parsed.value.ingredients.isEmpty)
        #expect(parsed.value.references.isEmpty)
        #expect(parsed.value.steps.map(\.text) == [source])
        #expect(parsed.diagnostics.map(\.kind) == [.unnamedAnnotation])
    }

    @Test(arguments: ["Rate it @@ out of five.", "Use ## here.", "Spread the >> now."])
    func reportsNothingForASpanStatingNoAmountAndNamingNothing(source: String) {
        #expect(SousParser().parseRecipe(source).diagnostics.isEmpty)
    }

    @Test
    func extractsSeveralIngredientsFromOneStep() throws {
        let step = try #require(Recipe.read("Fry @garlic@ and add @baby spinach@.").firstStep)
        #expect(step.ingredients.map(\.name) == ["garlic", "baby spinach"])
    }

    @Test
    func readsALiteralSigilInsideAFenceAsPartOfTheAmount() throws {
        let parsed = SousParser().parseRecipe("Add @{a@b} sauce@ now.")

        let ingredient = try #require(parsed.value.firstIngredient)
        #expect(ingredient.name == "sauce")
        #expect(ingredient.amount?.kind.impreciseText == "a@b")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsAnEscapedBraceAsPartOfTheAmount() throws {
        let parsed = SousParser().parseRecipe("Add @{a\\}b} salt@.")

        let ingredient = try #require(parsed.value.firstIngredient)
        #expect(ingredient.amount?.kind.impreciseText == "a}b")
        #expect(ingredient.name == "salt")
        #expect(parsed.diagnostics.isEmpty)
        #expect(parsed.value.serialized() == "Add @{a\\}b} salt@.")
    }

    @Test
    func letsAnUnclosedFenceReachTheNextClosingBrace() throws {
        let parsed = SousParser().parseRecipe("Add @{200 g pasta@ and @{100 g} sauce@.")

        let step = try #require(parsed.value.steps.first)
        let ingredient = try #require(step.ingredients.first)
        #expect(step.ingredients.count == 1)
        #expect(ingredient.name == "sauce")
        #expect(ingredient.amount?.text == "200 g pasta@ and @{100 g")
        #expect(parsed.diagnostics.isEmpty)
    }
}
