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
        // A comma states no decimal point, and the number before it is not what the author
        // meant either, so the amount states no quantity at all.
        let amount = try #require(Recipe.read("Add @{3,2 kg} flour@.").firstAmount)

        #expect(amount.kind.impreciseText == "3,2 kg")
        #expect(amount.unit == nil)
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

    @Test(arguments: ["3. kg", "3.x"])
    func statesNoQuantityWhereADecimalPointHasNoDigitsAfterIt(fence: String) throws {
        let amount = try #require(Recipe.read("Add @{\(fence)} flour@.").firstAmount)

        #expect(amount.kind.impreciseText == fence)
        #expect(amount.unit == nil)
    }

    // The whitespace between the quantity and the unit separates them and belongs to neither,
    // and a fence states what its content states, so the whitespace around that content is
    // layout as well. A fence therefore reads exactly as the header value of the same text.

    @Test(arguments: [
        (fence: "200  g", unit: "g"),
        (fence: "200\tg", unit: "g"),
        (fence: "200 g ", unit: "g"),
        (fence: " 200 g", unit: "g"),
        (fence: " 200 fl oz ", unit: "fl oz")
    ])
    func trimsTheWhitespaceAroundTheContentAndTheUnit(fence: String, unit: String) throws {
        let amount = try #require(Recipe.read("Add @{\(fence)} flour@.").firstAmount)

        #expect(amount.kind.preciseQuantity?.value == 200.0)
        #expect(amount.unit == unit)
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

    // A character Unicode gives a fractional value to is a quantity, so the fractions a recipe
    // is written with need no spelling out. A whole number may stand before one, with or
    // without the whitespace separating them.

    @Test(arguments: [
        (fence: "\u{00BD} cup", value: 0.5, unit: "cup"),
        (fence: "1\u{00BD} cups", value: 1.5, unit: "cups"),
        (fence: "1 \u{00BD} cups", value: 1.5, unit: "cups"),
        (fence: "2\u{00BE}", value: 2.75, unit: ""),
        (fence: "\u{2153} cup", value: 1.0 / 3.0, unit: "cup")
    ])
    func readsAVulgarFractionAsAQuantity(fence: String, value: Double, unit: String) throws {
        let amount = try #require(Recipe.read("Add @{\(fence)} flour@.").firstAmount)

        #expect(amount.kind.preciseQuantity?.value == value)
        #expect(amount.unit == unit)
    }

    @Test
    func readsARangeBetweenVulgarFractions() throws {
        let amount = try #require(Recipe.read("Add @{\u{00BD}-1\u{00BC} cups} flour@.").firstAmount)

        let range = try #require(amount.kind.rangeQuantities)
        #expect(range.low.value == 0.5)
        #expect(range.high.value == 1.25)
        #expect(amount.unit == "cups")
    }

    // A whole numeric value is a number rather than a fraction, so a superscript and a numeral
    // stay unit text and no quantity is invented from them.

    @Test(arguments: ["\u{00B2} cups", "\u{216B} cups"])
    func readsNoQuantityFromACharacterStatingAWholeValue(fence: String) {
        let parsed = SousParser().parseRecipe("Add @{\(fence)} flour@.")

        #expect(parsed.value.firstAmount?.kind.impreciseText == fence)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsAFenceOfOnlyWhitespaceAsAnEmptyImpreciseAmount() throws {
        let amount = try #require(Recipe.read("Add @{   } salt@.").firstAmount)

        #expect(amount.kind.impreciseText?.isEmpty == true)
        #expect(amount.text.isEmpty)
    }

    @Test
    func readsTheFixedMarkerTheTrimmedContentOpensWith() throws {
        let amount = try #require(Recipe.read("Stir in @{ =1 tsp} baking soda@.").firstAmount)

        #expect(amount.isFixed)
        #expect(amount.text == "1 tsp")
    }

    // Whitespace separates whatever it stands between, whatever it is built from and however
    // much of it there is, so the whole number and the fraction of a mixed number are no
    // exception.

    @Test(arguments: ["1  1/2 cups", "1\t1/2 cups", "1 \t 1/2 cups"])
    func readsAMixedNumberAcrossAnyWhitespace(fence: String) throws {
        let amount = try #require(Recipe.read("Add @{\(fence)} flour@.").firstAmount)

        #expect(amount.kind.preciseQuantity?.value == 1.5)
        #expect(amount.unit == "cups")
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
