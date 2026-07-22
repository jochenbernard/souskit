import SousCore
import Testing

// Scaling to a target, available since v0.3. The factor is the target divided by the declared
// yield of the same unit, so the recipe has to declare one the target can be divided by.
//
// Units are compared with the whitespace around them ignored and nothing else. Recognizing two
// spellings of one dimension needs reference data, which a later version adds.

@Suite("Scaling to a target")
struct TargetScalingTests {
    private func scaled(_ source: String, to target: String) throws -> Recipe {
        let parser = SousParser()

        return try parser.parseRecipe(source).value.scaled(to: parser.parseAmount(target))
    }

    /// The suite's recipe: one header under test over one amount, so a scaled flour weight
    /// reads back as the factor the header derived.
    private func recipe(_ header: String) -> String {
        "---\n\(header)\n---\n\nMix @{200 g} flour@."
    }

    private func flour(in recipe: Recipe) throws -> Double {
        try #require(recipe.firstAmount?.kind.preciseQuantity?.value)
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

    // A target is read exactly as fence content, with nothing trimmed, so it differs from the
    // header value of the same text in both directions the fence rules allow.

    @Test
    func readsATargetOpeningWithWhitespaceAsImprecise() {
        let target = SousParser().parseAmount(" 800 g")

        #expect(target.kind.impreciseText == " 800 g")
        #expect(target.unit == nil)
    }

    @Test
    func readsTheFixedMarkerOfATargetAndScalesByItAnyway() throws {
        let parser = SousParser()
        let target = parser.parseAmount("=8 servings")
        #expect(target.isFixed)

        // The marker states that an amount does not move, which a target is never asked to.
        let scaled = try parser.parseRecipe(recipe("servings: 4")).value.scaled(to: target)
        #expect(try flour(in: scaled) == 400.0)
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
        #expect(throws: ScalingError.noMatchingYield) {
            try scaled(recipe("servings: 4\nyield: [800 g, 12 pancakes]"), to: target)
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
        #expect(throws: ScalingError.noMatchingYield) {
            try scaled(recipe("yield: 800 g"), to: target)
        }
    }

