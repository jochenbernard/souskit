import SousCore
import Testing

// Scaling by a factor, available since v0.3. Every amount either multiplies by the factor or
// does not move at all, and the header states what the scaled recipe now makes.

@Suite("Scaling by a factor")
struct ScalingTests {
    private func amount(in source: String, scaledBy factor: Double) throws -> Amount {
        let recipe = try SousParser().parseRecipe(source).value.scaled(by: factor)

        return try #require(recipe.ingredients.first?.amount)
    }

    @Test
    func multipliesAPreciseAmount() throws {
        let amount = try amount(in: "Mix @{200 g} flour@.", scaledBy: 1.5)

        #expect(amount.kind.preciseQuantity?.value == 300.0)
        #expect(amount.kind.preciseQuantity?.text == "300")
        #expect(amount.unit == "g")
        #expect(amount.text == "300 g")
    }

    @Test
    func multipliesBothEndsOfARange() throws {
        let amount = try amount(in: "Add @{1-2 tbsp} oil@.", scaledBy: 2.0)

        #expect(amount.kind.rangeQuantities?.low.value == 2.0)
        #expect(amount.kind.rangeQuantities?.high.value == 4.0)
        #expect(amount.text == "2-4 tbsp")
    }

    // A fixed, imprecise, or absent amount states nothing to multiply, so a scaled recipe is
    // not a strict multiple of the original.

    @Test
    func leavesAFixedAmountUnchanged() throws {
        let amount = try amount(in: "Stir in @{=1 tsp} salt@.", scaledBy: 2.0)

        #expect(amount.isFixed)
        #expect(amount.kind.preciseQuantity?.value == 1.0)
        #expect(amount.text == "=1 tsp")
    }

    @Test
    func leavesAnImpreciseAmountUnchanged() throws {
        let amount = try amount(in: "Stir in @{a pinch} salt@.", scaledBy: 2.0)

        #expect(amount.kind.impreciseText == "a pinch")
        #expect(amount.text == "a pinch")
    }

    @Test
    func leavesAnAbsentAmountAbsent() throws {
        let recipe = try SousParser().parseRecipe("Season with @salt@.").value.scaled(by: 2.0)

        #expect(recipe.ingredients.first?.amount == nil)
    }

    @Test
    func neverScalesATimer() throws {
        let recipe = try SousParser().parseRecipe("Bake for ~40 min~.").value.scaled(by: 2.0)

        let timer = try #require(recipe.timers.first)
        #expect(timer.text == "40 min")
        #expect(timer.components.first?.kind.preciseQuantity?.value == 40.0)
    }

    // The regenerated text holds the exact value. An integral one carries no decimal point,
    // and nothing is ever rounded.

    @Test(arguments: [
        (fence: "200 g", factor: 1.5, text: "300 g"),
        (fence: "1/2 tsp", factor: 3.0, text: "1.5 tsp"),
        (fence: "1 1/2 cups", factor: 2.0, text: "3 cups"),
        (fence: "0.5 kg", factor: 4.0, text: "2 kg"),
        (fence: "2", factor: 2.0, text: "4"),
        (fence: "1-2 tbsp", factor: 2.0, text: "2-4 tbsp"),
        (fence: "200 g", factor: 0.0, text: "0 g"),
        (fence: "3 g", factor: 0.5, text: "1.5 g")
    ])
    func regeneratesTheTextOfAScaledAmount(fence: String, factor: Double, text: String) throws {
        #expect(try amount(in: "Add @{\(fence)} water@.", scaledBy: factor).text == text)
    }

    @Test
    func neverRoundsAScaledQuantity() throws {
        let amount = try amount(in: "Add @{1/3 cup} water@.", scaledBy: 2.0)

        #expect(amount.kind.preciseQuantity?.value == 2.0 / 3.0)
        #expect(amount.text == "0.6666666666666666 cup")
    }

    // Regenerating writes one space between the quantity and the unit, and the unit itself is
    // whatever followed that one space, so spacing beyond it survives.

    @Test(arguments: [
        (fence: "200g", text: "400 g"),
        (fence: "200  g", text: "400  g")
    ])
    func regeneratesTheSeparatorButNotTheUnit(fence: String, text: String) throws {
        #expect(try amount(in: "Add @{\(fence)} water@.", scaledBy: 2.0).text == text)
    }

    // The declared yield and servings scale with the amounts, so the header still states what
    // the recipe makes.

    @Test
    func scalesTheDeclaredServings() throws {
        let source = "---\nservings: 4\n---\n\nMix @{200 g} flour@."

        let recipe = try SousParser().parseRecipe(source).value.scaled(by: 1.5)
        #expect(recipe.metadata.servings == 6.0)
        #expect(recipe.metadata["servings"] == "6")
    }

    @Test
    func scalesEveryDeclaredYield() throws {
        let source = "---\nyield: [6 servings, 3.2 kg]\n---\n\nMix @{200 g} flour@."

        let recipe = try SousParser().parseRecipe(source).value.scaled(by: 2.0)
        #expect(recipe.metadata.yields.map(\.text) == ["12 servings", "6.4 kg"])
    }

    @Test
    func scalesAServingsValueThatCarriesAUnit() throws {
        let recipe = try SousParser().parseRecipe("---\nservings: 6 people\n---").value.scaled(by: 2.0)

        #expect(recipe.metadata["servings"] == "12 people")
    }

