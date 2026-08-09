import SousCore
import Testing

@Suite("Specification examples")
struct SpecificationExampleTests {
    /// The source with each `yield` value bracketed, which is the form serializing writes a
    /// single-item list in.
    private func withYieldWritten(_ source: String) -> String {
        let key = "yield: "

        return source.split(separator: "\n", omittingEmptySubsequences: false)
            .map { line in
                line.hasPrefix(key) ? "\(key)[\(line.dropFirst(key.count))]" : String(line)
            }
            .joined(separator: "\n")
    }

    @Test
    func readsTheIntroductoryRecipe() {
        let source = """
        ---
        title: Soupe a l'Oignon
        servings: 4
        ---

        Melt @{50 g} butter@ in a #stockpot# and soften @{1 kg} onions@ with
        @{2 cloves} garlic@ for ~25 min~. Add @{200 ml} white wine@ and
        @{1 l} beef stock@, then simmer for ~20 min~.

        Ladle into bowls, scatter over grated @gruyere@, and season with
        @salt@:staple and @black pepper@:staple.
        """

        let parsed = SousParser().parseRecipe(source)
        let recipe = parsed.value
        #expect(recipe.metadata.title == "Soupe a l'Oignon")
        #expect(recipe.metadata.servings == 4)
        #expect(recipe.steps.count == 2)
        #expect(recipe.ingredients.map(\.name) == [
            "butter", "onions", "garlic", "white wine", "beef stock",
            "gruyere", "salt", "black pepper"
        ])
        #expect(recipe.ingredients.map({ $0.amount?.text }) == [
            "50 g", "1 kg", "2 cloves", "200 ml", "1 l", nil, nil, nil
        ])
        #expect(recipe.cookware.map(\.name) == ["stockpot"])
        #expect(recipe.timers.map(\.text) == ["25 min", "20 min"])
        #expect(recipe.timers.allSatisfy({ $0.kind == .precise }))
        #expect(recipe.ingredients.suffix(2).map(\.flags.isStaple) == [true, true])
        #expect(parsed.diagnostics.isEmpty)
        #expect(recipe.serialized() == source)
    }

    @Test
    func readsTheIngredientsPageRecipe() throws {
        let source = """
        ---
        title: Sole Meuniere
        servings: 2
        ---

        Dust @{50 g} flour@ over a plate and season it well.
        Melt @{80 g} butter@ in a #frying pan#, fry @{2} sole fillets@, and add @lemon@?.
        Lift them out with a #fish slice#, season with @salt@:staple, and scatter over @parsley@.
        """

        let parsed = SousParser().parseRecipe(source)
        let recipe = parsed.value
        #expect(recipe.ingredients.map(\.name)
            == ["flour", "butter", "sole fillets", "lemon", "salt", "parsley"])
        #expect(recipe.cookware.map(\.name) == ["frying pan", "fish slice"])
        #expect(recipe.steps.count == 1)

        let flour = try #require(recipe.ingredients.first?.amount)
        #expect(flour.kind.preciseQuantity?.value == 50)
        #expect(flour.unit == "g")

        #expect(recipe.ingredients.map(\.flags.isOptional) == [false, false, false, true, false, false])
        #expect(recipe.ingredients.map(\.flags.isStaple) == [false, false, false, false, true, false])
        #expect(parsed.diagnostics.isEmpty)
        #expect(recipe.serialized() == source)
    }

    @Test
    func readsTheQuicheLorraineExample() {
        let source = """
        ---
        title: Quiche Lorraine
        language: en
        version: 1.0
        servings: 6
        prep-time: 25 min
        cook-time: 35 min
        tags: [lunch, classic, french]
        allergens: [gluten, dairy]
        ---

        Whisk @{3} eggs@ with @salt@:staple and @black pepper@:staple until just combined.

        Fry @{150 g} lardons@ in a #frying pan# over medium heat, then stir them through
        @{200 ml} cream@ and the eggs, resting the mixture ~2-3 min~.

        Pour into the pastry case, scatter over grated @gruyere@?, and bake until just set.
        """

        let parsed = SousParser().parseRecipe(source)
        let recipe = parsed.value
        #expect(recipe.metadata.title == "Quiche Lorraine")
        #expect(recipe.metadata.servings == 6)
        #expect(recipe.steps.count == 3)
        #expect(recipe.ingredients.map(\.name)
            == ["eggs", "salt", "black pepper", "lardons", "cream", "gruyere"])
        #expect(recipe.cookware.map(\.name) == ["frying pan"])
        #expect(recipe.timers.map(\.kind) == [.range])
        #expect(recipe.ingredients.last?.flags.isOptional == true)

        let staples = recipe.ingredients.filter(\.flags.isStaple)
        #expect(staples.map(\.name) == ["salt", "black pepper"])

        #expect(recipe.metadata["prep-time"] == "25 min")
        #expect(parsed.diagnostics.isEmpty)
        #expect(recipe.serialized() == source)
    }

    @Test
    func readsTheTimersPageExample() {
        let source = """
        Bring the brioche dough together and refrigerate ~overnight~ (or up to ~2 days~).
        The next day, prove until puffy, about ~1-2 h~, then bake for ~20-25 min~.
        """

        let parsed = SousParser().parseRecipe(source)
        let recipe = parsed.value
        #expect(recipe.timers.map(\.text) == ["overnight", "2 days", "1-2 h", "20-25 min"])
        #expect(recipe.timers.map(\.kind) == [.qualitative, .precise, .range, .range])
        #expect(recipe.timers.dropFirst().compactMap({ $0.components.first?.unit }) == ["days", "h", "min"])
        #expect(parsed.diagnostics.isEmpty)
        #expect(recipe.serialized() == source)
    }

    @Test
    func preservesEveryFieldOfTheFullHeaderExample() {
        let source = """
        ---
        title: Gratin Dauphinois
        language: en
        version: 1.0
        servings: 6
        yield: 3.2 kg
        tags: [comfort food, french, make-ahead]
        diet: [vegetarian]
        allergens: [dairy]
        source: https://example.com/gratin-dauphinois
        author: Jane Doe
        license: CC-BY-4.0
        image: images/gratin.jpg
        prep-time: 40 min
        cook-time: 45 min
        make-ahead: best assembled a day ahead and baked from cold
        nutrition:
          calories: 3840 kcal
          protein: 174 g
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        let metadata = parsed.value.metadata
        #expect(metadata.title == "Gratin Dauphinois")
        #expect(metadata.language == "en")
        #expect(metadata.version == "1.0")
        #expect(metadata.servings == 6)
        #expect(metadata.tags == ["comfort food", "french", "make-ahead"])
        #expect(metadata.source == "https://example.com/gratin-dauphinois")

        #expect(metadata.yields.map(\.text) == ["3.2 kg"])

        #expect(metadata["diet"] == "[vegetarian]")
        #expect(metadata["prep-time"] == "40 min")
        #expect(metadata["nutrition"]?.isEmpty == true)
        #expect(metadata.entries.contains(where: { $0.value == .raw("  calories: 3840 kcal") }))
        #expect(parsed.diagnostics.allSatisfy({ $0.severity == .warning }))

        let written = parsed.value.serialized()
        #expect(written == withYieldWritten(source))
        #expect(Recipe.read(written).serialized() == written)
    }

    @Test(arguments: [
        "Toast the baguette and spread it with butter.",
        "---\ntitle: Tartine Beurree\n---",
        "---\ntitle: Tartine Beurree\nservings: 1\n---\n\nToast @{2 slices} baguette@ until golden."
    ])
    func readsEverySmallestRecipe(source: String) {
        let parsed = SousParser().parseRecipe(source)

        #expect(parsed.diagnostics.isEmpty)
        #expect(parsed.value.serialized() == source)
    }

    @Test
    func readsTheGroupsExample() throws {
        let source = """
        ---
        title: Tarte Tatin
        servings: 6
        yield: 1 tart
        prep-time: 20 min
        cook-time: 40 min
        tags: [dessert, french]
        allergens: [gluten, dairy]
        ---

        ## Caramel
        Melt @{150 g} caster sugar@ with @{100 g} butter@ and pack in @{1.2 kg} apples@
        in an #ovenproof skillet#.

        ## Pastry
        Roll @{320 g} puff pastry@ into a round, dust it with @{20 g} flour@, brush it
        with @{1} egg@, and add a pinch of @salt@.

        ## Assemble
        Set the >caramel> aside to cool, lay the >pastry> over it, and bake at 190C for
        ~35-40 min~ until golden. Rest ~10 min~ on a #wire rack# before turning out.
        """

        let parsed = SousParser().parseRecipe(source)
        let recipe = parsed.value
        #expect(recipe.metadata.title == "Tarte Tatin")
        #expect(recipe.metadata.servings == 6)
        #expect(recipe.ingredients.map(\.name) == [
            "caster sugar", "butter", "apples", "puff pastry", "flour", "egg", "salt"
        ])
        #expect(recipe.cookware.map(\.name) == ["ovenproof skillet", "wire rack"])
        #expect(recipe.timers.map(\.text) == ["35-40 min", "10 min"])
        #expect(recipe.timers.map(\.kind) == [.range, .precise])
        #expect(recipe.metadata.yields.map(\.text) == ["1 tart"])

        #expect(recipe.groups.map(\.name) == ["Caramel", "Pastry", "Assemble"])
        #expect(recipe.groups.map({ $0.ingredients.map(\.name) }) == [
            ["caster sugar", "butter", "apples"],
            ["puff pastry", "flour", "egg", "salt"],
            []
        ])

        let assemble = try #require(recipe.groups.last)
        #expect(assemble.references.map(\.target) == ["caramel", "pastry"])
        #expect(recipe.dependencies(of: assemble).map(\.name) == ["Caramel", "Pastry"])
        #expect(recipe.validate().isEmpty)

        #expect(parsed.diagnostics.isEmpty)

        #expect(recipe.serialized() == withYieldWritten(source))
    }

    @Test
    func readsTheReferenceExampleWrittenForALaterVersion() throws {
        let source = """
        ---
        title: Croque Monsieur
        servings: 6
        prep-time: 25 min
        cook-time: 30 min
        tags: [french, lunch, classic]
        allergens: [gluten, dairy]
        ---

        Toast @{12 slices} pain de mie@ in a #frying pan# for ~2-3 min~, then set them aside.

        Grate @{250 g} gruyere@ and spread the slices with >{600 g} bechamel> and half of it.
        Layer them in a #baking dish#, scatter over the rest, and grill for ~5-8 min~.
        """

        let parsed = SousParser().parseRecipe(source)
        let recipe = parsed.value
        #expect(recipe.ingredients.map(\.name) == ["pain de mie", "gruyere"])
        #expect(recipe.cookware.map(\.name) == ["frying pan", "baking dish"])
        #expect(recipe.timers.map(\.kind) == [.range, .range])

        let reference = try #require(recipe.references.first)
        #expect(reference.target == "bechamel")
        #expect(reference.amount?.text == "600 g")

        #expect(recipe.validate().map(\.kind) == [.unresolvedReference])
        #expect(parsed.diagnostics.isEmpty)
        #expect(recipe.serialized() == source)
    }
}
