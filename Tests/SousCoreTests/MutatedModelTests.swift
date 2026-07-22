import SousCore
import Testing

// A model is faithful to what was read rather than validated against what can be written, so
// a caller may set a name or a text that no pair of sigils can bound. The documentation on
// those properties says which values those are, and these tests hold it to it. Reading
// produces none of them, so only a mutation can.

@Suite("Mutated models")
struct MutatedModelTests {
    /// The one-annotation recipe each case mutates, whose middle segment is the annotation.
    private func recipe(_ source: String) -> Recipe {
        SousParser().parseRecipe(source).value
    }

    private func reRead(_ recipe: Recipe) -> Recipe {
        SousParser().parseRecipe(recipe.serialized()).value
    }

    // The values that stop being an annotation: nothing to bound, a sigil the opener rule
    // leaves shut, or a paragraph break the span cannot reach across.

    @Test(arguments: ["", " salt", "\tsalt", "a\n\nb"])
    func writesAnIngredientNameThatNoLongerReadsBackAsOne(name: String) throws {
        var value = recipe("Add @salt@ now.")
        var ingredient = try #require(value.ingredients.first)
        ingredient.name = name
        value.groups[0].steps[0].segments[1] = .ingredient(ingredient)

        #expect(reRead(value).ingredients.isEmpty)
    }

    @Test(arguments: ["", " pan", "\tpan", "a\n\nb"])
    func writesACookwareNameThatNoLongerReadsBackAsOne(name: String) throws {
        var value = recipe("Use a #pan# now.")
        var cookware = try #require(value.cookware.first)
        cookware.name = name
        value.groups[0].steps[0].segments[1] = .cookware(cookware)

        #expect(reRead(value).cookware.isEmpty)
    }

    @Test(arguments: ["", " 40 min", "\t40 min", "a\n\nb"])
    func writesATimerTextThatNoLongerReadsBackAsOne(text: String) throws {
        var value = recipe("Wait ~40 min~ now.")
        var timer = try #require(value.timers.first)
        timer.text = text
        value.groups[0].steps[0].segments[1] = .timer(timer)

        #expect(reRead(value).timers.isEmpty)
    }

    // The values that stay an annotation, which is what makes the list above a real boundary
    // rather than a blanket warning: only leading whitespace, emptiness, and a blank line cost
    // the annotation its sigils.

    @Test(arguments: ["salt ", "sa lt", "a\nb"])
    func writesAnIngredientNameThatStillReadsBack(name: String) throws {
        var value = recipe("Add @salt@ now.")
        var ingredient = try #require(value.ingredients.first)
        ingredient.name = name
        value.groups[0].steps[0].segments[1] = .ingredient(ingredient)

        #expect(reRead(value).ingredients.map(\.name) == [name])
    }

    // An amount is written between the fence's braces rather than between sigils, so its own
    // boundary is the brace that closes the fence early.

    @Test
    func writesAnAmountTextHoldingAClosingBraceThatEndsTheFenceEarly() throws {
        var value = recipe("Add @{200 g} salt@ now.")
        var ingredient = try #require(value.ingredients.first)
        ingredient.amount?.text = "a}b"
        value.groups[0].steps[0].segments[1] = .ingredient(ingredient)

        let written = try #require(reRead(value).ingredients.first)
        #expect(written.amount?.text == "a")
        #expect(written.name == "b} salt")
    }

    @Test
    func writesAnAmountTextHoldingABlankLineThatEndsTheParagraph() throws {
        var value = recipe("Add @{200 g} salt@ now.")
        var ingredient = try #require(value.ingredients.first)
        ingredient.amount?.text = "a\n\nb"
        value.groups[0].steps[0].segments[1] = .ingredient(ingredient)

        #expect(reRead(value).ingredients.isEmpty)
    }

    @Test
    func writesAnEmptyAmountTextAsAnAmountStill() throws {
        var value = recipe("Add @{200 g} salt@ now.")
        var ingredient = try #require(value.ingredients.first)
        ingredient.amount?.text = ""
        value.groups[0].steps[0].segments[1] = .ingredient(ingredient)

        let written = try #require(reRead(value).ingredients.first)
        #expect(written.amount?.text.isEmpty == true)
        #expect(written.name == "salt")
    }

    // A group's name is written after the "##" and the one space of a heading line, so it stops
    // opening a group when nothing bounds it: an empty name leaves the line naming nothing, and
    // a line break ends the heading and leaves the rest a step. Reading produces neither.

    @Test(arguments: ["", "Sauce\nMore"])
    func writesAGroupNameThatNoLongerReadsBackAsOne(name: String) {
        var value = recipe("## Sauce\nBrown the beef.")
        value.groups[0].name = name

        #expect(reRead(value).groups.map(\.name) != [name])
    }

    // Whitespace around a name costs it nothing, because the one space after the "##" belongs
    // to neither side and a second begins the name.

    @Test(arguments: [" Sauce", "\tSauce", "Sauce ", " ", "Rich Sauce", "sauces/red", "@salt@"])
    func writesAGroupNameThatStillReadsBack(name: String) {
        var value = recipe("## Sauce\nBrown the beef.")
        value.groups[0].name = name

        #expect(reRead(value).groups.map(\.name) == [name])
    }

    // An unnamed group states no heading, so one holding no step states nothing at all.

    @Test
    func writesAnEmptyDefaultGroupAsNothing() {
        var value = recipe("Warm the oven.\n\n## Sauce\nBrown the beef.")
        value.groups[0].steps = []

        #expect(value.serialized() == "## Sauce\nBrown the beef.")
    }

    // A quantity is a leading run of digits, so a negative value writes text that is not one.
    // Reading produces no such value, but a mutation can, and scaling refuses it rather than
    // writing an amount that no longer reads back.

    @Test
    func refusesToScaleAQuantityMutatedToANegativeValue() throws {
        var value = recipe("Add @{200 g} flour@.")
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
