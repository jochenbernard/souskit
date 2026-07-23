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
        let amount = try #require(Recipe.read(source).firstAmount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == value)
        #expect(quantity.text == text)
        #expect(amount.unit == unit)
    }

    @Test
    func parsesARangeAmount() throws {
        let amount = try #require(Recipe.read("Add @{1-2 tbsp} olive oil@.").firstAmount)
        let range = try #require(amount.kind.rangeQuantities)
        #expect(range.low.value == 1.0)
        #expect(range.low.text == "1")
        #expect(range.high.value == 2.0)
        #expect(range.high.text == "2")
        #expect(amount.unit == "tbsp")
    }

    @Test
    func parsesAnImpreciseAmount() throws {
        let amount = try #require(Recipe.read("Add @{a pinch} salt@.").firstAmount)
        #expect(amount.kind.impreciseText == "a pinch")
        #expect(amount.unit == nil)
    }

    @Test
    func treatsAnAmountWithNoLeadingNumberAsImprecise() throws {
        let amount = try #require(Recipe.read("Loosen with @{-2 tbsp} water@.").firstAmount)
        #expect(amount.kind.impreciseText == "-2 tbsp")
        #expect(amount.unit == nil)
    }

    // The quantity is built from the digits 0 to 9, so a numeral outside that set leaves the
    // fence with no leading number.
    @Test(arguments: ["\u{0663}", "\u{FF13}"])
    func treatsANonAsciiNumeralAsImprecise(digit: String) throws {
        let amount = try #require(Recipe.read("Add @{\(digit) g} sugar@.").firstAmount)
        #expect(amount.kind.impreciseText == "\(digit) g")
        #expect(amount.unit == nil)
    }

    @Test
    func usesOnlyADotAsTheDecimalPoint() throws {
        let amount = try #require(Recipe.read("Add @{3,2 kg} flour@.").firstAmount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == 3.0)
        #expect(quantity.text == "3")
        #expect(amount.unit == ",2 kg")
    }

    @Test
    func treatsAZeroQuantityAsPrecise() throws {
        let amount = try #require(Recipe.read("Add @{0} yeast@.").firstAmount)
        let quantity = try #require(amount.kind.preciseQuantity)
        let unit = try #require(amount.unit)
        #expect(quantity.value == 0.0)
        #expect(unit.isEmpty)
    }

    @Test
    func allowsAQuantityWithNoUnit() throws {
        let amount = try #require(Recipe.read("Whisk @{3} eggs@.").firstAmount)
        let quantity = try #require(amount.kind.preciseQuantity)
        let unit = try #require(amount.unit)
        #expect(quantity.value == 3.0)
        #expect(unit.isEmpty)
    }

    @Test
    func keepsOtherSigilsInertInsideAFence() throws {
        let amount = try #require(Recipe.read("Add @{>500 g} flour@.").firstAmount)
        #expect(amount.kind.impreciseText == ">500 g")
        #expect(amount.unit == nil)
    }

    @Test
    func doesNotDivideByAZeroDenominator() throws {
        let amount = try #require(Recipe.read("Add @{1/0 cup} flour@.").firstAmount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == 1.0)
        #expect(quantity.text == "1")
        #expect(amount.unit == "/0 cup")
    }

    @Test
    func doesNotDivideByAZeroDenominatorInAMixedNumber() throws {
        let amount = try #require(Recipe.read("Add @{1 1/0 cup} flour@.").firstAmount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == 1.0)
        #expect(quantity.text == "1")
        #expect(amount.unit == "1/0 cup")
    }

    @Test
    func parsesAFractionWithADecimalNumerator() throws {
        let amount = try #require(Recipe.read("Add @{1.5/2 cups} milk@.").firstAmount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == 0.75)
        #expect(quantity.text == "1.5/2")
        #expect(amount.unit == "cups")
    }

    @Test
    func parsesAFractionWithADecimalDenominator() throws {
        let amount = try #require(Recipe.read("Add @{1/2.5 cups} milk@.").firstAmount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == 0.4)
        #expect(quantity.text == "1/2.5")
        #expect(amount.unit == "cups")
    }

    @Test
    func doesNotDivideByADenominatorThatIsADecimalZero() throws {
        let amount = try #require(Recipe.read("Add @{1/0.0 cup} flour@.").firstAmount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == 1.0)
        #expect(quantity.text == "1")
        #expect(amount.unit == "/0.0 cup")
    }

    @Test
    func readsAFractionAsAMixedNumberOnlyAfterAWholeNumber() throws {
        // The mixed form follows a whole number, so a decimal one does not open one.
        let amount = try #require(Recipe.read("Add @{1.5 1/2 cups} flour@.").firstAmount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == 1.5)
        #expect(quantity.text == "1.5")
        #expect(amount.unit == "1/2 cups")
    }

    @Test
    func parsesAFractionWithNoUnit() throws {
        let amount = try #require(Recipe.read("Use @{2/4} lemon@.").firstAmount)
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
        let amount = try #require(Recipe.read(source).firstAmount)
        let range = try #require(amount.kind.rangeQuantities)
        #expect(range.low.value == low)
        #expect(range.high.value == high)
        #expect(amount.unit == unit)
    }

    @Test
    func parsesARangeThatStartsWithAMixedNumber() throws {
        let amount = try #require(Recipe.read("Add @{1 1/2-2 cups} flour@.").firstAmount)
        let range = try #require(amount.kind.rangeQuantities)
        #expect(range.low.value == 1.5)
        #expect(range.low.text == "1 1/2")
        #expect(range.high.value == 2.0)
        #expect(range.high.text == "2")
        #expect(amount.unit == "cups")
    }

    @Test
    func treatsAHyphenWithNoFollowingNumberAsPartOfTheUnit() throws {
        let amount = try #require(Recipe.read("Add @{1- 2 tbsp} olive oil@.").firstAmount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == 1.0)
        #expect(amount.unit == "- 2 tbsp")
    }

    @Test(arguments: [
        (source: "Add @{3. kg} flour@.", unit: ". kg"),
        (source: "Add @{3.x} flour@.", unit: ".x")
    ])
    func stopsTheQuantityAtADecimalPointWithNoDigitsAfterIt(source: String, unit: String) throws {
        let amount = try #require(Recipe.read(source).firstAmount)
        let quantity = try #require(amount.kind.preciseQuantity)
        #expect(quantity.value == 3.0)
        #expect(quantity.text == "3")
        #expect(amount.unit == unit)
    }

    @Test
    func keepsAnyExtraSpaceBeforeTheUnitInTheUnit() throws {
        // A single space separates the quantity from the unit; a second one is unit text.
        let amount = try #require(Recipe.read("Add @{200  g} flour@.").firstAmount)
        #expect(amount.unit == " g")
    }

    @Test
    func readsAnEmptyFenceAsAnEmptyImpreciseAmount() throws {
        let ingredient = try #require(Recipe.read("Add @{} salt@.").firstIngredient)
        let amount = try #require(ingredient.amount)
        #expect(ingredient.name == "salt")
        #expect(amount.kind.impreciseText?.isEmpty == true)
        #expect(amount.unit == nil)
    }

    // A quantity is a leading run of numeric characters, and an exponent is not one of them,
    // so the mark and everything after it is unit text. This is what a writer producing an
    // amount has to stay inside.

    @Test(arguments: [
        (fence: "1e5 g", quantity: 1.0, unit: "e5 g"),
        (fence: "1e-5 g", quantity: 1.0, unit: "e-5 g"),
        (fence: "2.5e3", quantity: 2.5, unit: "e3")
    ])
    func readsNoExponentInAQuantity(fence: String, quantity: Double, unit: String) {
        let amount = SousParser().parseAmount(fence)

        #expect(amount.kind.preciseQuantity?.value == quantity)
        #expect(amount.unit == unit)
    }

    @Test
    func capturesTheVerbatimFenceContentAsText() throws {
        let amount = try #require(Recipe.read("Cook @{200 g} pasta@.").firstAmount)
        #expect(amount.text == "200 g")
    }
}
