import SousCore
import Testing

@Suite("Diagnostics")
struct DiagnosticsTests {
    @Test
    func aWellFormedRecipeHasNoDiagnostics() {
        let source = """
        ---
        title: Garlic Pasta
        servings: 2
        ---

        Cook @{200 g} spaghetti@ in a #large pot#.
        """

        #expect(SousParser().parseRecipe(source).diagnostics.isEmpty)
    }

    @Test
    func aWarningPreservesTheContentSoTheFileRemainsUsable() {
        let source = """
        ---
        title: Toast
        chef: Alice
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.diagnostics.allSatisfy({ $0.severity == .warning }))
        #expect(parsed.value.metadata.title == "Toast")
        #expect(parsed.value.metadata["chef"] == "Alice")
    }
}