    // Only the two fields stating how much the recipe makes move. A number anywhere else in
    // the header states something scaling has no business multiplying.

    @Test
    func leavesEveryFieldButTheYieldAndTheServingsAlone() throws {
        let source = "---\nversion: 1.0\ntitle: 3 Bean Stew\ncalories: 640\ntags: [4 star]\n---"

        let recipe = try SousParser().parseRecipe(source).value.scaled(by: 2.0)
        #expect(recipe.metadata.version == "1.0")
        #expect(recipe.metadata.title == "3 Bean Stew")
        #expect(recipe.metadata["calories"] == "640")
        #expect(recipe.metadata.tags == ["4 star"])
    }

    // A value is written positionally whatever its magnitude, because the exponent notation
    // Swift reaches for at the extremes is not a quantity any reader reads back.

    @Test(arguments: [
        (factor: 0.00001, text: "0.00001 g"),
        (factor: 0.0000025, text: "0.0000025 g"),
        (factor: 1e20, text: "100000000000000000000 g"),
        (factor: 1.5e20, text: "150000000000000000000 g")
    ])
    func writesAScaledValuePositionallyAtEveryMagnitude(factor: Double, text: String) throws {
        #expect(try amount(in: "Add @{1 g} water@.", scaledBy: factor).text == text)
    }

    @Test(arguments: [0.00001, 1e20])
    func aRecipeScaledToAnExtremeStillRoundTrips(factor: Double) throws {
        let parser = SousParser()

        let scaled = try parser.parseRecipe("Add @{1 g} water@.").value.scaled(by: factor)
        let reRead = parser.parseRecipe(scaled.serialized())

        #expect(reRead.value.steps.map(\.segments) == scaled.steps.map(\.segments))
        #expect(reRead.diagnostics.isEmpty)
    }

    @Test
    func leavesAHeaderValueWithNoQuantityAlone() throws {
        let source = "---\nservings: six\nyield: plenty\ntitle: Stew\n---"

        let recipe = try SousParser().parseRecipe(source).value.scaled(by: 2.0)
        #expect(recipe.metadata["servings"] == "six")
        #expect(recipe.metadata.yields.map(\.text) == ["plenty"])
        #expect(recipe.metadata.title == "Stew")
    }

    // A step is rewritten only where an amount actually moved, so untouched prose keeps the
    // spacing it was read with.

    @Test
    func rewritesTheTextOfAStepItChanged() throws {
        let source = "Mix @{200 g} flour@ and @{a pinch} salt@."

        let recipe = try SousParser().parseRecipe(source).value.scaled(by: 2.0)
        #expect(recipe.steps.first?.text == "Mix @{400 g} flour@ and @{a pinch} salt@.")
    }

    @Test
    func keepsTheTextOfAStepItDidNotChange() throws {
        let source = "Toast the @bread@  slowly with @{=1 tsp} butter@."

        let recipe = try SousParser().parseRecipe(source).value.scaled(by: 2.0)
        #expect(recipe.steps.first?.text == source)
    }

    // A factor of one moves no value, so it rewrites nothing at all: the recipe that comes
    // back is the recipe that went in, incidental spacing included.

    @Test
    func scalingByOneChangesNothing() throws {
        let source = """
        ---
        servings: 4
        yield: [6 servings, 3.2 kg]
        ---

        Mix @{200g} flour@, @{1-2 tbsp} oil@, and @{=1 tsp} salt@ for ~40 min~.
        """

        let recipe = SousParser().parseRecipe(source).value
        #expect(try recipe.scaled(by: 1.0) == recipe)
    }

    // A factor a scaled amount could not be written back from is refused, so scaling never
    // produces a recipe that fails to read as itself.

    @Test(arguments: [-1.0, -0.5, Double.infinity, -Double.infinity, Double.nan])
    func refusesAFactorItCouldNotWriteBack(factor: Double) {
        let recipe = SousParser().parseRecipe("Mix @{200 g} flour@.").value

        #expect(throws: ScalingError.unusableFactor) {
            try recipe.scaled(by: factor)
        }
    }

    @Test
    func scalingByZeroIsAllowed() throws {
        #expect(try amount(in: "Mix @{200 g} flour@.", scaledBy: 0.0).kind.preciseQuantity?.value == 0.0)
    }

    // Whatever scaling writes has to read back as what it states, over every amount form and
    // every factor, or the round-trip guarantee holds only for recipes nobody scaled.

    @Test(arguments: [
        "200 g", "1-2 tbsp", "=1 tsp", "a pinch", "2", "1/2 tsp", "1 1/2 cups", "0.5 kg",
        "200g", "200  g", "10-12"
    ], [0.0, 0.5, 1.0, 2.0, 3.0])
    func aScaledRecipeStillRoundTrips(fence: String, factor: Double) throws {
        let parser = SousParser()
        let source = "---\nservings: 4\nyield: [6 servings, 3.2 kg]\n---\n\nAdd @{\(fence)} water@."

        let scaled = try parser.parseRecipe(source).value.scaled(by: factor)
        let reRead = parser.parseRecipe(scaled.serialized())

        #expect(reRead.value.metadata == scaled.metadata, "\(fence) scaled by \(factor)")
        #expect(reRead.value.steps.map(\.segments) == scaled.steps.map(\.segments), "\(fence) scaled by \(factor)")
        #expect(reRead.diagnostics.isEmpty, "\(fence) scaled by \(factor)")
    }
}
