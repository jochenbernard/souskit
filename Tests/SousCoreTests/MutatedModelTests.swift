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
        value.steps[0].segments[1] = .ingredient(ingredient)

        #expect(reRead(value).ingredients.isEmpty)
    }

    @Test(arguments: ["", " pan", "\tpan", "a\n\nb"])
    func writesACookwareNameThatNoLongerReadsBackAsOne(name: String) throws {
        var value = recipe("Use a #pan# now.")
        var cookware = try #require(value.cookware.first)
        cookware.name = name
        value.steps[0].segments[1] = .cookware(cookware)

        #expect(reRead(value).cookware.isEmpty)
    }

    @Test(arguments: ["", " 40 min", "\t40 min", "a\n\nb"])
    func writesATimerTextThatNoLongerReadsBackAsOne(text: String) throws {
        var value = recipe("Wait ~40 min~ now.")
        var timer = try #require(value.timers.first)
        timer.text = text
        value.steps[0].segments[1] = .timer(timer)

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
        value.steps[0].segments[1] = .ingredient(ingredient)

        #expect(reRead(value).ingredients.map(\.name) == [name])
    }

    // An amount is written between the fence's braces rather than between sigils, so its own
    // boundary is the brace that closes the fence early.

    @Test
    func writesAnAmountTextHoldingAClosingBraceThatEndsTheFenceEarly() throws {
        var value = recipe("Add @{200 g} salt@ now.")
        var ingredient = try #require(value.ingredients.first)
        ingredient.amount?.text = "a}b"
        value.steps[0].segments[1] = .ingredient(ingredient)

        let written = try #require(reRead(value).ingredients.first)
        #expect(written.amount?.text == "a")
        #expect(written.name == "b} salt")
    }

    @Test
    func writesAnAmountTextHoldingABlankLineThatEndsTheParagraph() throws {
        var value = recipe("Add @{200 g} salt@ now.")
        var ingredient = try #require(value.ingredients.first)
        ingredient.amount?.text = "a\n\nb"
        value.steps[0].segments[1] = .ingredient(ingredient)

        #expect(reRead(value).ingredients.isEmpty)
    }

    @Test
    func writesAnEmptyAmountTextAsAnAmountStill() throws {
        var value = recipe("Add @{200 g} salt@ now.")
        var ingredient = try #require(value.ingredients.first)
        ingredient.amount?.text = ""
        value.steps[0].segments[1] = .ingredient(ingredient)

        let written = try #require(reRead(value).ingredients.first)
        #expect(written.amount?.text.isEmpty == true)
        #expect(written.name == "salt")
    }
}
