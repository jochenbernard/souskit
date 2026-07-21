import SousCore
import Testing

@Suite("Span edge cases")
struct SpanEdgeCaseTests {
    @Test
    func readsASpanThatNamesNothingAsOrdinaryTextEvenWithAnAmountFence() throws {
        let parsed = SousParser().parseRecipe("Add @{200 g}@ now.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.isEmpty)
        #expect(step.segments.map(\.proseText) == ["Add @{200 g}@ now."])
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsTheSpansOwnSigilInsideAnAmountFenceAsPartOfTheAmount() throws {
        // Every sigil is inert between the braces, the span's own included, so the fence is
        // read before the closing sigil is looked for.
        let parsed = SousParser().parseRecipe("Add @{2 @ g} flour@ now.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.name == "flour")
        #expect(ingredient.amount?.kind.preciseQuantity?.value == 2.0)
        #expect(ingredient.amount?.unit == "@ g")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func doesNotReadAnAmountFenceInACookwareSpan() throws {
        // Cookware carries a single value, so a brace is part of its name.
        let parsed = SousParser().parseRecipe("Use a #{200 g} pan#.")

        let cookware = try #require(parsed.value.steps.first?.cookware.first)
        #expect(cookware.name == "{200 g} pan")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsTwoAdjacentSpans() {
        let parsed = SousParser().parseRecipe("Mix @salt@@pepper@ in.")

        #expect(parsed.value.ingredients.map(\.name) == ["salt", "pepper"])
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func doesNotOpenASpanForASigilAtTheEndOfTheText() throws {
        let parsed = SousParser().parseRecipe("Season with salt @")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func keepsATrailingBackslashAsOrdinaryText() throws {
        let parsed = SousParser().parseRecipe("Season to taste \\")

        let step = try #require(parsed.value.steps.first)
        #expect(step.segments.first?.proseText == "Season to taste \\")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func keepsABackslashBeforeACharacterThatIsNotEscapable() throws {
        let parsed = SousParser().parseRecipe("Read the \\note here.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.segments.first?.proseText == "Read the \\note here.")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func keepsAnOrdinaryBackslashInProse() throws {
        // Only a sigil is escapable, so a backslash anywhere else is ordinary text and
        // needs no doubling.
        let parsed = SousParser().parseRecipe("Note the path C:\\Users, then add @garlic@.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.segments.first?.proseText == "Note the path C:\\Users, then add ")
        #expect(step.ingredients.map(\.name) == ["garlic"])
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func keepsAnOrdinaryBackslashInAName() throws {
        let parsed = SousParser().parseRecipe("Use a #8\\ pan#.")

        let cookware = try #require(parsed.value.steps.first?.cookware.first)
        #expect(cookware.name == "8\\ pan")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsADoubledBackslashAsOneLiteralBackslash() throws {
        let parsed = SousParser().parseRecipe("Halve the \\\\ ratio.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.segments.first?.proseText == "Halve the \\ ratio.")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsAnEscapedBackslashDirectlyBeforeAnAnnotation() throws {
        // The backslash is escapable, so a literal one can sit directly before a sigil that
        // opens a span.
        let parsed = SousParser().parseRecipe("Path C:\\\\@garlic@ now.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.segments.first?.proseText == "Path C:\\")
        #expect(step.ingredients.map(\.name) == ["garlic"])
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsAnEscapedBackslashInsideAName() throws {
        let parsed = SousParser().parseRecipe("Add @a\\\\b@ now.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.name == "a\\b")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsANameThatEndsInAnEscapedBackslash() throws {
        let parsed = SousParser().parseRecipe("Add @flour\\\\@ now.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.name == "flour\\")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func representsACookwareAnnotationAsASegment() throws {
        let parsed = SousParser().parseRecipe("Warm a #pan# now.")

        let segments = try #require(parsed.value.steps.first?.segments)
        #expect(segments.count == 3)
        #expect(segments.first?.proseText == "Warm a ")
        #expect(segments.dropFirst().first?.cookwareValue?.name == "pan")
        #expect(segments.last?.proseText == " now.")
    }
}
