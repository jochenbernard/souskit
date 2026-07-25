import SousCore
import Testing

// Scaling by a factor, available since v0.3. Every amount either multiplies by the factor or
// does not move at all, and the header states what the scaled recipe now makes.
//
// What a moved amount is written back as is `ScaledAmountTests`.

@Suite("Scaling by a factor")
struct ScalingTests {
    @Test
    func multipliesAPreciseAmount() throws {
        let amount = try SousParser().amount(in: "Mix @{200 g} flour@.", scaledBy: 1.5)

        #expect(amount.kind.preciseQuantity?.value == 300.0)
        #expect(amount.unit == "g")
    }

    @Test
    func multipliesBothEndsOfARange() throws {
        let amount = try SousParser().amount(in: "Add @{1-2 tbsp} oil@.", scaledBy: 2.0)

        #expect(amount.kind.rangeQuantities?.low.value == 2.0)
        #expect(amount.kind.rangeQuantities?.high.value == 4.0)
    }

    // A fixed, imprecise, or absent amount states nothing to multiply, so a scaled recipe is
    // not a strict multiple of the original.

    @Test
    func leavesAFixedAmountUnchanged() throws {
        let amount = try SousParser().amount(in: "Stir in @{=1 tsp} salt@.", scaledBy: 2.0)

        #expect(amount.isFixed)
        #expect(amount.kind.preciseQuantity?.value == 1.0)
        #expect(amount.text == "1 tsp")
    }

    @Test
    func leavesAnImpreciseAmountUnchanged() throws {
        let amount = try SousParser().amount(in: "Stir in @{a pinch} salt@.", scaledBy: 2.0)

        #expect(amount.kind.impreciseText == "a pinch")
        #expect(amount.text == "a pinch")
    }

    @Test
    func leavesAnAbsentAmountAbsent() throws {
        let recipe = try Recipe.read("Season with @salt@.").scaled(by: 2.0)

        #expect(recipe.firstAmount == nil)
    }

    @Test
    func neverScalesATimer() throws {
        let recipe = try Recipe.read("Bake for ~40 min~.").scaled(by: 2.0)

        let timer = try #require(recipe.timers.first)
        #expect(timer.text == "40 min")
        #expect(timer.components.first?.kind.preciseQuantity?.value == 40.0)
    }

    // The declared yield and servings scale with the amounts, so the header still states what
    // the recipe makes.

    @Test
    func scalesTheDeclaredServings() throws {
        let source = "---\nservings: 4\n---\n\nMix @{200 g} flour@."

        let recipe = try Recipe.read(source).scaled(by: 1.5)
        #expect(recipe.metadata.servings == 6.0)
        #expect(recipe.metadata["servings"] == "6")
    }

    @Test
    func scalesEveryDeclaredYield() throws {
        let source = "---\nyield: [6 servings, 3.2 kg]\n---\n\nMix @{200 g} flour@."

        let recipe = try Recipe.read(source).scaled(by: 2.0)
        #expect(recipe.metadata.yields.map(\.text) == ["12 servings", "6.4 kg"])
    }

    @Test
    func scalesAServingsValueThatCarriesAUnit() throws {
        let recipe = try Recipe.read("---\nservings: 6 people\n---").scaled(by: 2.0)

        #expect(recipe.metadata["servings"] == "12 people")
    }

    // Every entry of a repeated key states the same field, so scaling moves them all rather
    // than only the one the accessor reads.

