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
        let ingredient = try #require(Recipe.read("Add @water@:non-food:staple now.").firstIngredient)
        #expect(ingredient.flags.isNonFood)
        #expect(ingredient.flags.isStaple)
        #expect(!ingredient.flags.isOptional)
    }

    @Test
    func chainsTheShorthandWithANamedFlag() throws {
        let ingredient = try #require(Recipe.read("Add @rosemary@?:staple now.").firstIngredient)
        #expect(ingredient.flags.isOptional)
        #expect(ingredient.flags.isStaple)
    }

    @Test
    func composesFlagsWithAnAmountAndTheFixedMarker() throws {
        let ingredient = try #require(Recipe.read("Stir in @{=10 g} salt@:staple.").firstIngredient)
        let amount = try #require(ingredient.amount)
        #expect(ingredient.name == "salt")
        #expect(ingredient.flags.isStaple)
        #expect(amount.isFixed)
        #expect(amount.kind.preciseQuantity?.value == 10.0)
        #expect(amount.unit == "g")
    }

    @Test
    func readsARepeatedFlagOnce() throws {
        let ingredient = try #require(Recipe.read("Season with @salt@:staple:staple.").firstIngredient)
        #expect(ingredient.flags.isStaple)
        #expect(ingredient.flags.unrecognized.isEmpty)
    }

    @Test
    func attachesEachFlagChainToItsOwnIngredient() throws {
        let ingredients = try #require(Recipe.read("Season with @salt@:staple and @rosemary@?.").steps.first?.ingredients)
        #expect(ingredients.map(\.flags.isStaple) == [true, false])
        #expect(ingredients.map(\.flags.isOptional) == [false, true])
    }

    // A flag word runs from its colon through the following run of letters and hyphens, and
    // ends at the first character outside that set.

    @Test
    func endsAFlagWordAtTheFirstCharacterOutsideItsSet() throws {
        let step = try #require(Recipe.read("Season with @black pepper@:staple.").firstStep)
        #expect(step.ingredients.first?.flags.isStaple == true)
        #expect(step.segments.last?.proseText == ".")
    }

    @Test
    func readsAHyphenAsPartOfAFlagWord() throws {
        let ingredient = try #require(Recipe.read("Add @sauce@:home-made now.").firstIngredient)
        #expect(ingredient.flags.unrecognized == ["home-made"])
    }

    // No flag this language defines carries a number, so a number is prose like any other
    // character outside the set. It ends a flag word and opens none of its own.

    @Test
    func endsAFlagWordAtANumber() throws {
        let step = try #require(Recipe.read("Add @sauce@:batch-2 now.").firstStep)
        #expect(step.ingredients.first?.flags.unrecognized == ["batch-"])
        #expect(step.segments.last?.proseText == "2 now.")
    }

    @Test(arguments: ["2", "\u{00BD}"])
    func doesNotOpenAFlagOnANumber(number: String) throws {
        let parsed = SousParser().parseRecipe("Add @salt@:\(number) spoons now.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.ingredients.first?.flags.unrecognized.isEmpty == true)
        #expect(step.segments.last?.proseText == ":\(number) spoons now.")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsALetterOutsideAsciiAsPartOfAFlagWord() throws {
        let ingredient = try #require(Recipe.read("Add @sauce@:cr\u{00E8}me now.").firstIngredient)
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
        let step = try #require(Recipe.read("Season with @salt@:staple::optional.").firstStep)
        #expect(step.ingredients.first?.flags.isStaple == true)
        #expect(step.ingredients.first?.flags.isOptional == false)
        #expect(step.segments.last?.proseText == "::optional.")
    }

    @Test
    func doesNotReadAFlagSeparatedFromTheSpanByASpace() throws {
        let step = try #require(Recipe.read("Season with @salt@ :staple.").firstStep)
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
        let step = try #require(Recipe.read("Season with @salt@:staple\\?y.").firstStep)
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

    @Test
    func doesNotAttachFlagsToATimer() throws {
        // A timer carries a single duration, so a colon after it is ordinary prose. Nothing
        // opens a flag there, so the prose keeps its colon unescaped and reads back the same.
        let parsed = SousParser().parseRecipe("Wait ~40 min~:staple here.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.timers.map(\.text) == ["40 min"])
        #expect(step.segments.last?.proseText == ":staple here.")
        #expect(parsed.diagnostics.isEmpty)
        #expect(parsed.value.serialized() == "Wait ~40 min~:staple here.")
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
        let ingredient = try #require(Recipe.read("Add @sauce@:homemade:staple:frozen now.").firstIngredient)
        #expect(ingredient.flags.unrecognized == ["homemade", "frozen"])
        #expect(ingredient.flags.isStaple)
    }
}
