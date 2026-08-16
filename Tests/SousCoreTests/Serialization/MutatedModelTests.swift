import SousCore
import Testing

@Suite("Mutated models")
struct MutatedModelTests {
    @Test(arguments: ["", " salt", "\tsalt", "a\nb", "salt\n", "a\n\nb"])
    func writesAnIngredientNameThatNoLongerReadsBackAsOne(name: String) throws {
        var value = Recipe.read("Add @salt@ now.")
        var ingredient = try #require(value.ingredients.first)
        ingredient.name = name
        value.groups[0].steps[0].segments[1] = .ingredient(ingredient)

        #expect(value.reRead().ingredients.isEmpty)
    }

    @Test(arguments: ["", " casserole", "\tcasserole", "a\nb", "casserole\n", "a\n\nb"])
    func writesACookwareNameThatNoLongerReadsBackAsOne(name: String) throws {
        var value = Recipe.read("Use a #casserole# now.")
        var cookware = try #require(value.cookware.first)
        cookware.name = name
        value.groups[0].steps[0].segments[1] = .cookware(cookware)

        #expect(value.reRead().cookware.isEmpty)
    }

    @Test(arguments: ["", " 40 min", "\t40 min", "a\nb", "40 min\n", "a\n\nb"])
    func writesATimerTextThatNoLongerReadsBackAsOne(text: String) throws {
        var value = Recipe.read("Wait ~40 min~ now.")
        var timer = try #require(value.timers.first)
        timer.text = text
        value.groups[0].steps[0].segments[1] = .timer(timer)

        #expect(value.reRead().timers.isEmpty)
    }

    @Test(arguments: ["", " bechamel", "\tbechamel", "a\nb", "bechamel\n", "a\n\nb"])
    func writesAReferenceTargetThatNoLongerReadsBackAsOne(target: String) throws {
        var value = Recipe.read("Layer the >bechamel> in a dish.")
        var reference = try #require(value.references.first)
        reference.target = target
        value.groups[0].steps[0].segments[1] = .reference(reference)

        #expect(value.reRead().references.isEmpty)
    }

    @Test(arguments: ["salt ", "salt\t"])
    func writesAnIngredientNameThatReadsBackTrimmed(name: String) throws {
        var value = Recipe.read("Add @salt@ now.")
        var ingredient = try #require(value.ingredients.first)
        ingredient.name = name
        value.groups[0].steps[0].segments[1] = .ingredient(ingredient)

        #expect(value.reRead().ingredients.map(\.name) == ["salt"])
    }

    @Test(arguments: [" bechamel", "bechamel "])
    func writesAReferenceTargetTheFenceBeforeItLeavesTrimmed(target: String) throws {
        var value = Recipe.read("Layer the >{2 g} bechamel> in a dish.")
        var reference = try #require(value.references.first)
        reference.target = target
        value.groups[0].steps[0].segments[1] = .reference(reference)

        #expect(value.reRead().references.map(\.target) == ["bechamel"])
    }

    @Test(arguments: ["sa lt"])
    func writesAnIngredientNameThatStillReadsBack(name: String) throws {
        var value = Recipe.read("Add @salt@ now.")
        var ingredient = try #require(value.ingredients.first)
        ingredient.name = name
        value.groups[0].steps[0].segments[1] = .ingredient(ingredient)

        #expect(value.reRead().ingredients.map(\.name) == [name])
    }

    @Test(arguments: ["bech amel", "sauces/rouille"])
    func writesAReferenceTargetThatStillReadsBack(target: String) throws {
        var value = Recipe.read("Layer the >bechamel> in a dish.")
        var reference = try #require(value.references.first)
        reference.target = target
        value.groups[0].steps[0].segments[1] = .reference(reference)

        #expect(value.reRead().references.map(\.target) == [target])
    }

    @Test(arguments: ["a}b", "a\\b", "a\\}b"])
    func writesAnAmountTextThatStatesABraceOrABackslash(text: String) throws {
        var value = Recipe.read("Add @{200 g} salt@ now.")
        var ingredient = try #require(value.ingredients.first)
        ingredient.amount?.text = text
        value.groups[0].steps[0].segments[1] = .ingredient(ingredient)

        let written = try #require(value.reRead().ingredients.first)
        #expect(written.amount?.text == text)
        #expect(written.name == "salt")
    }

    @Test(arguments: ["a\nb", "a\n\nb"])
    func writesAnAmountTextHoldingALineBreakThatLeavesTheFenceUnclosed(text: String) throws {
        var value = Recipe.read("Add @{200 g} salt@ now.")
        var ingredient = try #require(value.ingredients.first)
        ingredient.amount?.text = text
        value.groups[0].steps[0].segments[1] = .ingredient(ingredient)

        #expect(value.reRead().ingredients.isEmpty)
    }

    @Test
    func writesAnEmptyAmountTextAsAnAmountStill() throws {
        var value = Recipe.read("Add @{200 g} salt@ now.")
        var ingredient = try #require(value.ingredients.first)
        ingredient.amount?.text = ""
        value.groups[0].steps[0].segments[1] = .ingredient(ingredient)

        let written = try #require(value.reRead().ingredients.first)
        #expect(written.amount?.text.isEmpty == true)
        #expect(written.name == "salt")
    }

    @Test(arguments: [
        (name: "", groups: [nil], steps: ["## \nBrown the beef."]),
        (name: "Filling\nMore", groups: ["Filling"], steps: ["More\nBrown the beef."]),
        (name: "Filling\n## Other", groups: ["Filling", "Other"], steps: ["Brown the beef."]),
        (name: " Filling", groups: ["Filling"], steps: ["Brown the beef."]),
        (name: "Filling ", groups: ["Filling"], steps: ["Brown the beef."]),
        (name: "\tFilling", groups: ["Filling"], steps: ["Brown the beef."]),
        (name: " ", groups: [nil], steps: ["##  \nBrown the beef."])
    ])
    func writesAGroupNameThatNoLongerReadsBackAsOne(
        name: String,
        groups: [String?],
        steps: [String]
    ) {
        var value = Recipe.read("## Filling\nBrown the beef.")
        value.groups[0].name = name

        let written = value.reRead()
        #expect(written.groups.map(\.name) == groups)
        #expect(written.steps.map(\.text) == steps)
    }

    @Test(arguments: ["Rich Filling", "sauces/rouille", "@salt@", "a  b"])
    func writesAGroupNameThatStillReadsBack(name: String) {
        var value = Recipe.read("## Filling\nBrown the beef.")
        value.groups[0].name = name

        #expect(value.reRead().groups.map(\.name) == [name])
    }

    @Test
    func writesAnEmptyDefaultGroupAsNothing() {
        var value = Recipe.read("Warm the oven.\n\n## Filling\nBrown the beef.")
        value.groups[0].steps = []

        #expect(value.serialized() == "## Filling\nBrown the beef.")
    }

    @Test
    func refusesToScaleAQuantityMutatedToANegativeValue() throws {
        var value = Recipe.read("Add @{200 g} flour@.")
        var ingredient = try #require(value.ingredients.first)
        var amount = try #require(ingredient.amount)
        var quantity = try #require(amount.kind.preciseQuantity)

        quantity.value = -200
        amount.kind = .precise(quantity)
        ingredient.amount = amount
        value.groups[0].steps[0].segments[1] = .ingredient(ingredient)

        #expect(throws: ScalingError.unwritableQuantity) {
            try value.scaled(by: 2.0)
        }
    }
}
