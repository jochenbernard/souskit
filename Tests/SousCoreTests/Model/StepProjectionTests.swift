import SousCore
import Testing

@Suite("Step projection")
struct StepProjectionTests {
    @Test
    func derivesTheIngredientsFromTheSegments() {
        var step = Recipe.read("Fry @garlic@ and add @baby spinach@.").steps[0]
        step.segments.removeLast(2)

        #expect(step.ingredients.map(\.name) == ["garlic"])
    }

    @Test
    func derivesTheCookwareFromTheSegments() {
        var step = Recipe.read("Warm a #pan# and a #ladle#.").steps[0]
        step.segments.removeLast(2)

        #expect(step.cookware.map(\.name) == ["pan"])
    }

    @Test
    func derivesTheTimersFromTheSegments() {
        var step = Recipe.read("Simmer ~40 min~ and rest ~10 min~.").steps[0]
        step.segments.removeLast(2)

        #expect(step.timers.map(\.text) == ["40 min"])
    }

    @Test
    func derivesTheReferencesFromTheSegments() {
        var step = Recipe.read("Layer the >sauce> and the >topping>.").steps[0]
        step.segments.removeLast(2)

        #expect(step.references.map(\.target) == ["sauce"])
    }

    @Test
    func derivesARecipeWideListFromTheSegments() {
        var recipe = Recipe.read("Fry @garlic@ in a #pan#.\n\nAdd @salt@.")
        recipe.groups[0].steps[0].segments = []

        #expect(recipe.ingredients.map(\.name) == ["salt"])
        #expect(recipe.cookware.isEmpty)
    }

    @Test
    func writesTwoAdjacentProseSegmentsAsOneRun() {
        var recipe = Recipe.read("Add @salt@.")
        recipe.groups[0].steps[0].segments = [.text("Season it"), .text("? Yes.")]

        #expect(recipe.serialized() == "Season it? Yes.")
        #expect(Recipe.read(recipe.serialized()).steps.map(\.text) == ["Season it? Yes."])
    }

    @Test
    func derivesTheStepsAndTheGroupListsFromTheGroups() {
        var recipe = Recipe.read("## Sauce\nFry @garlic@.\n\n## Top\nAdd @salt@.")
        recipe.groups[0].steps = []

        #expect(recipe.steps.map(\.text) == ["Add @salt@."])
        #expect(recipe.groups[0].ingredients.isEmpty)
        #expect(recipe.ingredients.map(\.name) == ["salt"])
    }

    @Test
    func collectsIngredientsAcrossStepsInDocumentOrder() {
        let source = """
        Fry @garlic@ and add @baby spinach@.

        Finish with @{50 g} parmesan@.
        """

        let ingredients = Recipe.read(source).ingredients
        #expect(ingredients.map(\.name) == ["garlic", "baby spinach", "parmesan"])
    }

    @Test
    func collectsCookwareAcrossStepsInDocumentOrder() {
        let source = """
        Bring a #large pot# of water to a boil.

        Warm a #frying pan# and a #ladle#.
        """

        let cookware = Recipe.read(source).cookware
        #expect(cookware.map(\.name) == ["large pot", "frying pan", "ladle"])
    }

    @Test
    func collectsTimersAcrossStepsInDocumentOrder() {
        let source = """
        Simmer ~40 min~ gently.

        Rest ~overnight~ before slicing.
        """

        let timers = Recipe.read(source).timers
        #expect(timers.map(\.text) == ["40 min", "overnight"])
    }

    @Test
    func readsNoAnnotationsFromAProseOnlyStep() {
        let recipe = Recipe.read("Toast the bread.")

        #expect(recipe.ingredients.isEmpty)
        #expect(recipe.cookware.isEmpty)
        #expect(recipe.timers.isEmpty)
        #expect(recipe.steps[0].ingredients.isEmpty)
        #expect(recipe.steps[0].cookware.isEmpty)
        #expect(recipe.steps[0].timers.isEmpty)
    }
}
