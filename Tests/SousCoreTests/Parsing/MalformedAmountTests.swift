import SousCore
import Testing

@Suite("Malformed amounts")
struct MalformedAmountTests {
    @Test
    func usesOnlyADotAsTheDecimalPoint() throws {
        let amount = try #require(Recipe.read("Add @{3,2 kg} flour@.").firstAmount)

        #expect(amount.kind.impreciseText == "3,2 kg")
        #expect(amount.unit == nil)
    }

    @Test(arguments: ["1/0 tbsp", "1/0.0 tbsp"])
    func doesNotDivideByAZeroDenominator(fence: String) throws {
        let amount = try #require(Recipe.read("Add @{\(fence)} flour@.").firstAmount)

        #expect(amount.kind.impreciseText == fence)
        #expect(amount.unit == nil)
    }

    @Test
    func readsAMixedNumberWhoseFractionDividesByZeroAsTheWholeNumberAndItsUnit() throws {
        let amount = try #require(Recipe.read("Add @{1 1/0 tbsp} flour@.").firstAmount)

        #expect(amount.kind.preciseQuantity?.value == 1.0)
        #expect(amount.unit == "1/0 tbsp")
    }

    @Test(arguments: ["3. kg", "3.x"])
    func statesNoQuantityWhereADecimalPointHasNoDigitsAfterIt(fence: String) throws {
        let amount = try #require(Recipe.read("Add @{\(fence)} flour@.").firstAmount)

        #expect(amount.kind.impreciseText == fence)
        #expect(amount.unit == nil)
    }

    @Test(arguments: ["3,2 kg", "1,000 g", "3. kg", "1/0 tbsp", "1/x tbsp", ".5", ",5", "-2 tbsp"])
    func warnsAboutANumberAnAmountCannotFinish(fence: String) {
        let parsed = SousParser().parseRecipe("Add @{\(fence)} flour@.")

        #expect(parsed.value.firstAmount?.kind.impreciseText == fence)
        #expect(parsed.value.firstAmount?.isFixed == false)
        #expect(parsed.diagnostics.map(\.kind) == [.malformedQuantity])
    }

    @Test(arguments: [
        (
            fence: "3,2 kg",
            message: "Amount has a decimal point it cannot use; write a decimal as '.' between digits."
        ),
        (
            fence: " 3,2 kg ",
            message: "Amount has a decimal point it cannot use; write a decimal as '.' between digits."
        ),
        (fence: "1/0 tbsp", message: "Amount has a fraction with a missing or zero denominator."),
        (fence: ".5", message: "Amount opens as a number with no leading digit; write one, as in '0.5'.")
    ])
    func describesTheNumberAnAmountCannotFinish(fence: String, message: String) throws {
        let parsed = SousParser().parseRecipe("Add @{\(fence)} flour@.")

        #expect(try parsed.firstDiagnostic(ofKind: .malformedQuantity).message == message)
    }

    @Test(arguments: ["a pinch", "half", "to taste", "-", ".", ". a", ", a", "- a"])
    func readsAnImpreciseAmountStatingNoNumberWithoutReporting(fence: String) {
        let parsed = SousParser().parseRecipe("Add @{\(fence)} flour@.")

        #expect(parsed.value.firstAmount?.kind.impreciseText == fence)
        #expect(parsed.diagnostics.isEmpty)
    }
}
