import SousCore
import Testing

// The complete files the Sous documentation works through, read back here so the
// outcomes it states stay the outcomes this reader produces. Each also round-trips byte
// for byte, including the constructs later versions introduce, which a v0.2 reader
// carries through as ordinary prose.

@Suite("Specification examples")
struct SpecificationExampleTests {
    @Test
    func readsTheIntroductoryRecipe() {
        let source = """
        ---
        title: Tomato Basil Soup
        servings: 4
        ---

        Warm @{2 tbsp} olive oil@ in a #large pot# and soften @{1} onion@ with
        @{2 cloves} garlic@ for ~5 min~. Add @{800 g} chopped tomatoes@ and
        @{500 ml} vegetable stock@, then simmer for ~20 min~.

        Blend until smooth, stir through a handful of @basil@, and season with
        @salt@:staple and @black pepper@:staple.
        """

        let parsed = SousParser().parseRecipe(source)
        let recipe = parsed.value
        #expect(recipe.metadata.title == "Tomato Basil Soup")
        #expect(recipe.metadata.servings == 4)
        #expect(recipe.steps.count == 2)
        #expect(recipe.ingredients.map(\.name) == [
            "olive oil", "onion", "garlic", "chopped tomatoes", "vegetable stock",
            "basil", "salt", "black pepper"
        ])
        #expect(recipe.ingredients.map({ $0.amount?.text }) == [
            "2 tbsp", "1", "2 cloves", "800 g", "500 ml", nil, nil, nil
        ])
        #expect(recipe.cookware.map(\.name) == ["large pot"])
        #expect(recipe.timers.map(\.text) == ["5 min", "20 min"])
        #expect(recipe.timers.allSatisfy({ $0.kind == .precise }))
        #expect(recipe.ingredients.suffix(2).map(\.flags.isStaple) == [true, true])
        #expect(parsed.diagnostics.isEmpty)
        #expect(recipe.serialized() == source)
    }

    @Test
    func readsTheIngredientsPageRecipe() throws {
        let source = """
        ---
        title: Garlic Butter Pasta
        servings: 2
        ---

        Bring a #large pot# of salted water to a boil and cook @{200 g} spaghetti@.
        Melt @{30 g} butter@ in a #pan#, fry @{2 cloves} garlic@, and add @chili flakes@?.
        Toss the pasta, season with @salt@:staple, and finish with grated @parmesan@.
        """

        let parsed = SousParser().parseRecipe(source)
        let recipe = parsed.value
        // "Grated" sits outside the span, so the ingredient resolves as plain parmesan.
        #expect(recipe.ingredients.map(\.name)
            == ["spaghetti", "butter", "garlic", "chili flakes", "salt", "parmesan"])
        #expect(recipe.cookware.map(\.name) == ["large pot", "pan"])
        #expect(recipe.steps.count == 1)

        let spaghetti = try #require(recipe.ingredients.first?.amount)
        #expect(spaghetti.kind.preciseQuantity?.value == 200)
        #expect(spaghetti.unit == "g")

        // Chili flakes are optional and salt is a staple; nothing else carries a flag.
        #expect(recipe.ingredients.map(\.flags.isOptional) == [false, false, false, true, false, false])
        #expect(recipe.ingredients.map(\.flags.isStaple) == [false, false, false, false, true, false])
        #expect(parsed.diagnostics.isEmpty)
        #expect(recipe.serialized() == source)
    }

    @Test
    func readsTheHerbOmeletteExample() {
        let source = """
        ---
        title: Herb Omelette
        language: en
        version: 1.0
        servings: 1
        prep-time: 5 min
        cook-time: 5 min
        tags: [breakfast, quick, vegetarian]
        diet: [vegetarian]
        ---

        Whisk @{3} eggs@ with @salt@:staple and @black pepper@:staple until just combined.

        Melt @{15 g} butter@ in a #non-stick pan# over medium heat. Pour in the eggs and
        cook ~2-3 min~, drawing the edges in, until almost set.

        Scatter over chopped @{2 tbsp} chives@ and grated @cheese@?, fold, and serve.
        """

        let parsed = SousParser().parseRecipe(source)
        let recipe = parsed.value
        #expect(recipe.metadata.title == "Herb Omelette")
        #expect(recipe.metadata.servings == 1)
        #expect(recipe.steps.count == 3)
        #expect(recipe.ingredients.map(\.name)
            == ["eggs", "salt", "black pepper", "butter", "chives", "cheese"])
        #expect(recipe.cookware.map(\.name) == ["non-stick pan"])
        #expect(recipe.timers.map(\.kind) == [.range])
        #expect(recipe.ingredients.last?.flags.isOptional == true)

        let staples = recipe.ingredients.filter(\.flags.isStaple)
        #expect(staples.map(\.name) == ["salt", "black pepper"])

        // The three fields later versions introduce, `prep-time`, `cook-time`, and `diet`, are
        // unknown here, so each is preserved and warned about rather than dropped.
        #expect(recipe.metadata["prep-time"] == "5 min")
        #expect(parsed.diagnostics.count == 3)
        #expect(parsed.diagnostics.allSatisfy({ $0.kind == .unknownHeaderKey && $0.severity == .warning }))
        #expect(recipe.serialized() == source)
    }

    @Test
    func readsTheTimersPageExample() {
        let source = """
        Bring the dough together and refrigerate ~overnight~ (or up to ~2 days~).
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
        title: Vegetable Lasagna
        language: en
        version: 1.0
        servings: 6
        yield: 3.2 kg
        tags: [comfort food, italian, make-ahead]
        diet: [vegetarian]
        allergens: [gluten, dairy]
        source: https://example.com/veg-lasagna
        author: Jane Doe
        license: CC-BY-4.0
        image: images/lasagna.jpg
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
        #expect(metadata.title == "Vegetable Lasagna")
        #expect(metadata.language == "en")
        #expect(metadata.version == "1.0")
        #expect(metadata.servings == 6)
        #expect(metadata.tags == ["comfort food", "italian", "make-ahead"])
        #expect(metadata.source == "https://example.com/veg-lasagna")

        // A field a later version introduces is preserved as written, brackets included,
        // because only a list field of this version reads them as a list.
        #expect(metadata["yield"] == "3.2 kg")
        #expect(metadata["diet"] == "[vegetarian]")
        #expect(metadata["prep-time"] == "40 min")
        #expect(metadata["nutrition"]?.isEmpty == true)
        #expect(metadata.entries.contains(where: { $0.value == .raw("  calories: 3840 kcal") }))
        #expect(parsed.diagnostics.allSatisfy({ $0.severity == .warning }))
        #expect(parsed.value.serialized() == source)
    }

    @Test(arguments: [
        "Toast the bread and spread it with butter.",
        "---\ntitle: Buttered Toast\n---",
        "---\ntitle: Buttered Toast\nservings: 1\n---\n\nToast @{2 slices} bread@ until golden."
    ])
    func readsEverySmallestRecipe(source: String) {
        let parsed = SousParser().parseRecipe(source)

        #expect(parsed.diagnostics.isEmpty)
        #expect(parsed.value.serialized() == source)
    }

    // A file written for a later version still opens here, degrading gracefully: the group
    // headings and references it carries are ordinary prose, its unknown header keys are
    // preserved and warned about, and everything this version does read is read in full.

    @Test
    func readsTheGroupsExampleWrittenForALaterVersion() {
        let source = """
        ---
        title: Berry Crumble
        servings: 6
        yield: 1 dish
        prep-time: 20 min
        cook-time: 35 min
        tags: [dessert, baking]
        allergens: [gluten, dairy]
        ---

        ## Filling
        Toss @{600 g} mixed berries@ with @{50 g} sugar@ and @{1 tbsp} cornflour@ in a #bowl#.

        ## Crumble
        Rub cold @{100 g} butter@ into @{150 g} flour@ until sandy, then stir through
        @{75 g} sugar@ and @{50 g} rolled oats@.

        ## Assemble
        Spread the >filling> into a #baking dish#, scatter the >crumble> over the top, and
        bake at 190C for ~35-40 min~ until golden. Rest ~10 min~ before serving.
        """

        let parsed = SousParser().parseRecipe(source)
        let recipe = parsed.value
        #expect(recipe.metadata.title == "Berry Crumble")
        #expect(recipe.metadata.servings == 6)
        #expect(recipe.ingredients.map(\.name) == [
            "mixed berries", "sugar", "cornflour", "butter", "flour", "sugar", "rolled oats"
        ])
        #expect(recipe.cookware.map(\.name) == ["bowl", "baking dish"])
        #expect(recipe.timers.map(\.text) == ["35-40 min", "10 min"])
        #expect(recipe.timers.map(\.kind) == [.range, .precise])

        // The four header keys later versions introduce are the only thing to report.
        #expect(parsed.diagnostics.map(\.kind) == Array(repeating: .unknownHeaderKey, count: 4))
        #expect(recipe.serialized() == source)
    }

    @Test
    func readsTheReferenceExampleWrittenForALaterVersion() {
        let source = """
        ---
        title: Baked Ziti
        servings: 6
        prep-time: 25 min
        cook-time: 30 min
        tags: [italian, pasta, comfort food]
        allergens: [gluten, dairy]
        ---

        Cook @{500 g} ziti@ in a #large pot# of salted water for ~9-11 min~, then drain.

        Grate @{250 g} mozzarella@ and stir the pasta through >{600 g} ragu> with half of it.
        Tip into a #baking dish#, scatter over the rest, and bake at 200C for ~25-30 min~.
        """

        let parsed = SousParser().parseRecipe(source)
        let recipe = parsed.value
        // The reference and its consumption fence are prose, so neither is read as an
        // ingredient and neither is altered on the way out.
        #expect(recipe.ingredients.map(\.name) == ["ziti", "mozzarella"])
        #expect(recipe.cookware.map(\.name) == ["large pot", "baking dish"])
        #expect(recipe.timers.map(\.kind) == [.range, .range])
        #expect(parsed.diagnostics.allSatisfy({ $0.kind == .unknownHeaderKey }))
        #expect(recipe.serialized() == source)
    }
}
