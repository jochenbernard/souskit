import SousCore
import Testing

@Suite("Ingredient flags")
struct IngredientFlagTests {
    @Test
    func readsTheStapleFlag() throws {
        let parsed = SousParser().parseRecipe("Season with @salt@:staple.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.name == "salt")
        #expect(ingredient.flags.isStaple)
        #expect(!ingredient.flags.isOptional)
        #expect(!ingredient.flags.isNonFood)
        #expect(ingredient.flags.unrecognized.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsTheNonFoodFlag() throws {
        let parsed = SousParser().parseRecipe("Loosen with @{50 ml} water@:non-food if needed.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.flags.isNonFood)
        #expect(ingredient.amount?.unit == "ml")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsTheOptionalFlag() throws {
        let parsed = SousParser().parseRecipe("Scatter @chili flakes@:optional over the top.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.flags.isOptional)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsTheQuestionMarkAsTheOptionalShorthand() throws {
        let parsed = SousParser().parseRecipe("Scatter @rosemary@? over the top.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.flags.isOptional)
        #expect(ingredient.name == "rosemary")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func chainsSeveralNamedFlags() throws {
        let parsed = SousParser().parseRecipe("Add @water@:non-food:staple now.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.flags.isNonFood)
        #expect(ingredient.flags.isStaple)
        #expect(!ingredient.flags.isOptional)
    }

    @Test
    func chainsTheShorthandWithANamedFlag() throws {
        let parsed = SousParser().parseRecipe("Add @rosemary@?:staple now.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.flags.isOptional)
        #expect(ingredient.flags.isStaple)
    }

    @Test
    func composesFlagsWithAnAmountAndTheFixedMarker() throws {
        let parsed = SousParser().parseRecipe("Stir in @{=10 g} salt@:staple.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        let amount = try #require(ingredient.amount)
        #expect(ingredient.name == "salt")
        #expect(ingredient.flags.isStaple)
        #expect(amount.isFixed)
        #expect(amount.kind.preciseQuantity?.value == 10.0)
        #expect(amount.unit == "g")
    }

    @Test
    func readsARepeatedFlagOnce() throws {
        let parsed = SousParser().parseRecipe("Season with @salt@:staple:staple.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.flags.isStaple)
        #expect(ingredient.flags.unrecognized.isEmpty)
    }

    @Test
    func attachesEachFlagChainToItsOwnIngredient() throws {
        let parsed = SousParser().parseRecipe("Season with @salt@:staple and @rosemary@?.")

        let ingredients = try #require(parsed.value.steps.first?.ingredients)
        #expect(ingredients.map(\.flags.isStaple) == [true, false])
        #expect(ingredients.map(\.flags.isOptional) == [false, true])
    }

    // A flag word runs from its colon through the following run of letters, digits, and
    // hyphens, and ends at the first character outside that set.

    @Test
    func endsAFlagWordAtTheFirstCharacterOutsideItsSet() throws {
        let parsed = SousParser().parseRecipe("Season with @black pepper@:staple.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.first?.flags.isStaple == true)
        #expect(step.segments.last?.proseText == ".")
    }

    @Test
    func readsDigitsAndHyphensAsPartOfAFlagWord() throws {
        let parsed = SousParser().parseRecipe("Add @sauce@:batch-2 now.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.flags.unrecognized == ["batch-2"])
    }

    @Test
    func readsALetterOutsideAsciiAsPartOfAFlagWord() throws {
        let parsed = SousParser().parseRecipe("Add @sauce@:cr\u{00E8}me now.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.flags.unrecognized == ["cr\u{00E8}me"])
    }

    @Test
    func keepsAColonWithNoFlagWordAsProse() throws {
        let parsed = SousParser().parseRecipe("Season with @salt@: to taste.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.first?.flags.isStaple == false)
        #expect(step.segments.last?.proseText == ": to taste.")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func endsTheChainAtAColonWithNoFlagWord() throws {
        let parsed = SousParser().parseRecipe("Season with @salt@:staple::optional.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.first?.flags.isStaple == true)
        #expect(step.ingredients.first?.flags.isOptional == false)
        #expect(step.segments.last?.proseText == "::optional.")
    }

    @Test
    func doesNotReadAFlagSeparatedFromTheSpanByASpace() throws {
        let parsed = SousParser().parseRecipe("Season with @salt@ :staple.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.first?.flags.isStaple == false)
        #expect(step.segments.last?.proseText == " :staple.")
    }

    // A flag opens on the character right after the closing sigil, so prose that needs a
    // literal `?` or `:` there escapes it, exactly as prose needs `\@` for a literal sigil.

    @Test
    func doesNotReadAnEscapedShorthandAsAFlag() throws {
        let parsed = SousParser().parseRecipe("Is it @salt@\\? Yes.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.first?.flags.isOptional == false)
        #expect(step.segments.last?.proseText == "? Yes.")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func doesNotReadAnEscapedColonAsAFlag() throws {
        let parsed = SousParser().parseRecipe("Serve @rice@\\:about 200 g each.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.first?.flags.unrecognized.isEmpty == true)
        #expect(step.segments.last?.proseText == ":about 200 g each.")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func endsTheChainAtAnEscapedShorthand() throws {
        let parsed = SousParser().parseRecipe("Season with @salt@:staple\\?y.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.first?.flags.isStaple == true)
        #expect(step.ingredients.first?.flags.isOptional == false)
        #expect(step.segments.last?.proseText == "?y.")
    }

    @Test
    func doesNotAttachFlagsToCookware() throws {
        // Cookware carries a single value, so a colon after it is ordinary prose.
        let parsed = SousParser().parseRecipe("Warm a #pan#:staple here.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.cookware.map(\.name) == ["pan"])
        #expect(step.segments.last?.proseText == ":staple here.")
        #expect(parsed.diagnostics.isEmpty)
    }

    // An unrecognized flag is never fatal: it is preserved as written and warned about, so a
    // file using a flag from a later version still reads.

    @Test
    func preservesAnUnrecognizedFlag() throws {
        let parsed = SousParser().parseRecipe("Add @sauce@:homemade now.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.flags.unrecognized == ["homemade"])
        #expect(!ingredient.flags.isStaple)
        #expect(parsed.diagnostics.contains(where: { $0.kind == .unknownFlag }))
        #expect(parsed.diagnostics.allSatisfy({ $0.severity == .warning }))
    }

    @Test
    func keepsUnrecognizedFlagsInDocumentOrder() throws {
        let parsed = SousParser().parseRecipe("Add @sauce@:homemade:staple:frozen now.")

        let ingredient = try #require(parsed.value.steps.first?.ingredients.first)
        #expect(ingredient.flags.unrecognized == ["homemade", "frozen"])
        #expect(ingredient.flags.isStaple)
    }
}