    @Test(arguments: [
        (header: "yield: 0 g", target: "500 g"),
        (header: "servings: 0", target: "8 servings")
    ])
    func refusesToDivideByAYieldOfZero(header: String, target: String) {
        #expect(throws: ScalingError.zeroYield) {
            try scaled(recipe(header), to: target)
        }
    }

    // A value stating no quantity states no dimension, which is what validation reads it as,
    // so it neither conflicts with a yield nor hides one behind it.

    @Test(arguments: [
        (header: "servings: six\nyield: 4 servings", target: "8 servings", expected: 400.0),
        (header: "yield: [plenty, 12]", target: "18", expected: 300.0),
        (header: "yield: [plenty g, 800 g]", target: "1600 g", expected: 400.0)
    ])
    func looksPastAYieldThatStatesNoQuantity(header: String, target: String, expected: Double) throws {
        #expect(try flour(in: scaled(recipe(header), to: target)) == expected)
    }

    @Test
    func looksPastAServingsValueThatStatesNoQuantity() throws {
        let parsed = SousParser().parseRecipe(recipe("servings: six\nyield: 4 servings")).value

        #expect(try flour(in: parsed.scaled(toServings: 8.0)) == 400.0)
    }

    // The fixed marker belongs to the amount fence, so a header value opening with one states
    // an imprecise amount, which names no dimension to divide by.

    @Test(arguments: ["servings: =4", "yield: =4 servings"])
    func readsNoFixedMarkerInAHeaderValue(header: String) {
        #expect(throws: ScalingError.noMatchingYield) {
            try scaled(recipe(header), to: "8 servings")
        }
    }

    // A dimension stated more than once is reported by validation either way, but it divides
    // just as well while every statement of it agrees.

    @Test(arguments: [
        "servings: 4\nyield: 4 servings",
        "yield: [4 servings, 4.0 servings]",
        "yield: 4 servings\nyield: 4 servings"
    ])
    func dividesByADimensionStatedTwiceThatAgrees(header: String) throws {
        let scaled = try scaled(recipe(header), to: "8 servings")

        #expect(try flour(in: scaled) == 400.0)
        // The repetition is still reported; only the request was satisfiable.
        #expect(scaled.validate().map(\.kind) == [.repeatedYield])
    }

    @Test(arguments: [
        "servings: 4\nyield: 6 servings",
        "yield: [4 servings, 6 servings]",
        // A range and a single quantity are two statements that do not agree.
        "yield: [4 servings, 4-6 servings]"
    ])
    func refusesADimensionStatedTwiceThatDisagrees(header: String) {
        #expect(throws: ScalingError.conflictingYields) {
            try scaled(recipe(header), to: "8 servings")
        }
    }

    @Test
    func refusesANumberOfServingsWhenThePortionsDisagree() {
        let parsed = SousParser().parseRecipe(recipe("servings: 4\nyield: 6 servings")).value

        #expect(throws: ScalingError.conflictingYields) {
            try parsed.scaled(toServings: 8.0)
        }
    }

    // Only a request that has to divide by the dimension fails. A factor needs no divisor, so
    // it scales every statement of it as written.

    @Test
    func scalesByAFactorThroughADimensionThatDisagrees() throws {
        let parsed = SousParser().parseRecipe(recipe("servings: 4\nyield: 6 servings")).value

        let scaled = try parsed.scaled(by: 2.0)
        #expect(scaled.metadata["servings"] == "8")
        #expect(scaled.metadata.yields.map(\.text) == ["12 servings"])
    }

    // The guards report the first thing that stops the division, so a dimension stated twice
    // is a conflict before either statement is looked at as a divisor.

    @Test(arguments: [
        (header: "yield: [10-12 muffins, 10-12 muffins]", target: "18 muffins", error: ScalingError.noMatchingYield),
        (header: "yield: [0 g, 0 g]", target: "500 g", error: ScalingError.zeroYield),
        (header: "yield: [0 g, 5 g]", target: "500 g", error: ScalingError.conflictingYields)
    ])
    func reportsWhatStoppedTheDivision(header: String, target: String, error: ScalingError) {
        #expect(throws: error) {
            try scaled(recipe(header), to: target)
        }
    }

    // The target's unit normalizes the same way the yield's does, so the whitespace around
    // either of them is ignored.

    @Test
    func matchesAUnitThroughTheWhitespaceAroundTheTarget() throws {
        #expect(try flour(in: scaled(recipe("yield: 12 pancakes"), to: "18  pancakes")) == 300.0)
    }

    // A target has to state one quantity to be divided by too, so a range names a dimension it
    // cannot itself serve as the divisor for.

    @Test
    func refusesToDivideByAYieldThatStatesARange() {
        #expect(throws: ScalingError.noMatchingYield) {
            try scaled(recipe("yield: 10-12 muffins"), to: "18 muffins")
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
        let parsed = SousParser().parseRecipe(recipe("yield: 800 g")).value

        #expect(throws: ScalingError.noMatchingYield) {
            try parsed.scaled(toServings: 8.0)
        }
    }

    @Test
    func refusesANumberOfServingsWhenThePortionsStateARange() {
        let parsed = SousParser().parseRecipe(recipe("servings: 4-6")).value

        #expect(throws: ScalingError.noMatchingYield) {
            try parsed.scaled(toServings: 8.0)
        }
    }

    // A factor the target derives is refused on the same terms a stated one is.

    @Test
    func refusesATargetDerivingAFactorItCouldNotWriteBack() {
        let parser = SousParser()
        let parsed = parser.parseRecipe(recipe("yield: 800 g")).value
        let target = parser.parseAmount("1" + String(repeating: "0", count: 400) + " g")

        #expect(throws: ScalingError.unusableFactor) {
            try parsed.scaled(to: target)
        }
    }

    @Test
    func refusesZeroDeclaredServings() {
        let parsed = SousParser().parseRecipe(recipe("servings: 0")).value

        #expect(throws: ScalingError.zeroYield) {
            try parsed.scaled(toServings: 8.0)
        }
    }

    @Test(arguments: [-2.0, -0.0, Double.infinity, -Double.infinity, Double.nan])
    func refusesAServingsTargetItCouldNotWriteBack(servings: Double) {
        let parsed = SousParser().parseRecipe(recipe("servings: 4")).value

        #expect(throws: ScalingError.unusableFactor) {
            try parsed.scaled(toServings: servings)
        }
    }

    @Test
    func scalingToWhatIsAlreadyDeclaredChangesNothing() throws {
        let source = "---\nservings: 4\n---\n\nMix @{200g} flour@ and @{=1 tsp} salt@."
        let parsed = SousParser().parseRecipe(source).value

        #expect(try parsed.scaled(toServings: 4.0) == parsed)
    }

    @Test
    func aTargetOfZeroScalesToNothing() throws {
        let scaled = try SousParser().parseRecipe(recipe("servings: 4")).value.scaled(toServings: 0.0)

        #expect(try flour(in: scaled) == 0.0)
        #expect(scaled.metadata.servings == 0.0)
    }
}
