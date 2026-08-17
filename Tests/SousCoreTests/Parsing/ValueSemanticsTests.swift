import SousCore
import Testing

@Suite("Value semantics")
struct ValueSemanticsTests {
    /// One parser shared across tests, so its use from another isolation domain is exercised.
    private static let parser = SousParser()

    @Test
    func sharesOneParserAcrossIsolationDomains() async {
        let recipe = await Task.detached { Self.parser.parseRecipe("Fry @garlic@ in a #casserole#.").value }.value

        #expect(recipe.ingredients.map(\.name) == ["garlic"])
        #expect(recipe.cookware.map(\.name) == ["casserole"])
    }

    @Test
    func comparesTwoParsesOfTheSameSource() {
        let source = "---\ntitle: Vinaigrette\n---\n\nFry @garlic@ in a #casserole#."
        let first = Self.parser.parseRecipe(source)
        let second = Self.parser.parseRecipe(source)

        #expect(first == second)
    }

    @Test
    func distinguishesParsesOfDifferentSources() {
        #expect(Self.parser.parseRecipe("Fry @garlic@.") != Self.parser.parseRecipe("Fry @onions@."))
    }

    @Test
    func distinguishesParsesThatDifferOnlyInTheirDiagnostics() {
        let clean = Self.parser.parseRecipe("Fry @garlic@.")
        var warned = clean
        warned.diagnostics = Self.parser.parseRecipe("Fry @garlic until fragrant.").diagnostics

        #expect(!warned.diagnostics.isEmpty)
        #expect(warned.value == clean.value)
        #expect(warned != clean)
    }

    @Test
    func distinguishesAmountsThatDifferOnlyInTheirText() throws {
        let amount = try #require(Self.parser.parseRecipe("Sift @{200 g} flour@.").value.firstAmount)
        var spaced = amount
        spaced.text = "200  g"

        #expect(spaced != amount)
    }

    @Test
    func distinguishesAmountsThatDifferOnlyInTheirFixedMarker() throws {
        let amount = try #require(Self.parser.parseRecipe("Stir in @{1 tsp} salt@.").value.firstAmount)
        var fixed = amount
        fixed.isFixed = true

        #expect(fixed != amount)
    }

    @Test
    func distinguishesStepsThatDifferOnlyInTheirText() throws {
        let step = try #require(Self.parser.parseRecipe("Whisk the vinegar.").value.firstStep)
        var rewritten = step
        rewritten.text = "Whisk the vinegar"

        #expect(rewritten != step)
    }

    @Test
    func distinguishesTimersThatDifferOnlyInTheirText() throws {
        let timer = try #require(Self.parser.parseRecipe("Simmer ~40 min~ gently.").value.firstTimer)
        var rewritten = timer
        rewritten.text = "40  min"

        #expect(rewritten != timer)
    }

    @Test
    func distinguishesIngredientsThatDifferOnlyInTheirFlags() throws {
        let ingredient = try #require(Self.parser.parseRecipe("Season with @salt@.").value.firstIngredient)
        var staple = ingredient
        staple.flags.isStaple = true

        #expect(staple != ingredient)
    }

    @Test
    func distinguishesFlagsThatDifferOnlyInWhatTheyDoNotRecognize() throws {
        let ingredient = try #require(
            Self.parser.parseRecipe("Add @beef stock@:homemade now.").value.firstIngredient
        )
        var dropped = ingredient.flags
        dropped.unrecognized = []

        #expect(dropped != ingredient.flags)
    }

    @Test
    func distinguishesRecipesThatDifferOnlyInTheirMetadata() {
        let recipe = Self.parser.parseRecipe("---\ntitle: Vinaigrette\n---\n\nWhisk the vinegar.").value
        var retitled = recipe
        retitled.metadata.entries[0].value = .scalar("Bouillabaisse")

        #expect(retitled != recipe)
    }

    @Test
    func distinguishesGroupsThatDifferOnlyInTheirName() throws {
        let group = try #require(Self.parser.parseRecipe("## Pastry\nRub in the butter.").value.groups.first)
        var renamed = group
        renamed.name = "Filling"

        #expect(renamed != group)
    }

    @Test
    func distinguishesDiagnosticsThatDifferOnlyInTheirRange() throws {
        let diagnostic = try Self.parser.parseRecipe("Fry @garlic until fragrant.")
            .firstDiagnostic(ofKind: .unclosedSpan)
        var unplaced = diagnostic
        unplaced.range = nil

        #expect(unplaced != diagnostic)
    }

    @Test
    func hashesEqualRecipesAlike() {
        let recipes: Set<Recipe> = [
            Self.parser.parseRecipe("Fry @garlic@.").value,
            Self.parser.parseRecipe("Fry @garlic@.").value
        ]

        #expect(recipes.count == 1)
    }

    @Test
    func hashesEqualParseResultsAlike() {
        let results: Set<Parsed<Recipe>> = [
            Self.parser.parseRecipe("Fry @garlic until fragrant."),
            Self.parser.parseRecipe("Fry @garlic until fragrant.")
        ]

        #expect(results.count == 1)
    }
}
