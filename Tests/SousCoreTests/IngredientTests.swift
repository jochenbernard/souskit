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

    // A name is trimmed, so whatever whitespace separates it from the fence belongs to
    // neither and the writer states the separation as the one space it writes.

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

    // A span stating an amount and naming nothing is ordinary text like any other span that
    // names nothing, and the amount its author wrote would go with it, so it is reported.

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
        // A bare pair of sigils is prose an author wrote for its own sake, so it earns no
        // report; only an amount states something a reader would otherwise drop.
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
