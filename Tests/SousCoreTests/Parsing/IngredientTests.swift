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
        let ingredient = try #require(Recipe.read("Add @pearl onions@.").firstIngredient)
        #expect(ingredient.name == "pearl onions")
    }

    @Test
    func anIngredientWithoutAFenceHasNoAmount() throws {
        let ingredient = try #require(Recipe.read("Season with @salt@.").firstIngredient)
        #expect(ingredient.amount == nil)
    }

    @Test
    func allowsNoSpaceBetweenTheAmountFenceAndTheName() throws {
        let ingredient = try #require(Recipe.read("Sift @{200 g}flour@.").firstIngredient)
        #expect(ingredient.name == "flour")
    }

    @Test(arguments: [
        "@{200 g}  flour@",
        "@{200 g}\tflour@",
        "@{200 g} flour @",
        "@flour @"
    ])
    func trimsTheWhitespaceAroundAName(span: String) {
        let parsed = SousParser().parseRecipe("Sift \(span).")

        #expect(parsed.value.ingredients.map(\.name) == ["flour"])
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func writesTheSeparationTheNameNoLongerCarries() {
        #expect(Recipe.read("Sift @{200 g}  flour@.").serialized() == "Sift @{200 g} flour@.")
    }

    @Test(arguments: [
        "Sift @{200 g}@.",
        "Sift @{200 g}   @.",
        "Fry @{2 cloves garlic}@.",
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
        let step = try #require(Recipe.read("Fry @garlic@ and add @pearl onions@.").firstStep)
        #expect(step.ingredients.map(\.name) == ["garlic", "pearl onions"])
    }

    @Test
    func readsALiteralSigilInsideAFenceAsPartOfTheAmount() throws {
        let parsed = SousParser().parseRecipe("Add @{a@b} beef stock@ now.")

        let ingredient = try #require(parsed.value.firstIngredient)
        #expect(ingredient.name == "beef stock")
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
        let parsed = SousParser().parseRecipe("Add @{200 g flour@ and @{100 g} butter@.")

        let step = try #require(parsed.value.steps.first)
        let ingredient = try #require(step.ingredients.first)
        #expect(step.ingredients.count == 1)
        #expect(ingredient.name == "butter")
        #expect(ingredient.amount?.text == "200 g flour@ and @{100 g")
        #expect(parsed.diagnostics.isEmpty)
    }
}
