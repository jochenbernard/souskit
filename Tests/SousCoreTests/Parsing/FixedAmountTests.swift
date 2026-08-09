import SousCore
import Testing

@Suite("Fixed amounts")
struct FixedAmountTests {
    @Test
    func readsTheMarkerBeforeAPreciseQuantity() throws {
        let parsed = SousParser().parseRecipe("Stir in @{=1 tsp} nutmeg@.")

        let amount = try #require(parsed.value.firstAmount)
        #expect(amount.isFixed)
        #expect(amount.kind.preciseQuantity?.value == 1.0)
        #expect(amount.kind.preciseQuantity?.text == "1")
        #expect(amount.unit == "tsp")
        #expect(amount.text == "1 tsp")
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
        let amount = try #require(Recipe.read("Stir in @{\(fence)} nutmeg@.").firstAmount)
        #expect(amount.isFixed)
        #expect(amount.kind.preciseQuantity?.value == value)
        #expect(amount.unit == "tsp")
    }

    @Test
    func readsTheMarkerBeforeAQuantityWithNoUnit() throws {
        let amount = try #require(Recipe.read("Whisk @{=2} eggs@ into the batter.").firstAmount)
        #expect(amount.isFixed)
        #expect(amount.kind.preciseQuantity?.value == 2.0)
        #expect(amount.unit == nil)
    }

    @Test
    func anAmountWithoutTheMarkerIsNotFixed() {
        let amounts = Recipe.read("Mix @{200 g} flour@ and @{a pinch} salt@.").ingredients.compactMap(\.amount)
        #expect(amounts.count == 2)
        #expect(amounts.allSatisfy({ !$0.isFixed }))
    }

    @Test(arguments: ["= 1 tsp", "=  1 tsp", "=\t1 tsp"])
    func readsTheMarkerWhateverSeparatesItFromTheAmount(fence: String) throws {
        let amount = try #require(Recipe.read("Stir in @{\(fence)} nutmeg@.").firstAmount)

        #expect(amount.isFixed)
        #expect(amount.kind.preciseQuantity?.value == 1.0)
        #expect(amount.unit == "tsp")
        #expect(amount.text == "1 tsp")
    }

    @Test(arguments: [
        (fence: "=a pinch", text: "a pinch"),
        (fence: "= a pinch", text: "a pinch"),
        (fence: "==1 tsp", text: "=1 tsp"),
        (fence: "=", text: "")
    ])
    func readsTheMarkerBeforeAnImpreciseAmount(fence: String, text: String) throws {
        let amount = try #require(Recipe.read("Stir in @{\(fence)} nutmeg@.").firstAmount)

        #expect(amount.isFixed)
        #expect(amount.kind.impreciseText == text)
        #expect(amount.unit == nil)
        #expect(amount.text == text)
    }

    @Test(arguments: ["1 =tsp", "a =pinch"])
    func fixesNoAmountWhoseMarkerOpensNothing(fence: String) throws {
        let amount = try #require(Recipe.read("Stir in @{\(fence)} nutmeg@.").firstAmount)

        #expect(!amount.isFixed)
        #expect(amount.text == fence)
    }

    @Test(arguments: [
        (source: "Stir in @{= 1 tsp} nutmeg@.", written: "Stir in @{=1 tsp} nutmeg@."),
        (source: "Stir in @{=a pinch} nutmeg@.", written: "Stir in @{=a pinch} nutmeg@."),
        (source: "Stir in @{==1 tsp} nutmeg@.", written: "Stir in @{==1 tsp} nutmeg@.")
    ])
    func writesTheMarkerBackFromTheAmountItFixed(source: String, written: String) {
        #expect(Recipe.read(source).serialized() == written)
    }

    @Test
    func writesTheMarkerAMutationStates() throws {
        var value = Recipe.read("Add @{200 g} salt@ now.")
        var ingredient = try #require(value.ingredients.first)
        ingredient.amount?.isFixed = true
        value.groups[0].steps[0].segments[1] = .ingredient(ingredient)

        #expect(value.serialized() == "Add @{=200 g} salt@ now.")
        #expect(value.reRead().ingredients.first?.amount?.isFixed == true)
    }

    @Test
    func warnsAboutANumberAFixedAmountCannotFinish() {
        let parsed = SousParser().parseRecipe("Stir in @{=3,2 kg} flour@.")

        #expect(parsed.value.firstAmount?.isFixed == true)
        #expect(parsed.value.firstAmount?.kind.impreciseText == "3,2 kg")
        #expect(parsed.diagnostics.map(\.kind) == [.malformedQuantity])
    }

    @Test
    func keepsAMarkerAfterTheQuantityInTheUnit() throws {
        let amount = try #require(Recipe.read("Stir in @{1 =tsp} nutmeg@.").firstAmount)
        #expect(amount.kind.preciseQuantity?.value == 1.0)
        #expect(amount.unit == "=tsp")
    }
}
