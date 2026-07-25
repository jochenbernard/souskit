import SousCore
import Testing

@Suite("Fixed amounts")
struct FixedAmountTests {
    @Test
    func readsTheMarkerBeforeAPreciseQuantity() throws {
        let parsed = SousParser().parseRecipe("Stir in @{=1 tsp} baking soda@.")

        let amount = try #require(parsed.value.firstAmount)
        #expect(amount.isFixed)
        #expect(amount.kind.preciseQuantity?.value == 1.0)
        #expect(amount.kind.preciseQuantity?.text == "1")
        #expect(amount.unit == "tsp")
        // The marker states that the amount is fixed rather than what it is, so the text is
        // the amount's own and the writer puts the marker back from the property it set.
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

    // The marker opens the fence and fixes whatever the amount states, so the whitespace
    // between the two separates them and belongs to neither, as whitespace does everywhere.

    @Test(arguments: ["= 1 tsp", "=  1 tsp", "=\t1 tsp"])
    func readsTheMarkerWhateverSeparatesItFromTheAmount(fence: String) throws {
        let amount = try #require(Recipe.read("Stir in @{\(fence)} baking soda@.").firstAmount)

        #expect(amount.isFixed)
        #expect(amount.kind.preciseQuantity?.value == 1.0)
        #expect(amount.unit == "tsp")
        #expect(amount.text == "1 tsp")
    }

    // An imprecise amount states what an author wrote rather than a number, and the marker
    // states that it holds still, so the two compose like any other amount and marker.

    @Test(arguments: [
        (fence: "=a pinch", text: "a pinch"),
        (fence: "= a pinch", text: "a pinch"),
        (fence: "==1 tsp", text: "=1 tsp"),
        (fence: "=", text: "")
    ])
    func readsTheMarkerBeforeAnImpreciseAmount(fence: String, text: String) throws {
        let amount = try #require(Recipe.read("Stir in @{\(fence)} baking soda@.").firstAmount)

        #expect(amount.isFixed)
        #expect(amount.kind.impreciseText == text)
        #expect(amount.unit == nil)
        #expect(amount.text == text)
    }

    // Only the marker the content opens with is one, because it states something about the
    // whole amount rather than about a part of it.

    @Test(arguments: ["1 =tsp", "a =pinch"])
    func fixesNoAmountWhoseMarkerOpensNothing(fence: String) throws {
        let amount = try #require(Recipe.read("Stir in @{\(fence)} baking soda@.").firstAmount)

        #expect(!amount.isFixed)
        #expect(amount.text == fence)
    }

    // Reading takes the marker out of the text into the amount, so writing puts it back from
    // there, and an amount a mutation fixes is written fixed.

    @Test(arguments: [
        (source: "Stir in @{= 1 tsp} soda@.", written: "Stir in @{=1 tsp} soda@."),
        (source: "Stir in @{=a pinch} soda@.", written: "Stir in @{=a pinch} soda@."),
        (source: "Stir in @{==1 tsp} soda@.", written: "Stir in @{==1 tsp} soda@.")
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
        // The marker states that the amount holds still, which it does whether or not the
        // amount states a number, so the two are read and reported independently.
        let parsed = SousParser().parseRecipe("Stir in @{=3,2 kg} flour@.")

        #expect(parsed.value.firstAmount?.isFixed == true)
        #expect(parsed.value.firstAmount?.kind.impreciseText == "3,2 kg")
        #expect(parsed.diagnostics.map(\.kind) == [.malformedQuantity])
    }

    @Test
    func keepsAMarkerAfterTheQuantityInTheUnit() throws {
        let amount = try #require(Recipe.read("Stir in @{1 =tsp} baking soda@.").firstAmount)
        #expect(amount.kind.preciseQuantity?.value == 1.0)
        #expect(amount.unit == "=tsp")
    }
}
