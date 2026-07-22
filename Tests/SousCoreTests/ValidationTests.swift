import SousCore
import Testing

// Version 0.3 brings the first intra-file validation rule: the header declares at most one
// value per dimension, counting `servings` and every `yield` entry together.
//
// A dimension is what a unit measures, and recognizing two spellings of one needs reference
// data. So the rule reaches exactly as far as the unit written, with the whitespace around it
// ignored, and `servings` counts as the unit `servings`.

@Suite("Validation")
struct ValidationTests {
    private func validate(_ header: String) -> [Diagnostic] {
        SousParser().parseRecipe("---\n\(header)\n---\n\nMix @{200 g} flour@.").value.validate()
    }

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

    @Test
    func reportsAPortionYieldThatDisagreesWithServings() throws {
        let diagnostics = validate("servings: 4\nyield: 6 servings")

        #expect(diagnostics.count == 1)
        let diagnostic = try #require(diagnostics.first)
        #expect(diagnostic.kind == .conflictingYields)
        // The file is well-formed but not valid, which is an error rather than a warning.
        #expect(diagnostic.severity == .error)
        // Validation reads a recipe, not the text it came from, so it can point at no range.
        #expect(diagnostic.range == nil)
    }

    @Test(arguments: [
        "yield: [6 servings, 8 servings]",
        "yield: 6 servings\nyield: 8 servings",
        "yield: [800 g, 900 g]",
        "servings: 4\nyield: 4.5 servings",
        // A range and a single quantity are two different statements of the dimension.
        "yield: [12 muffins, 10-12 muffins]"
    ])
    func reportsTwoValuesOfOneDimension(header: String) {
        #expect(validate(header).map(\.kind) == [.conflictingYields])
    }

    // Declaring the same amount twice is allowed, because the dimension still holds one value.

    @Test(arguments: [
        "servings: 4\nyield: 4 servings",
        "yield: [6 servings, 6 servings]",
        "servings: 4\nyield: 4.0 servings",
        "yield: [800 g, 800  g]",
        "yield: [10-12 muffins, 10-12 muffins]"
    ])
    func acceptsOneDimensionStatedTwiceWithTheSameValue(header: String) {
        #expect(validate(header).isEmpty)
    }

    // Different units are different dimensions as far as this version can tell, and telling
    // that grams and kilograms measure the same thing is what reference data is for.

    @Test(arguments: [
        "yield: [6 servings, 3.2 kg]",
        "yield: [800 g, 1 kg]",
        "servings: 4\nyield: 800 g",
        "yield: [12, 12 muffins]"
    ])
    func acceptsOneValuePerDimension(header: String) {
        #expect(validate(header).isEmpty)
    }

    // A value with no quantity states no dimension, so it never conflicts with anything.

    @Test(arguments: [
        "yield: [plenty, plenty]",
        "yield: [plenty, lots]",
        "servings: six\nyield: 4 servings",
        "servings: six\nservings: four"
    ])
    func ignoresAValueThatStatesNoQuantity(header: String) {
        #expect(validate(header).isEmpty)
    }

    @Test
    func reportsOneDiagnosticPerConflictingDimension() {
        #expect(validate("yield: [4 servings, 6 servings, 8 servings]").map(\.kind) == [.conflictingYields])
        #expect(validate("yield: [4 servings, 6 servings, 800 g, 900 g]").map(\.kind) == [
            .conflictingYields, .conflictingYields
        ])
    }

    // Validation is computed on demand and never stored, so a recipe scaled out of a valid one
    // stays valid and one scaled out of an invalid one keeps its problem.

    @Test
    func scalingDoesNotChangeWhetherARecipeIsValid() throws {
        let valid = SousParser().parseRecipe("---\nservings: 4\nyield: 4 servings\n---").value
        let invalid = SousParser().parseRecipe("---\nservings: 4\nyield: 6 servings\n---").value

        #expect(try valid.scaled(by: 2.0).validate().isEmpty)
        #expect(try invalid.scaled(by: 2.0).validate().map(\.kind) == [.conflictingYields])
    }
}
