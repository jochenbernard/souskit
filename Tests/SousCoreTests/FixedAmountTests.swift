import SousCore
import Testing

@Suite("Fixed amounts")
struct FixedAmountTests {
    @Test
    func readsTheMarkerBeforeAPreciseQuantity() throws {
        let parsed = SousParser().parseRecipe("Stir in @{=1 tsp} baking soda@.")

        let amount = try #require(parsed.value.ingredients.first?.amount)
        #expect(amount.isFixed)
        #expect(amount.kind.preciseQuantity?.value == 1.0)
        #expect(amount.kind.preciseQuantity?.text == "1")
        #expect(amount.unit == "tsp")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsTheMarkerBeforeARange() throws {
        let parsed = SousParser().parseRecipe("Add @{=1-2 tbsp} olive oil@.")

        let amount = try #require(parsed.value.ingredients.first?.amount)
        #expect(amount.isFixed)
        #expect(amount.kind.rangeQuantities?.low.value == 1.0)
        #expect(amount.kind.rangeQuantities?.high.value == 2.0)
        #expect(amount.unit == "tbsp")
    }

    @Test(arguments: [
        (fence: "=1/2 tsp", value: 0.5),
        (fence: "=1 1/2 tsp", value: 1.5),
        (fence: "=0.5 tsp", value: 0.5)
    ])
    func readsTheMarkerBeforeEveryQuantityForm(fence: String, value: Double) throws {
        let parsed = SousParser().parseRecipe("Stir in @{\(fence)} baking soda@.")

        let amount = try #require(parsed.value.ingredients.first?.amount)
        #expect(amount.isFixed)
        #expect(amount.kind.preciseQuantity?.value == value)
        #expect(amount.unit == "tsp")
    }

    @Test
    func readsTheMarkerBeforeAQuantityWithNoUnit() throws {
        let parsed = SousParser().parseRecipe("Whisk @{=2} eggs@ into the batter.")

        let amount = try #require(parsed.value.ingredients.first?.amount)
        #expect(amount.isFixed)
        #expect(amount.kind.preciseQuantity?.value == 2.0)
        #expect(amount.unit?.isEmpty == true)
    }

    @Test
    func keepsTheMarkerInTheAmountText() throws {
        let parsed = SousParser().parseRecipe("Stir in @{=1 tsp} baking soda@.")

        let amount = try #require(parsed.value.ingredients.first?.amount)
        #expect(amount.text == "=1 tsp")
    }

    @Test
    func anAmountWithoutTheMarkerIsNotFixed() {
        let parsed = SousParser().parseRecipe("Mix @{200 g} flour@ and @{a pinch} salt@.")

        let amounts = parsed.value.ingredients.compactMap(\.amount)
        #expect(amounts.count == 2)
        #expect(amounts.allSatisfy({ !$0.isFixed }))
    }

    // The marker is only meaningful immediately before a numeric quantity. Anywhere else it
    // is ordinary text of an imprecise amount, which is what leaves the fence readable.

    @Test(arguments: ["=a pinch", "= 1 tsp", "==1 tsp", "1 =tsp", "="])
    func doesNotFixAnAmountWhoseMarkerPrecedesNoQuantity(fence: String) throws {
        let parsed = SousParser().parseRecipe("Stir in @{\(fence)} baking soda@.")

        let amount = try #require(parsed.value.ingredients.first?.amount)
        #expect(!amount.isFixed)
        #expect(amount.text == fence)
    }

    @Test
    func readsAMarkerThatPrecedesNoQuantityAsImpreciseText() throws {
        let parsed = SousParser().parseRecipe("Stir in @{=a pinch} baking soda@.")

        let amount = try #require(parsed.value.ingredients.first?.amount)
        #expect(amount.kind.impreciseText == "=a pinch")
        #expect(amount.unit == nil)
    }

    @Test
    func keepsAMarkerAfterTheQuantityInTheUnit() throws {
        let parsed = SousParser().parseRecipe("Stir in @{1 =tsp} baking soda@.")

        let amount = try #require(parsed.value.ingredients.first?.amount)
        #expect(amount.kind.preciseQuantity?.value == 1.0)
        #expect(amount.unit == "=tsp")
    }
}
