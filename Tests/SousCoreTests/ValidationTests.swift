import SousCore
import Testing

// Version 0.2 defines no intra-file validation rules (the first arrives in v0.3), so a
// well-formed recipe validates without any diagnostics. These tests hold against the
// current no-op and guard that contract against regressions.

@Suite("Validation")
struct ValidationTests {
    @Test
    func aWellFormedRecipeValidatesWithoutDiagnostics() {
        let source = """
        ---
        title: Garlic Pasta
        servings: 2
        ---

        Cook @{200 g} spaghetti@ in a #large pot#.
        """

        #expect(SousParser().parseRecipe(source).value.validate().isEmpty)
    }

    @Test
    func aProseOnlyRecipeValidatesWithoutDiagnostics() {
        #expect(SousParser().parseRecipe("Toast the bread.").value.validate().isEmpty)
    }
}
