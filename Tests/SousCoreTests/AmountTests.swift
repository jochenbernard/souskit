import SousCore
import Testing

@Suite("Amounts")
struct AmountTests {
    @Test(arguments: [
        (source: "Cook @{200 g} pasta@.", value: 200.0, text: "200", unit: "g"),
        (source: "Add @{2 cloves} garlic@.", value: 2.0, text: "2", unit: "cloves"),
        (source: "Mix @{1 1/2 cups} flour@.", value: 1.5, text: "1 1/2", unit: "cups"),
        (source: "Add @{1/2 cup} sugar@.", value: 0.5, text: "1/2", unit: "cup"),
        (source: "Pour @{2 fl oz} milk@.", value: 2.0, text: "2", unit: "fl oz"),
        (source: "Add @{3.2 kg} potatoes@.", value: 3.2, text: "3.2", unit: "kg")
    ])
    func parsesAPreciseAmount(
        source: String,
        value: Double,
        text: String,
        unit: String
    ) throws {
        let parsed = SousParser().parseRecipe(source)

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == value)
        #expect(quantity.text == text)
        #expect(amount.unit == unit)
    }

    @Test
    func parsesARangeAmount() throws {
        let parsed = SousParser().parseRecipe("Add @{1-2 tbsp} olive oil@.")

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        let range = try #require(amount.kind.rangeQuantities)
        #expect(range.low.value == 1.0)
        #expect(range.low.text == "1")
        #expect(range.high.value == 2.0)
        #expect(range.high.text == "2")
        #expect(amount.unit == "tbsp")
    }

    @Test
    func parsesAnImpreciseAmount() throws {
        let parsed = SousParser().parseRecipe("Add @{a pinch} salt@.")

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        #expect(amount.kind.impreciseText == "a pinch")
        #expect(amount.unit == nil)
    }

    @Test
    func treatsAnAmountWithNoLeadingNumberAsImprecise() throws {
        let parsed = SousParser().parseRecipe("Loosen with @{-2 tbsp} water@.")

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        #expect(amount.kind.impreciseText == "-2 tbsp")
        #expect(amount.unit == nil)
    }

    @Test
    func usesOnlyADotAsTheDecimalPoint() throws {
        let parsed = SousParser().parseRecipe("Add @{3,2 kg} flour@.")

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == 3.0)
        #expect(quantity.text == "3")
        #expect(amount.unit == ",2 kg")
    }

    @Test
    func treatsAZeroQuantityAsPrecise() throws {
        let parsed = SousParser().parseRecipe("Add @{0} yeast@.")

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        let quantity = try #require(amount.kind.preciseQuantity)
        let unit = try #require(amount.unit)
        #expect(quantity.value == 0.0)
        #expect(unit.isEmpty)
    }

    @Test
    func allowsAQuantityWithNoUnit() throws {
        let parsed = SousParser().parseRecipe("Whisk @{3} eggs@.")

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        let quantity = try #require(amount.kind.preciseQuantity)
        let unit = try #require(amount.unit)
        #expect(quantity.value == 3.0)
        #expect(unit.isEmpty)
    }

    @Test
    func keepsOtherSigilsInertInsideAFence() throws {
        let parsed = SousParser().parseRecipe("Add @{>500 g} flour@.")

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        #expect(amount.kind.impreciseText == ">500 g")
        #expect(amount.unit == nil)
    }

    @Test
    func doesNotDivideByAZeroDenominator() throws {
        let parsed = SousParser().parseRecipe("Add @{1/0 cup} flour@.")

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == 1.0)
        #expect(quantity.text == "1")
        #expect(amount.unit == "/0 cup")
    }

    @Test
    func doesNotDivideByAZeroDenominatorInAMixedNumber() throws {
        let parsed = SousParser().parseRecipe("Add @{1 1/0 cup} flour@.")

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == 1.0)
        #expect(quantity.text == "1")
        #expect(amount.unit == "1/0 cup")
    }

    @Test
    func parsesAFractionWithADecimalNumerator() throws {
        let parsed = SousParser().parseRecipe("Add @{1.5/2 cups} milk@.")

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == 0.75)
        #expect(quantity.text == "1.5/2")
        #expect(amount.unit == "cups")
    }

    @Test
    func parsesAFractionWithNoUnit() throws {
        let parsed = SousParser().parseRecipe("Use @{2/4} lemon@.")

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        let quantity = try #require(amount.kind.preciseQuantity)
        let unit = try #require(amount.unit)
        #expect(quantity.value == 0.5)
        #expect(quantity.text == "2/4")
        #expect(unit.isEmpty)
    }

    @Test(arguments: [
        (source: "Add @{1-2} olive oil@.", low: 1.0, high: 2.0, unit: ""),
        (source: "Add @{0.5-1.5 cups} milk@.", low: 0.5, high: 1.5, unit: "cups"),
        (source: "Add @{1/2-1 cup} water@.", low: 0.5, high: 1.0, unit: "cup")
    ])
    func parsesARangeOfEveryQuantityForm(source: String, low: Double, high: Double, unit: String) throws {
        let parsed = SousParser().parseRecipe(source)

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        let range = try #require(amount.kind.rangeQuantities)
        #expect(range.low.value == low)
        #expect(range.high.value == high)
        #expect(amount.unit == unit)
    }

    @Test
    func parsesARangeThatStartsWithAMixedNumber() throws {
        let parsed = SousParser().parseRecipe("Add @{1 1/2-2 cups} flour@.")

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        let range = try #require(amount.kind.rangeQuantities)
        #expect(range.low.value == 1.5)
        #expect(range.low.text == "1 1/2")
        #expect(range.high.value == 2.0)
        #expect(range.high.text == "2")
        #expect(amount.unit == "cups")
    }

    @Test
    func treatsAHyphenWithNoFollowingNumberAsPartOfTheUnit() throws {
        let parsed = SousParser().parseRecipe("Add @{1- 2 tbsp} olive oil@.")

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == 1.0)
        #expect(amount.unit == "- 2 tbsp")
    }

    @Test(arguments: [
        (source: "Add @{3. kg} flour@.", unit: ". kg"),
        (source: "Add @{3.x} flour@.", unit: ".x")
    ])
    func stopsTheQuantityAtADecimalPointWithNoDigitsAfterIt(source: String, unit: String) throws {
        let parsed = SousParser().parseRecipe(source)

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == 3.0)
        #expect(quantity.text == "3")
        #expect(amount.unit == unit)
    }

    @Test
    func keepsAnyExtraSpaceBeforeTheUnitInTheUnit() throws {
        // A single space separates the quantity from the unit; a second one is unit text.
        let parsed = SousParser().parseRecipe("Add @{200  g} flour@.")

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        #expect(amount.unit == " g")
    }

    @Test
    func readsAnEmptyFenceAsAnEmptyImpreciseAmount() throws {
        let parsed = SousParser().parseRecipe("Add @{} salt@.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        let amount = try #require(ingredient.amount)
        #expect(ingredient.name == "salt")
        #expect(amount.kind.impreciseText?.isEmpty == true)
        #expect(amount.unit == nil)
    }

    @Test
    func capturesTheVerbatimFenceContentAsText() throws {
        let parsed = SousParser().parseRecipe("Cook @{200 g} pasta@.")

        let amount = try #require(parsed.value.steps.first?.ingredients.first?.amount)
        #expect(amount.text == "200 g")
    }
}
