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
        #expect(parsed.diagnostics.map(\.kind) == [.unnamedAnnotation])
    }

    @Test
    func readsTheSpansOwnSigilInsideAnAmountFenceAsPartOfTheAmount() throws {
        let parsed = SousParser().parseRecipe("Add @{2 @ g} flour@ now.")

        let ingredient = try #require(parsed.value.firstIngredient)
        #expect(ingredient.name == "flour")
        #expect(ingredient.amount?.kind.preciseQuantity?.value == 2.0)
        #expect(ingredient.amount?.unit == "@ g")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func doesNotReadAnAmountFenceInACookwareSpan() throws {
        let parsed = SousParser().parseRecipe("Use a #{200 g} pan#.")

        let cookware = try #require(parsed.value.firstCookware)
        #expect(cookware.name == "{200 g} pan")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func closesASpanOnlyOnItsOwnSigil() throws {
        let parsed = SousParser().parseRecipe("Use a #pan @garlic@ style#.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.cookware.map(\.name) == ["pan @garlic@ style"])
        #expect(step.ingredients.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
        #expect(parsed.value.serialized() == "Use a #pan @garlic@ style#.")
    }

    @Test
    func readsTwoAdjacentSpans() {
        let parsed = SousParser().parseRecipe("Mix @salt@@thyme@ in.")

        #expect(parsed.value.ingredients.map(\.name) == ["salt", "thyme"])
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
        let parsed = SousParser().parseRecipe("Note the path C:\\Users, then add @garlic@.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.segments.first?.proseText == "Note the path C:\\Users, then add ")
        #expect(step.ingredients.map(\.name) == ["garlic"])
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func keepsAnOrdinaryBackslashInAName() throws {
        let parsed = SousParser().parseRecipe("Use a #8\\ pan#.")

        let cookware = try #require(parsed.value.firstCookware)
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
        let parsed = SousParser().parseRecipe("Path C:\\\\@garlic@ now.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.segments.first?.proseText == "Path C:\\")
        #expect(step.ingredients.map(\.name) == ["garlic"])
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsAnEscapedBackslashInsideAName() throws {
        let parsed = SousParser().parseRecipe("Add @a\\\\b@ now.")

        let ingredient = try #require(parsed.value.firstIngredient)
        #expect(ingredient.name == "a\\b")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsANameThatEndsInAnEscapedBackslash() throws {
        let parsed = SousParser().parseRecipe("Add @flour\\\\@ now.")

        let ingredient = try #require(parsed.value.firstIngredient)
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
