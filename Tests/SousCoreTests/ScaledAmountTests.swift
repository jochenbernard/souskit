import SousCore
import Testing

@Suite("Writing a scaled amount")
struct ScaledAmountTests {
    /// Expects a scaled recipe to serialize and read back unchanged, with no diagnostics.
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

    @Test(arguments: [
        (fence: "200g", text: "400 g"),
        (fence: "200  g", text: "400 g")
    ])
    func regeneratesTheSeparatorButNotTheUnit(fence: String, text: String) throws {
        #expect(try SousParser().amount(in: "Add @{\(fence)} water@.", scaledBy: 2.0).text == text)
    }

    @Test(arguments: [
        (factor: 0.00001, text: "0.00001 g"),
        (factor: 0.0000025, text: "0.0000025 g"),
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

    @Test
    func leavesAQuantityAlreadyPastThatRangeAlone() throws {
        let source = "Add @{\(String.quantity(digits: 400)) g} water@."

        #expect(try Recipe.read(source).scaled(by: 2.0).steps.first?.text == source)
    }

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

    @Test
    func keepsAFractionUnitOutOfTheQuantityWhenTheValuesStillAgree() throws {
        let amount = try SousParser().amount(in: "Add @{1.5 0/2 cups} water@.", scaledBy: 2.0)

        #expect(amount.text == "3.0 0/2 cups")
        #expect(amount.unit == "0/2 cups")
    }

    @Test
    func keepsAFractionUnitOutOfAQuantityAtAnExtremeMagnitude() throws {
        let amount = try SousParser().amount(in: "Add @{1.5 1/2-cup servings} water@.", scaledBy: 1e16)

        #expect(amount.text == "15000000000000000.0 1/2-cup servings")
        #expect(amount.unit == "1/2-cup servings")
    }

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
