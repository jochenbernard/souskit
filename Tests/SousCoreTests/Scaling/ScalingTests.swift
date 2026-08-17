import SousCore
import Testing

@Suite("Scaling by a factor")
struct ScalingTests {
    @Test
    func multipliesAPreciseAmount() throws {
        let amount = try SousParser().amount(in: "Mix @{200 g} flour@.", scaledBy: 1.5)

        #expect(amount.kind.preciseQuantity?.value == 300.0)
        #expect(amount.unit == "g")
    }

    @Test
    func multipliesAnAmountWithNoUnit() throws {
        let amount = try SousParser().amount(in: "Whisk @{3} eggs@.", scaledBy: 2.0)

        #expect(amount.kind.preciseQuantity?.value == 6.0)
        #expect(amount.unit == nil)
        #expect(amount.text == "6")
    }

    @Test
    func multipliesBothEndsOfARange() throws {
        let amount = try SousParser().amount(in: "Add @{1-2 tbsp} olive oil@.", scaledBy: 2.0)

        #expect(amount.kind.rangeQuantities?.low.value == 2.0)
        #expect(amount.kind.rangeQuantities?.high.value == 4.0)
    }

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

    @Test
    func scalesEveryEntryOfARepeatedField() throws {
        let source = "---\nservings: 4\nservings: 6\nyield: 800 g\nyield: 12 madeleines\n---"

        let recipe = try Recipe.read(source).scaled(by: 2.0)
        #expect(recipe.metadata.servings == 12.0)
        #expect(recipe.metadata.entries.map(\.value) == [
            .scalar("8"), .scalar("12"), .list(["1600 g"]), .list(["24 madeleines"])
        ])
    }

    @Test
    func leavesEveryFieldButTheYieldAndTheServingsAlone() throws {
        let source = "---\nversion: 1.0\ncalories: 550\ntags: [4 star, make-ahead]\n---"

        let recipe = try Recipe.read(source).scaled(by: 2.0)
        #expect(recipe.metadata.version == "1.0")
        #expect(recipe.metadata["calories"] == "550")
        #expect(recipe.metadata.tags == ["4 star", "make-ahead"])
    }

    @Test
    func leavesAHeaderValueWithNoQuantityAlone() throws {
        let source = "---\nservings: six\nyield: plenty\ntitle: Bouillabaisse\n---"

        let recipe = try Recipe.read(source).scaled(by: 2.0)
        #expect(recipe.metadata["servings"] == "six")
        #expect(recipe.metadata.yields.map(\.text) == ["plenty"])
        #expect(recipe.metadata.title == "Bouillabaisse")
    }

    @Test
    func rewritesTheTextOfAStepItChanged() throws {
        let source = "Mix @{200 g} flour@ and @{a pinch} salt@."

        let recipe = try Recipe.read(source).scaled(by: 2.0)
        #expect(recipe.steps.first?.text == "Mix @{400 g} flour@ and @{a pinch} salt@.")
    }

    @Test
    func keepsTheTextOfAStepItDidNotChange() throws {
        let source = "Whisk the @dijon mustard@ slowly with @{=1 tsp}  salt@."

        let recipe = try Recipe.read(source).scaled(by: 2.0)
        #expect(recipe.steps.first?.text == source)
    }

    @Test
    func reEscapesTheProseOfARewrittenStep() throws {
        let source = "Add @{200 g} cream@ then wait \\~5\\~."

        let recipe = try Recipe.read(source).scaled(by: 2.0)
        #expect(recipe.steps.first?.text == "Add @{400 g} cream@ then wait \\~5\\~.")
    }

    @Test
    func keepsTheFlagsOfARewrittenStep() throws {
        let source = "Mix @{200 g} flour@:staple? into a #mixing bowl#."

        let recipe = try Recipe.read(source).scaled(by: 2.0)
        #expect(recipe.steps.first?.text == "Mix @{400 g} flour@:staple? into a #mixing bowl#.")
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

    @Test
    func keepsTheGroupsOfAScaledRecipe() throws {
        let source = """
        ## Pastry
        Mix @{200 g} flour@.

        ## Filling
        Grate @{50 g} gruyere@.
        """

        let scaled = try Recipe.read(source).scaled(by: 2.0)
        #expect(scaled.groups.map(\.name) == ["Pastry", "Filling"])
        #expect(scaled.serialized() == """
        ## Pastry
        Mix @{400 g} flour@.

        ## Filling
        Grate @{100 g} gruyere@.
        """)
    }

    @Test
    func keepsTheStepsOfAGroupInTheOrderTheyWereRead() throws {
        let source = "Mix @{200 g} flour@.\n\nWhisk @{4} eggs@ into it."

        let scaled = try Recipe.read(source).scaled(by: 2.0)
        #expect(scaled.steps.map(\.text) == ["Mix @{400 g} flour@.", "Whisk @{8} eggs@ into it."])
    }

    @Test(arguments: [
        (source: "Layer the >{300 g} bechamel> in a dish.", text: "Layer the >{600 g} bechamel> in a dish."),
        (source: "Layer the >{=300 g} bechamel> in a dish.", text: "Layer the >{=300 g} bechamel> in a dish."),
        (source: "Layer the >{half} bechamel> in a dish.", text: "Layer the >{half} bechamel> in a dish."),
        (source: "Layer the >bechamel> in a dish.", text: "Layer the >bechamel> in a dish.")
    ])
    func scalesTheConsumptionFenceOfAReference(source: String, text: String) throws {
        #expect(try Recipe.read(source).scaled(by: 2.0).steps.first?.text == text)
    }

    @Test
    func scalingByOneChangesNothing() throws {
        let source = """
        ---
        servings: 4
        yield: [6 servings, 3.2 kg]
        ---

        Mix @{200g} flour@, @{1-2 tbsp} olive oil@, and @{=1 tsp} salt@ for ~40 min~.
        """

        let recipe = Recipe.read(source)
        #expect(try recipe.scaled(by: 1.0) == recipe)
    }

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
