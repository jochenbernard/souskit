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
        // The marker stays in the amount's text, which is what writes it back.
        #expect(amount.text == "=1 tsp")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsTheMarkerBeforeARange() throws {
        let amount = try #require(Recipe.read("Add @{=1-2 tbsp} olive oil@.").firstAmount)
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
        let amount = try #require(Recipe.read("Stir in @{\(fence)} baking soda@.").firstAmount)
        #expect(amount.isFixed)
        #expect(amount.kind.preciseQuantity?.value == value)
        #expect(amount.unit == "tsp")
    }

    @Test
    func readsTheMarkerBeforeAQuantityWithNoUnit() throws {
        let amount = try #require(Recipe.read("Whisk @{=2} eggs@ into the batter.").firstAmount)
        #expect(amount.isFixed)
        #expect(amount.kind.preciseQuantity?.value == 2.0)
        #expect(amount.unit?.isEmpty == true)
    }

    @Test
    func anAmountWithoutTheMarkerIsNotFixed() {
        let amounts = Recipe.read("Mix @{200 g} flour@ and @{a pinch} salt@.").ingredients.compactMap(\.amount)
        #expect(amounts.count == 2)
        #expect(amounts.allSatisfy({ !$0.isFixed }))
    }

    // The marker is only meaningful immediately before a numeric quantity. Anywhere else it
    // is ordinary text of an imprecise amount, which is what leaves the fence readable.

    @Test(arguments: ["=a pinch", "= 1 tsp", "==1 tsp", "1 =tsp", "="])
    func doesNotFixAnAmountWhoseMarkerPrecedesNoQuantity(fence: String) throws {
        let amount = try #require(Recipe.read("Stir in @{\(fence)} baking soda@.").firstAmount)
        #expect(!amount.isFixed)
        #expect(amount.text == fence)
    }

    @Test
    func readsAMarkerThatPrecedesNoQuantityAsImpreciseText() throws {
        let amount = try #require(Recipe.read("Stir in @{=a pinch} baking soda@.").firstAmount)
        #expect(amount.kind.impreciseText == "=a pinch")
        #expect(amount.unit == nil)
    }

    @Test
    func keepsAMarkerAfterTheQuantityInTheUnit() throws {
        let amount = try #require(Recipe.read("Stir in @{1 =tsp} baking soda@.").firstAmount)
        #expect(amount.kind.preciseQuantity?.value == 1.0)
        #expect(amount.unit == "=tsp")
    }
}
