import SousCore
import Testing

@Suite("Ingredient flags")
struct IngredientFlagTests {
    @Test
    func readsTheStapleFlag() throws {
        let parsed = SousParser().parseRecipe("Season with @salt@:staple.")

        let ingredient = try #require(parsed.value.firstIngredient)
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

        let ingredient = try #require(parsed.value.firstIngredient)
        #expect(ingredient.flags.isNonFood)
        #expect(ingredient.amount?.unit == "ml")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsTheOptionalFlag() throws {
        let parsed = SousParser().parseRecipe("Scatter @cayenne@:optional over the top.")

        let ingredient = try #require(parsed.value.firstIngredient)
        #expect(ingredient.flags.isOptional)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsTheQuestionMarkAsTheOptionalShorthand() throws {
        let parsed = SousParser().parseRecipe("Scatter @thyme@? over the top.")

        let ingredient = try #require(parsed.value.firstIngredient)
        #expect(ingredient.flags.isOptional)
        #expect(ingredient.name == "thyme")
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
        let ingredient = try #require(Recipe.read("Add @thyme@?:staple now.").firstIngredient)
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
    func readsARepeatedUnrecognizedFlagOnce() {
        let parsed = SousParser().parseRecipe("Add @stock@:homemade:homemade now.")

        #expect(parsed.value.ingredients.map(\.flags.unrecognized) == [["homemade"]])
        #expect(parsed.value.serialized() == "Add @stock@:homemade now.")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func attachesEachFlagChainToItsOwnIngredient() throws {
        let recipe = Recipe.read("Season with @salt@:staple and @thyme@?.")
        let ingredients = try #require(recipe.steps.first?.ingredients)
        #expect(ingredients.map(\.flags.isStaple) == [true, false])
        #expect(ingredients.map(\.flags.isOptional) == [false, true])
    }

    @Test
    func endsAFlagWordAtTheFirstCharacterOutsideItsSet() throws {
        let step = try #require(Recipe.read("Season with @black pepper@:staple.").firstStep)
        #expect(step.ingredients.first?.flags.isStaple == true)
        #expect(step.segments.last?.proseText == ".")
    }

    @Test
    func readsAHyphenAsPartOfAFlagWord() throws {
        let ingredient = try #require(Recipe.read("Add @stock@:home-made now.").firstIngredient)
        #expect(ingredient.flags.unrecognized == ["home-made"])
    }

    @Test
    func endsAFlagWordAtANumber() throws {
        let step = try #require(Recipe.read("Add @stock@:batch-2 now.").firstStep)
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
        let ingredient = try #require(Recipe.read("Add @stock@:cr\u{00E8}me now.").firstIngredient)
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
        let parsed = SousParser().parseRecipe("Serve @potatoes@\\:about 200 g each.")

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
        let parsed = SousParser().parseRecipe("Warm a #casserole#:staple here.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.cookware.map(\.name) == ["casserole"])
        #expect(step.segments.last?.proseText == ":staple here.")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func doesNotAttachFlagsToATimer() throws {
        let parsed = SousParser().parseRecipe("Wait ~40 min~:staple here.")

        let step = try #require(parsed.value.steps.first)
        #expect(step.timers.map(\.text) == ["40 min"])
        #expect(step.segments.last?.proseText == ":staple here.")
        #expect(parsed.diagnostics.isEmpty)
        #expect(parsed.value.serialized() == "Wait ~40 min~:staple here.")
    }

    @Test
    func preservesAnUnrecognizedFlag() throws {
        let parsed = SousParser().parseRecipe("Add @stock@:homemade now.")

        let ingredient = try #require(parsed.value.firstIngredient)
        #expect(ingredient.flags.unrecognized == ["homemade"])
        #expect(!ingredient.flags.isStaple)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func keepsUnrecognizedFlagsInDocumentOrder() throws {
        let ingredient = try #require(Recipe.read("Add @stock@:homemade:staple:frozen now.").firstIngredient)
        #expect(ingredient.flags.unrecognized == ["homemade", "frozen"])
        #expect(ingredient.flags.isStaple)
    }
}
