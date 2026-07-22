import SousCore
import Testing

// Scaling to a target, available since v0.3. The factor is the target divided by the declared
// yield of the same unit, so the recipe has to declare one the target can be divided by.
//
// Units are compared with the whitespace around them ignored and nothing else. Recognizing two
// spellings of one dimension needs reference data, which the semantic layer adds later.

@Suite("Scaling to a target")
struct TargetScalingTests {
    private func scaled(_ source: String, to target: String) throws -> Recipe {
        let parser = SousParser()

        return try parser.parseRecipe(source).value.scaled(to: parser.parseAmount(target))
    }

    private func flour(in recipe: Recipe) throws -> Double {
        try #require(recipe.ingredients.first?.amount?.kind.preciseQuantity?.value)
    }

    // The parser is where an amount is read from text, so a caller states a target the way a
    // recipe states a yield.

    @Test
    func readsATargetAmountFromItsText() {
        let target = SousParser().parseAmount("18 pancakes")

        #expect(target.kind.preciseQuantity?.value == 18.0)
        #expect(target.unit == "pancakes")
        #expect(target.text == "18 pancakes")
    }

    @Test
    func derivesTheFactorFromTheYieldOfTheTargetsUnit() throws {
        let source = "---\nyield: 12 pancakes\n---\n\nWhisk @{200 g} flour@ into a batter."

        let recipe = try scaled(source, to: "18 pancakes")
        #expect(try flour(in: recipe) == 300.0)
        #expect(recipe.metadata.yields.map(\.text) == ["18 pancakes"])
    }

    @Test
    func countsServingsAsAYieldInPortions() throws {
        let source = "---\nservings: 4\n---\n\nWhisk @{200 g} flour@ into a batter."

        let recipe = try scaled(source, to: "8 servings")
        #expect(try flour(in: recipe) == 400.0)
        #expect(recipe.metadata.servings == 8.0)
    }

    @Test
    func picksTheYieldOfTheTargetsOwnUnitFromSeveral() throws {
        let source = "---\nyield: [6 servings, 3.2 kg]\n---\n\nWhisk @{200 g} flour@ into a batter."

        let recipe = try scaled(source, to: "1.6 kg")
        #expect(try flour(in: recipe) == 100.0)
        // Every declared yield scales, not only the one the factor came from.
        #expect(recipe.metadata.yields.map(\.text) == ["3 servings", "1.6 kg"])
    }

    @Test
    func matchesAUnitThroughTheWhitespaceAroundIt() throws {
        let source = "---\nyield: 800  g\n---\n\nWhisk @{200 g} flour@ into a batter."

        #expect(try flour(in: scaled(source, to: "1000 g")) == 250.0)
    }

    @Test
    func matchesAnEmptyUnitAgainstAnEmptyUnit() throws {
        let source = "---\nyield: 12\n---\n\nWhisk @{200 g} flour@ into a batter."

        #expect(try flour(in: scaled(source, to: "18")) == 300.0)
    }

    // Two spellings of one dimension are two units here, and case is part of the spelling.

    @Test(arguments: ["1 kg", "18 Pancakes", "18", "500 ml"])
    func refusesATargetNoDeclaredYieldStates(target: String) {
        let source = "---\nservings: 4\nyield: [800 g, 12 pancakes]\n---\n\nMix @{200 g} flour@."

        #expect(throws: ScalingError.noMatchingYield) {
            try scaled(source, to: target)
        }
    }

    @Test
    func refusesARecipeThatDeclaresNothingToDivideBy() {
        #expect(throws: ScalingError.noMatchingYield) {
            try scaled("Mix @{200 g} flour@.", to: "400 g")
        }
    }

    // A target has to state one quantity to divide by, so a range and an imprecise amount
    // divide nothing, whatever the recipe declares.

    @Test(arguments: ["1-2 kg", "plenty", "a lot of g"])
    func refusesATargetThatStatesNoSingleQuantity(target: String) {
        let source = "---\nyield: 800 g\n---\n\nMix @{200 g} flour@."

        #expect(throws: ScalingError.noMatchingYield) {
            try scaled(source, to: target)
        }
    }

    @Test(arguments: [
        (header: "yield: 0 g", target: "500 g"),
        (header: "servings: 0", target: "8 servings")
    ])
    func refusesToDivideByAYieldOfZero(header: String, target: String) {
        #expect(throws: ScalingError.zeroYield) {
            try scaled("---\n\(header)\n---\n\nMix @{200 g} flour@.", to: target)
        }
    }

    // A yield has to state one quantity to be divided by too, so a range names a dimension it
    // cannot itself serve as the divisor for.

    @Test
    func refusesToDivideByAYieldThatStatesARange() {
        let source = "---\nyield: 10-12 muffins\n---\n\nMix @{200 g} flour@."

        #expect(throws: ScalingError.noMatchingYield) {
            try scaled(source, to: "18 muffins")
        }
    }

    // Scaling to a number of portions is the same derivation, taken from either spelling of a
    // portion yield.

    @Test(arguments: ["---\nservings: 6\n---", "---\nyield: 6 servings\n---"])
    func scalesToANumberOfServings(header: String) throws {
        let source = "\(header)\n\nWhisk @{200 g} flour@ into a batter."

        let recipe = try SousParser().parseRecipe(source).value.scaled(toServings: 9.0)
        #expect(try flour(in: recipe) == 300.0)
    }

    @Test
    func refusesANumberOfServingsWhenNoPortionsAreDeclared() {
        let source = "---\nyield: 800 g\n---\n\nMix @{200 g} flour@."
        let recipe = SousParser().parseRecipe(source).value

        #expect(throws: ScalingError.noMatchingYield) {
            try recipe.scaled(toServings: 8.0)
        }
    }

    @Test
    func refusesZeroDeclaredServings() {
        let recipe = SousParser().parseRecipe("---\nservings: 0\n---\n\nMix @{200 g} flour@.").value

        #expect(throws: ScalingError.zeroYield) {
            try recipe.scaled(toServings: 8.0)
        }
    }

    @Test(arguments: [-2.0, Double.infinity, Double.nan])
    func refusesAServingsTargetItCouldNotWriteBack(servings: Double) {
        let recipe = SousParser().parseRecipe("---\nservings: 4\n---\n\nMix @{200 g} flour@.").value

        #expect(throws: ScalingError.unusableFactor) {
            try recipe.scaled(toServings: servings)
        }
    }

    @Test
    func scalingToWhatIsAlreadyDeclaredChangesNothing() throws {
        let source = "---\nservings: 4\n---\n\nMix @{200g} flour@ and @{=1 tsp} salt@."
        let recipe = SousParser().parseRecipe(source).value

        #expect(try recipe.scaled(toServings: 4.0) == recipe)
    }

    @Test
    func aTargetOfZeroScalesToNothing() throws {
        let source = "---\nservings: 4\n---\n\nMix @{200 g} flour@."

        let recipe = try SousParser().parseRecipe(source).value.scaled(toServings: 0.0)
        #expect(try flour(in: recipe) == 0.0)
        #expect(recipe.metadata.servings == 0.0)
    }
}
