import SousCore
import Testing

// The annotation lists are views over the segments a step is built from, so editing the
// segments moves them. Nothing is stored twice and nothing can drift.

@Suite("Step projection")
struct StepProjectionTests {
    @Test
    func derivesTheIngredientsFromTheSegments() {
        var step = SousParser().parseRecipe("Fry @garlic@ and add @baby spinach@.").value.steps[0]
        step.segments.removeLast(2)

        #expect(step.ingredients.map(\.name) == ["garlic"])
    }

    @Test
    func derivesTheCookwareFromTheSegments() {
        var step = SousParser().parseRecipe("Warm a #pan# and a #ladle#.").value.steps[0]
        step.segments.removeLast(2)

        #expect(step.cookware.map(\.name) == ["pan"])
    }

    @Test
    func derivesTheTimersFromTheSegments() {
        var step = SousParser().parseRecipe("Simmer ~40 min~ and rest ~10 min~.").value.steps[0]
        step.segments.removeLast(2)

        #expect(step.timers.map(\.text) == ["40 min"])
    }

    @Test
    func derivesARecipeWideListFromTheSegments() {
        var recipe = SousParser().parseRecipe("Fry @garlic@ in a #pan#.\n\nAdd @salt@.").value
        recipe.steps[0].segments = []

        #expect(recipe.ingredients.map(\.name) == ["salt"])
        #expect(recipe.cookware.isEmpty)
    }

    @Test
    func collectsIngredientsAcrossStepsInDocumentOrder() {
        let source = """
        Fry @garlic@ and add @baby spinach@.

        Finish with @{50 g} parmesan@.
        """

        let ingredients = SousParser().parseRecipe(source).value.ingredients
        #expect(ingredients.map(\.name) == ["garlic", "baby spinach", "parmesan"])
    }

    @Test
    func collectsCookwareAcrossStepsInDocumentOrder() {
        let source = """
        Bring a #large pot# of water to a boil.

        Warm a #frying pan# and a #ladle#.
        """

        let cookware = SousParser().parseRecipe(source).value.cookware
        #expect(cookware.map(\.name) == ["large pot", "frying pan", "ladle"])
    }

    @Test
    func collectsTimersAcrossStepsInDocumentOrder() {
        let source = """
        Simmer ~40 min~ gently.

        Rest ~overnight~ before slicing.
        """

        let timers = SousParser().parseRecipe(source).value.timers
        #expect(timers.map(\.text) == ["40 min", "overnight"])
    }

    @Test
    func readsNoAnnotationsFromAProseOnlyStep() {
        let recipe = SousParser().parseRecipe("Toast the bread.").value

        #expect(recipe.ingredients.isEmpty)
        #expect(recipe.cookware.isEmpty)
        #expect(recipe.timers.isEmpty)
        #expect(recipe.steps[0].ingredients.isEmpty)
        #expect(recipe.steps[0].cookware.isEmpty)
        #expect(recipe.steps[0].timers.isEmpty)
    }
}