    @Test
    func scalesEveryEntryOfARepeatedField() throws {
        let source = "---\nservings: 4\nservings: 6\nyield: 800 g\nyield: 12 muffins\n---"

        let recipe = try Recipe.read(source).scaled(by: 2.0)
        #expect(recipe.metadata.servings == 12.0)
        #expect(recipe.metadata.entries.map(\.value) == [
            .scalar("8"), .scalar("12"), .list(["1600 g"]), .list(["24 muffins"])
        ])
    }

    // Only the two fields stating how much the recipe makes move. A number anywhere else in
    // the header states something scaling has no business multiplying.

    @Test
    func leavesEveryFieldButTheYieldAndTheServingsAlone() throws {
        let source = "---\nversion: 1.0\ntitle: 3 Bean Stew\ncalories: 640\ntags: [4 star]\n---"

        let recipe = try Recipe.read(source).scaled(by: 2.0)
        #expect(recipe.metadata.version == "1.0")
        #expect(recipe.metadata.title == "3 Bean Stew")
        #expect(recipe.metadata["calories"] == "640")
        #expect(recipe.metadata.tags == ["4 star"])
    }

    @Test
    func leavesAHeaderValueWithNoQuantityAlone() throws {
        let source = "---\nservings: six\nyield: plenty\ntitle: Stew\n---"

        let recipe = try Recipe.read(source).scaled(by: 2.0)
        #expect(recipe.metadata["servings"] == "six")
        #expect(recipe.metadata.yields.map(\.text) == ["plenty"])
        #expect(recipe.metadata.title == "Stew")
    }

    // A step is rewritten only where an amount actually moved, so untouched prose keeps the
    // spacing it was read with.

    @Test
    func rewritesTheTextOfAStepItChanged() throws {
        let source = "Mix @{200 g} flour@ and @{a pinch} salt@."

        let recipe = try Recipe.read(source).scaled(by: 2.0)
        #expect(recipe.steps.first?.text == "Mix @{400 g} flour@ and @{a pinch} salt@.")
    }

    @Test
    func keepsTheTextOfAStepItDidNotChange() throws {
        let source = "Toast the @bread@  slowly with @{=1 tsp} butter@."

        let recipe = try Recipe.read(source).scaled(by: 2.0)
        #expect(recipe.steps.first?.text == source)
    }

    // Rewriting a step writes every segment of it again, so what the reader resolved has to be
    // escaped back, the flags have to survive, and a step of several lines stays several lines.

    @Test
    func reEscapesTheProseOfARewrittenStep() throws {
        let source = "Add @{200 g} water@ then wait \\~5\\~."

        let recipe = try Recipe.read(source).scaled(by: 2.0)
        #expect(recipe.steps.first?.text == "Add @{400 g} water@ then wait \\~5\\~.")
    }

    @Test
    func keepsTheFlagsOfARewrittenStep() throws {
        let source = "Mix @{200 g} flour@:staple? into a #bowl#."

        let recipe = try Recipe.read(source).scaled(by: 2.0)
        #expect(recipe.steps.first?.text == "Mix @{400 g} flour@:staple? into a #bowl#.")
        let ingredient = try #require(recipe.ingredients.first)
        #expect(ingredient.flags.isStaple)
        #expect(ingredient.flags.isOptional)
    }

    @Test(arguments: [
        (source: "Mix @{200 g} flour@\nand @{1 tsp} salt@.", text: "Mix @{400 g} flour@\nand @{2 tsp} salt@."),
        (
            source: "Mix @{200 g} flour@,\nthen rest it,\nthen bake.",
            text: "Mix @{400 g} flour@,\nthen rest it,\nthen bake."
        )
    ])
    func rewritesEveryLineOfAStepItChanged(source: String, text: String) throws {
        #expect(try Recipe.read(source).scaled(by: 2.0).steps.first?.text == text)
    }

    // A group states nothing of its own to multiply, so scaling it is scaling each of its
    // steps, and its heading comes back as it was written.

    @Test
    func keepsTheGroupsOfAScaledRecipe() throws {
        let source = """
        ## Sauce
        Mix @{200 g} flour@.

        ## Topping
        Grate @{50 g} parmesan@.
        """

        let scaled = try Recipe.read(source).scaled(by: 2.0)
        #expect(scaled.groups.map(\.name) == ["Sauce", "Topping"])
        #expect(scaled.serialized() == """
        ## Sauce
        Mix @{400 g} flour@.

        ## Topping
        Grate @{100 g} parmesan@.
        """)
    }

    // A consumption fence is an amount, and scaling is defined over amounts, so it moves with
    // the rest and the fixed marker holds it still.

    @Test(arguments: [
        (source: "Layer the >{300 g} sauce> in a dish.", text: "Layer the >{600 g} sauce> in a dish."),
        (source: "Layer the >{=300 g} sauce> in a dish.", text: "Layer the >{=300 g} sauce> in a dish."),
        (source: "Layer the >{half} sauce> in a dish.", text: "Layer the >{half} sauce> in a dish."),
        (source: "Layer the >sauce> in a dish.", text: "Layer the >sauce> in a dish.")
    ])
    func scalesTheConsumptionFenceOfAReference(source: String, text: String) throws {
        #expect(try Recipe.read(source).scaled(by: 2.0).steps.first?.text == text)
    }

    // A factor of one moves no value, so it rewrites nothing at all: the recipe that comes
    // back is the recipe that went in, incidental spacing included.

    @Test
    func scalingByOneChangesNothing() throws {
        let source = """
        ---
        servings: 4
        yield: [6 servings, 3.2 kg]
        ---

        Mix @{200g} flour@, @{1-2 tbsp} oil@, and @{=1 tsp} salt@ for ~40 min~.
        """

        let recipe = Recipe.read(source)
        #expect(try recipe.scaled(by: 1.0) == recipe)
    }

    // A factor a scaled amount could not be written back from is refused, so scaling never
    // produces a recipe that fails to read as itself. Negative zero belongs among them: it
    // compares equal to zero but writes the sign a negative factor does.

    @Test(arguments: [-1.0, -0.5, -0.0, Double.infinity, -Double.infinity, Double.nan])
    func refusesAFactorItCouldNotWriteBack(factor: Double) {
        let recipe = Recipe.read("Mix @{200 g} flour@.")

        #expect(throws: ScalingError.unusableFactor) {
            try recipe.scaled(by: factor)
        }
    }

    @Test
    func scalingByZeroIsAllowed() throws {
        #expect(try SousParser().amount(in: "Mix @{200 g} flour@.", scaledBy: 0.0).kind.preciseQuantity?.value == 0.0)
    }
}
