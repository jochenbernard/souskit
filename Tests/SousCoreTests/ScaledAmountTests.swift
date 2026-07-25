import SousCore
import Testing

// What a scaled amount is written back as. Scaling produces amounts nobody wrote, so the text
// they carry is built from the value rather than read from a source, and whatever it writes has
// to read back as the amount it states.

@Suite("Writing a scaled amount")
struct ScaledAmountTests {
    /// Whatever scaling writes has to read back as what it states, or the round-trip guarantee
    /// holds only for recipes nobody scaled.
    private func expectAScaledRecipeRoundTrips(
        _ source: String,
        by factor: Double,
        sourceLocation: Testing.SourceLocation = #_sourceLocation
    ) throws {
        let parser = SousParser()
        let scaled = try parser.parseRecipe(source).value.scaled(by: factor)
        let reRead = parser.parseRecipe(scaled.serialized())
        let note = Comment(rawValue: "\(source.debugDescription) scaled by \(factor)")

        #expect(reRead.value.metadata == scaled.metadata, note, sourceLocation: sourceLocation)
        #expect(
            reRead.value.steps.map(\.segments) == scaled.steps.map(\.segments),
            note,
            sourceLocation: sourceLocation
        )
        #expect(reRead.diagnostics.isEmpty, note, sourceLocation: sourceLocation)
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
        #expect(try SousParser().amount(in: "Add @{\(fence)} water@.", scaledBy: factor).text == text)
    }

    @Test
    func neverRoundsAScaledQuantity() throws {
        let amount = try SousParser().amount(in: "Add @{1/3 cup} water@.", scaledBy: 2.0)

        #expect(amount.kind.preciseQuantity?.value == 2.0 / 3.0)
        #expect(amount.text == "0.6666666666666666 cup")
    }

    // Regenerating writes one space between the quantity and the unit, whatever separated the
    // two where the amount was read, because the unit is trimmed of it.

    @Test(arguments: [
        (fence: "200g", text: "400 g"),
        (fence: "200  g", text: "400 g")
    ])
    func regeneratesTheSeparatorButNotTheUnit(fence: String, text: String) throws {
        #expect(try SousParser().amount(in: "Add @{\(fence)} water@.", scaledBy: 2.0).text == text)
    }

    // A value is written positionally whatever its magnitude, because the exponent notation
    // Swift reaches for at the extremes is not a quantity any reader reads back.

    @Test(arguments: [
        (factor: 0.00001, text: "0.00001 g"),
        (factor: 0.0000025, text: "0.0000025 g"),
        // The magnitude Swift starts writing an exponent at, so the first one to be moved.
        (factor: 1e16, text: "10000000000000000 g"),
        (factor: 1e20, text: "100000000000000000000 g"),
        (factor: 1.5e20, text: "150000000000000000000 g")
    ])
    func writesAScaledValuePositionallyAtEveryMagnitude(factor: Double, text: String) throws {
        #expect(try SousParser().amount(in: "Add @{1 g} water@.", scaledBy: factor).text == text)
    }

    @Test(arguments: [0.00001, 1e20])
    func aRecipeScaledToAnExtremeStillRoundTrips(factor: Double) throws {
        try expectAScaledRecipeRoundTrips("Add @{1 g} water@.", by: factor)
    }

    // A quantity holds as much as a number does, so a product that leaves that range is
    // refused rather than written as the text no reader reads back.

    @Test(arguments: [
        (digits: 308, factor: 10.0),
        (digits: 400, factor: 0.0)
    ])
    func refusesAProductItCouldNotWriteBack(digits: Int, factor: Double) {
        let recipe = Recipe.read("Add @{\(String.quantity(digits: digits)) g} water@.")

        #expect(throws: ScalingError.unwritableQuantity) {
            try recipe.scaled(by: factor)
        }
    }

    @Test
    func refusesAProductItCouldNotWriteBackInTheHeader() {
        let recipe = Recipe.read("---\nyield: \(String.quantity(digits: 400)) g\n---")

        #expect(throws: ScalingError.unwritableQuantity) {
            try recipe.scaled(by: 0.0)
        }
    }

    // A quantity already past that range states no product the factor moves it to, so scaling
    // leaves it exactly where it was.

    @Test
    func leavesAQuantityAlreadyPastThatRangeAlone() throws {
        let source = "Add @{\(String.quantity(digits: 400)) g} water@."

        #expect(try Recipe.read(source).scaled(by: 2.0).steps.first?.text == source)
    }

    // A whole quantity, one space, and a fraction is a mixed number, so an amount whose unit
    // opens a fraction states its quantity with a point no fraction can follow.

    @Test(arguments: [
        (fence: "1.5 1/2-cup servings", text: "3.0 1/2-cup servings"),
        (fence: "2.5 1/2", text: "5.0 1/2"),
        (fence: "0.5 2/3 cups", text: "1.0 2/3 cups"),
        (fence: "1-2.5 1/2", text: "2.0-5.0 1/2")
    ])
    func keepsAFractionUnitOutOfTheQuantityItFollows(fence: String, text: String) throws {
        let amount = try SousParser().amount(in: "Add @{\(fence)} water@.", scaledBy: 2.0)

        #expect(amount.text == text)
        #expect(amount.unit == String(fence.drop(while: { $0 != " " }).dropFirst()))
    }

    // The reading has to agree on the unit as well as on the values. A zero numerator adds
    // nothing, so the quantity still reads back as itself while the unit has moved into it.

    @Test
    func keepsAFractionUnitOutOfTheQuantityWhenTheValuesStillAgree() throws {
        let amount = try SousParser().amount(in: "Add @{1.5 0/2 cups} water@.", scaledBy: 2.0)

        #expect(amount.text == "3.0 0/2 cups")
        #expect(amount.unit == "0/2 cups")
    }

    // The point is added to a value that carries none, which is every value Swift writes with
    // an exponent, so an extreme factor and a fraction unit have to meet correctly.

    @Test
    func keepsAFractionUnitOutOfAQuantityAtAnExtremeMagnitude() throws {
        let amount = try SousParser().amount(in: "Add @{1.5 1/2-cup servings} water@.", scaledBy: 1e16)

        #expect(amount.text == "15000000000000000.0 1/2-cup servings")
        #expect(amount.unit == "1/2-cup servings")
    }

    // Both ends of a range are checked, so a range one end of which leaves the range a number
    // holds is refused like any other product.

    @Test
    func refusesARangeWithOneEndItCouldNotWriteBack() {
        let source = "Add @{1-\(String.quantity(digits: 308)) g} water@."
        let recipe = Recipe.read(source)

        #expect(throws: ScalingError.unwritableQuantity) {
            try recipe.scaled(by: 10.0)
        }
    }

    @Test
    func keepsAFractionUnitOutOfADeclaredYield() throws {
        let source = "---\nyield: [0.5 2/3 cups]\nservings: 0.5 1/2 batches\n---\n\nMix @{200 g} flour@."

        let recipe = try Recipe.read(source).scaled(by: 2.0)
        #expect(recipe.metadata.yields.map(\.text) == ["1.0 2/3 cups"])
        #expect(recipe.metadata.yields.compactMap(\.unit) == ["2/3 cups"])
        #expect(recipe.metadata["servings"] == "1.0 1/2 batches")
    }

    // Whatever scaling writes has to read back as what it states, over every amount form and
    // every factor, or the round-trip guarantee holds only for recipes nobody scaled.

    @Test(arguments: [
        "200 g", "1-2 tbsp", "=1 tsp", "a pinch", "2", "1/2 tsp", "1 1/2 cups", "0.5 kg",
        "200g", "200  g", "10-12", "1.5 1/2-cup servings", "2.5 1/2", "0.5 2/3 cups",
        "1-2.5 1/2", "200 g ", "1.5 1/2 "
    ], [0.0, 0.5, 1.0, 2.0, 3.0])
    func aScaledRecipeStillRoundTrips(fence: String, factor: Double) throws {
        try expectAScaledRecipeRoundTrips(
            "---\nservings: 4\nyield: [6 servings, 3.2 kg]\n---\n\nAdd @{\(fence)} water@.",
            by: factor
        )
    }
}
