// swiftlint:disable:next unused_import
import SousKit
import Testing

@Suite("SousKit re-export")
struct ReExportTests {
    @Test
    func exposesTheParserAndParsedResult() {
        let parsed: Parsed<Recipe> = SousParser().parseRecipe("Toast the bread.")

        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func exposesTheModelAndDiagnosticTypes() {
        let parsed = SousParser().parseRecipe("Toast the bread.")
        let recipe: Recipe = parsed.value
        let metadata: Metadata = recipe.metadata
        let diagnostics: [Diagnostic] = parsed.diagnostics

        #expect(metadata.title == nil)
        #expect(diagnostics.isEmpty)
        #expect(recipe.validate().isEmpty)
    }
}
