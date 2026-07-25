import SousCore
import Testing

// An amount states nothing it cannot finish: where a number runs into a decimal point it
// cannot use, or into a fraction with no number other than zero under it, the amount states
// no quantity at all rather than the number standing before the defect. Reading it as one
// would scale a recipe by a figure nobody wrote.
//
// A text with no leading digit states no quantity either, which is no defect in itself, and
// one that opens as a number nonetheless states a number nowhere else. Each keeps its text as
// written, so the file stays usable and the author is told which spelling the language reads.

@Suite("Malformed amounts")
struct MalformedAmountTests {
    @Test
    func usesOnlyADotAsTheDecimalPoint() throws {
        // A comma states no decimal point, and the number before it is not what the author
        // meant either, so the amount states no quantity at all.
        let amount = try #require(Recipe.read("Add @{3,2 kg} flour@.").firstAmount)

        #expect(amount.kind.impreciseText == "3,2 kg")
        #expect(amount.unit == nil)
    }

    @Test(arguments: ["1/0 cup", "1/0.0 cup"])
    func doesNotDivideByAZeroDenominator(fence: String) throws {
        // The fraction states nothing to divide by, so the number before it states no quantity
        // either, rather than standing as one the author never wrote.
        let amount = try #require(Recipe.read("Add @{\(fence)} flour@.").firstAmount)

        #expect(amount.kind.impreciseText == fence)
        #expect(amount.unit == nil)
    }

    @Test
    func readsAMixedNumberWhoseFractionDividesByZeroAsTheWholeNumberAndItsUnit() throws {
        // The mixed form is optional, so the whole number stands on its own and the fraction
        // it could not use opens the unit, no number running into a defect of its own.
        let amount = try #require(Recipe.read("Add @{1 1/0 cup} flour@.").firstAmount)

        #expect(amount.kind.preciseQuantity?.value == 1.0)
        #expect(amount.unit == "1/0 cup")
    }

    @Test(arguments: ["3. kg", "3.x"])
    func statesNoQuantityWhereADecimalPointHasNoDigitsAfterIt(fence: String) throws {
        let amount = try #require(Recipe.read("Add @{\(fence)} flour@.").firstAmount)

        #expect(amount.kind.impreciseText == fence)
        #expect(amount.unit == nil)
    }

    // A quantity that runs into a decimal point it cannot use, or a fraction it cannot finish,
    // states no number at all rather than the number before it, so a wrong quantity never
    // scales. A text with no leading digit states none either, which is no defect in itself,
    // and one opening as a number nonetheless states a number nowhere else. Each is reported,
    // and each keeps its text as written.

    @Test(arguments: ["3,2 kg", "1,000 g", "3. kg", "1/0 cup", "1/x cup", ".5", ",5", "-2 tbsp"])
    func warnsAboutANumberAnAmountCannotFinish(fence: String) {
        let parsed = SousParser().parseRecipe("Add @{\(fence)} flour@.")

        #expect(parsed.value.firstAmount?.kind.impreciseText == fence)
        #expect(parsed.value.firstAmount?.isFixed == false)
        #expect(parsed.diagnostics.map(\.kind) == [.malformedQuantity])
    }

    @Test(arguments: ["a pinch", "half", "to taste", "-", "."])
    func readsAnImpreciseAmountStatingNoNumberWithoutReporting(fence: String) {
        let parsed = SousParser().parseRecipe("Add @{\(fence)} flour@.")

        #expect(parsed.value.firstAmount?.kind.impreciseText == fence)
        #expect(parsed.diagnostics.isEmpty)
    }
}
