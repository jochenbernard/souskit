import SousCore
import Testing

@Suite("Validation")
struct ValidationTests {
    /// The diagnostics validating a recipe with the given header and one flour ingredient
    /// produces.
    private func validate(_ header: String) -> [Diagnostic] {
        Recipe.read(Fixtures.crepeBatter(header)).validate()
    }

    @Test
    func aWellFormedRecipeValidatesWithoutDiagnostics() {
        #expect(Recipe.read(Fixtures.wellFormedSource).validate().isEmpty)
    }

    @Test
    func aProseOnlyRecipeValidatesWithoutDiagnostics() {
        #expect(Recipe.read("Whisk the vinegar.").validate().isEmpty)
    }

    @Test(arguments: ["yield: 0 g", "servings: 0", "yield: [0 g, 6 servings]"])
    func reportsAYieldOfZero(header: String) throws {
        let diagnostics = validate(header)

        let diagnostic = try #require(diagnostics.first)
        #expect(diagnostics.count == 1)
        #expect(diagnostic.kind == .zeroYield)
        #expect(diagnostic.severity == .warning)
    }

    @Test(arguments: ["yield: 0.5 kg", "servings: 4", "yield: a pinch"])
    func reportsNoYieldOfZeroWhereNoneIsStated(header: String) {
        #expect(validate(header).isEmpty)
    }

    @Test
    func reportsAPortionYieldStatedAlongsideServings() throws {
        let diagnostics = validate("servings: 4\nyield: 6 servings")

        #expect(diagnostics.count == 1)
        let diagnostic = try #require(diagnostics.first)
        #expect(diagnostic.kind == .repeatedYield)
        #expect(diagnostic.severity == .warning)
        #expect(diagnostic.range == nil)
    }

    @Test(arguments: [
        "yield: [6 servings, 8 servings]",
        "yield: 6 servings\nyield: 8 servings",
        "yield: [800 g, 900 g]",
        "servings: 4\nyield: 4.5 servings",
        "yield: [12 madeleines, 10-12 madeleines]",
        "servings: 4\nyield: 4 servings",
        "yield: [6 servings, 6 servings]",
        "servings: 4\nyield: 4.0 servings",
        "yield: [800 g, 800  g]",
        "yield: [10-12 madeleines, 10-12 madeleines]"
    ])
    func reportsADimensionStatedMoreThanOnce(header: String) {
        #expect(validate(header).map(\.kind) == [.repeatedYield])
    }

    @Test(arguments: [
        "yield: [6 servings, 3.2 kg]",
        "yield: [800 g, 1 kg]",
        "servings: 4\nyield: 800 g",
        "yield: [12, 12 madeleines]"
    ])
    func acceptsOneStatementPerDimension(header: String) {
        #expect(validate(header).isEmpty)
    }

    @Test(arguments: [
        "yield: [plenty, plenty]",
        "yield: [plenty, lots]",
        "servings: six\nyield: 4 servings",
        "servings: six\nservings: four",
        "servings: =4\nyield: 6 servings"
    ])
    func ignoresAValueThatStatesNoQuantity(header: String) {
        #expect(validate(header).isEmpty)
    }

    @Test
    func ignoresARepeatedServingsKey() {
        #expect(validate("servings: 4\nservings: 6").isEmpty)
    }

    @Test
    func reportsEachDimensionInDocumentOrder() {
        let diagnostics = validate("yield: [5 L, 4 L]\nservings: 4\nyield: [6 servings]")

        #expect(diagnostics.map(\.message) == [
            "Header declares more than one yield in 'L'.",
            "Header declares more than one yield in 'servings'."
        ])
    }

    @Test
    func reportsOneDiagnosticPerRepeatedDimension() {
        #expect(validate("yield: [4 servings, 6 servings, 8 servings]").map(\.kind) == [.repeatedYield])
        #expect(validate("yield: [4 servings, 6 servings, 800 g, 900 g]").map(\.kind) == [
            .repeatedYield, .repeatedYield
        ])
    }

    @Test(arguments: [
        (header: "yield: [800 g, 900 g]", message: "Header declares more than one yield in 'g'."),
        (header: "yield: [12, 18]", message: "Header declares more than one yield with no unit."),
        (
            header: "servings: 4\nyield: 6 servings",
            message: "Header declares more than one yield in 'servings'."
        )
    ])
    func namesTheDimensionItReports(header: String, message: String) {
        #expect(validate(header).map(\.message) == [message])
    }

    @Test
    func scalingDoesNotChangeWhatValidationReports() throws {
        let clean = Recipe.read("---\nservings: 4\n---")
        let repeated = Recipe.read("---\nservings: 4\nyield: 6 servings\n---")

        #expect(try clean.scaled(by: 2.0).validate().isEmpty)
        #expect(try repeated.scaled(by: 2.0).validate().map(\.kind) == [.repeatedYield])
    }
}
