import SousCore
import Testing

@Suite("Recipe examples")
struct RecipeExampleTests {
    @Test(arguments: [
        Recipes.boeufBourguignon,
        Recipes.moulesMarinieres,
        Recipes.quicheLorraine,
        Recipes.gratinDauphinois,
        Recipes.vinaigrette,
        Recipes.bouillabaisse,
        Recipes.croqueMonsieur,
        Recipes.brioche,
        Recipes.crepes,
        Recipes.madeleines
    ])
    func writesEveryRecipeBackAsItWasRead(source: String) {
        let parsed = SousParser().parseRecipe(source)

        #expect(parsed.value.serialized() == source)
        #expect(parsed.value.reRead() == parsed.value)
    }

    @Test(arguments: [
        Recipes.boeufBourguignon,
        Recipes.moulesMarinieres,
        Recipes.quicheLorraine,
        Recipes.vinaigrette,
        Recipes.bouillabaisse,
        Recipes.brioche,
        Recipes.crepes,
        Recipes.madeleines
    ])
    func readsEveryRecipeWithoutComplaint(source: String) {
        let parsed = SousParser().parseRecipe(source)

        #expect(parsed.diagnostics.isEmpty)
        #expect(parsed.value.validate().isEmpty)
    }

    @Test
    func readsTheBraise() {
        let parsed = SousParser().parseRecipe(Recipes.boeufBourguignon)
        let recipe = parsed.value
        #expect(recipe.metadata.title == "Boeuf Bourguignon")
        #expect(recipe.metadata.servings == 6)
        #expect(recipe.steps.count == 4)
        #expect(recipe.ingredients.map(\.name) == [
            "beef", "lardons", "flour", "garlic", "thyme", "red wine", "beef stock",
            "pearl onions", "button mushrooms", "butter", "salt", "black pepper"
        ])
        #expect(recipe.ingredients.prefix(4).map({ $0.amount?.text }) == ["1.2 kg", "150 g", "2 tbsp", "3 cloves"])
        #expect(recipe.ingredients.suffix(2).allSatisfy({ $0.amount == nil }))
        #expect(recipe.cookware.map(\.name) == ["casserole", "frying pan"])
        #expect(recipe.timers.map(\.text) == ["5 min", "3 min", "3 h", "20 min"])
        #expect(recipe.timers.allSatisfy({ $0.kind == .precise }))
        #expect(recipe.ingredients.suffix(2).map(\.flags.isStaple) == [true, true])
    }

    @Test
    func readsTheQuickDish() throws {
        let recipe = Recipe.read(Recipes.moulesMarinieres)
        #expect(recipe.ingredients.map(\.name) == [
            "mussels", "shallots", "garlic", "butter", "white wine", "cream", "black pepper", "parsley"
        ])
        #expect(recipe.cookware.map(\.name) == ["heavy pot", "slotted spoon"])
        #expect(recipe.timers.map(\.kind) == [.precise, .range])
        #expect(recipe.steps.count == 4)

        let mussels = try #require(recipe.firstAmount)
        #expect(mussels.kind.preciseQuantity?.value == 2)
        #expect(mussels.unit == "kg")

        #expect(recipe.ingredients.map(\.flags.isOptional) == [false, false, false, false, false, true, false, false])
        #expect(recipe.ingredients.map(\.flags.isStaple) == [false, false, false, false, false, false, true, false])
    }

    @Test
    func readsTheTart() throws {
        let recipe = Recipe.read(Recipes.quicheLorraine)
        #expect(recipe.metadata.title == "Quiche Lorraine")
        #expect(recipe.metadata.language == "en")
        #expect(recipe.metadata.tags == ["lunch", "classic", "french"])
        #expect(recipe.metadata["prep-time"] == "30 min")
        #expect(recipe.groups.map(\.name) == ["Pastry", "Filling", "Assemble"])
        #expect(recipe.groups.map({ $0.cookware.map(\.name) })
            == [["mixing bowl"], ["frying pan"], ["tart tin"]])
        #expect(recipe.timers.map(\.kind) == [.precise, .range, .precise, .precise])
        #expect(recipe.ingredients.last?.flags.isOptional == true)

        #expect(recipe.ingredients.filter(\.flags.isNonFood).map(\.name) == ["parchment", "baking beans"])

        let assemble = try #require(recipe.groups.last)
        #expect(assemble.references.map(\.target) == ["pastry", "filling"])
        #expect(recipe.dependencies(of: assemble).map(\.name) == ["Pastry", "Filling"])
    }

    @Test
    func preservesEveryFieldOfTheFullHeader() {
        let parsed = SousParser().parseRecipe(Recipes.gratinDauphinois)
        let metadata = parsed.value.metadata
        #expect(metadata.title == "Gratin Dauphinois")
        #expect(metadata.version == "1.0")
        #expect(metadata.servings == 6)
        #expect(metadata.tags == ["comfort food", "french", "make-ahead"])
        #expect(metadata.source == "https://example.com/gratin-dauphinois")
        #expect(metadata.yields.map(\.text) == ["1.8 kg"])
        #expect(metadata["diet"] == "[vegetarian]")
        #expect(metadata["make-ahead"] == "best assembled a day ahead and baked from cold")
        #expect(metadata["nutrition"]?.isEmpty == true)
        #expect(metadata.entries.contains(where: { $0.value == .raw("  calories: 3300 kcal") }))
        #expect(parsed.diagnostics.map(\.kind) == [.malformedHeaderLine, .malformedHeaderLine])
        #expect(parsed.diagnostics.allSatisfy({ $0.severity == .warning }))
        #expect(parsed.value.validate().isEmpty)
        #expect(parsed.value.timers.map(\.kind) == [.compound, .precise])
    }

    @Test
    func readsTheSauce() {
        let recipe = Recipe.read(Recipes.vinaigrette)
        #expect(recipe.metadata.title == "Vinaigrette")
        #expect(recipe.metadata.servings == nil)
        #expect(recipe.metadata.yields.map(\.text) == ["125 ml"])
        #expect(recipe.steps.count == 2)
        #expect(recipe.ingredients.map(\.name)
            == ["dijon mustard", "red wine vinegar", "salt", "olive oil", "black pepper"])
        #expect(recipe.cookware.isEmpty)
        #expect(recipe.timers.isEmpty)
    }

    @Test
    func readsTheStewAndItsIntermediates() throws {
        let recipe = Recipe.read(Recipes.bouillabaisse)
        #expect(recipe.metadata.yields.map(\.text) == ["4.5 l"])
        #expect(recipe.groups.map(\.name) == ["Court-Bouillon", "Rouille", "Assemble"])
        #expect(recipe.groups.map(\.ingredients.count) == [8, 6, 2])
        #expect(recipe.cookware.map(\.name) == ["stockpot", "mortar", "soup bowls", "ladle"])
        #expect(recipe.timers.map(\.kind) == [.precise, .range, .range])

        let saffron = try #require(recipe.ingredients.first(where: { $0.name == "saffron" }))
        #expect(saffron.amount?.isFixed == true)
        #expect(saffron.amount?.text == "1 tsp")

        let assemble = try #require(recipe.groups.last)
        #expect(assemble.references.map(\.target) == ["court-bouillon", "rouille"])
        #expect(recipe.dependencies(of: assemble).map(\.name) == ["Court-Bouillon", "Rouille"])
    }

    @Test
    func readsTheReferenceNoGroupOfTheFileProduces() throws {
        let parsed = SousParser().parseRecipe(Recipes.croqueMonsieur)
        let recipe = parsed.value
        #expect(recipe.ingredients.map(\.name) == ["pain de mie", "butter", "ham", "gruyere"])
        #expect(recipe.cookware.map(\.name) == ["frying pan", "baking dish"])
        #expect(recipe.timers.map(\.kind) == [.range, .range])

        let reference = try #require(recipe.firstReference)
        #expect(reference.target == "bechamel")
        #expect(reference.amount?.text == "400 g")

        #expect(recipe.validate().map(\.kind) == [.unresolvedReference])
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsEveryFormOfDurationTheDoughRests() {
        let recipe = Recipe.read(Recipes.brioche)
        #expect(recipe.timers.map(\.text) == ["overnight", "2 days", "2-3 h", "45-55 min"])
        #expect(recipe.timers.map(\.kind) == [.qualitative, .precise, .range, .range])
        #expect(recipe.timers.dropFirst().compactMap({ $0.components.first?.unit }) == ["days", "h", "min"])
        #expect(recipe.ingredients.first(where: { $0.name == "yeast" })?.amount?.isFixed == true)
    }

    @Test(arguments: [
        (source: Recipes.crepes, yield: "12 crepes", servings: 4.0),
        (source: Recipes.madeleines, yield: "12 madeleines", servings: 6.0)
    ])
    func readsACountableYieldAlongsideServings(
        source: String,
        yield: String,
        servings: Double
    ) {
        let recipe = Recipe.read(source)

        #expect(recipe.metadata.yields.map(\.text) == [yield])
        #expect(recipe.metadata.servings == servings)
        #expect(recipe.validate().isEmpty)
    }
}
