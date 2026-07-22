import SousCore
import Testing

// Version 0.3 brings the first intra-file validation rule: a dimension states how much the
// recipe makes, so the header states each one at most once, counting `servings` and every
// `yield` entry together.
//
// Stating one twice is reported whether or not the two agree, because saying it twice says it
// twice either way. It leaves the file usable, so it is a warning; only scaling on that
// dimension has to divide by one value and fails while they disagree.
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
    func reportsAPortionYieldStatedAlongsideServings() throws {
        let diagnostics = validate("servings: 4\nyield: 6 servings")

        #expect(diagnostics.count == 1)
        let diagnostic = try #require(diagnostics.first)
        #expect(diagnostic.kind == .repeatedYield)
        // The file stays usable, so it is a warning rather than an error.
        #expect(diagnostic.severity == .warning)
        // Validation reads a recipe, not the text it came from, so it can point at no range.
        #expect(diagnostic.range == nil)
    }

    // Whether the two agree decides nothing here. It decides only whether scaling on that
    // dimension can divide by one of them.

    @Test(arguments: [
        "yield: [6 servings, 8 servings]",
        "yield: 6 servings\nyield: 8 servings",
        "yield: [800 g, 900 g]",
        "servings: 4\nyield: 4.5 servings",
        "yield: [12 muffins, 10-12 muffins]",
        "servings: 4\nyield: 4 servings",
        "yield: [6 servings, 6 servings]",
        "servings: 4\nyield: 4.0 servings",
        "yield: [800 g, 800  g]",
        "yield: [10-12 muffins, 10-12 muffins]"
    ])
    func reportsADimensionStatedMoreThanOnce(header: String) {
        #expect(validate(header).map(\.kind) == [.repeatedYield])
    }

    // Different units are different dimensions as far as this version can tell, and telling
    // that grams and kilograms measure the same thing is what reference data is for.

    @Test(arguments: [
        "yield: [6 servings, 3.2 kg]",
        "yield: [800 g, 1 kg]",
        "servings: 4\nyield: 800 g",
        "yield: [12, 12 muffins]"
    ])
    func acceptsOneStatementPerDimension(header: String) {
        #expect(validate(header).isEmpty)
    }

    // A value with no quantity states no dimension, so it restates nothing.

    @Test(arguments: [
        "yield: [plenty, plenty]",
        "yield: [plenty, lots]",
        "servings: six\nyield: 4 servings",
        "servings: six\nservings: four",
        // The fixed marker belongs to the fence, so a header value opening with one is text.
        "servings: =4\nyield: 6 servings"
    ])
    func ignoresAValueThatStatesNoQuantity(header: String) {
        #expect(validate(header).isEmpty)
    }

    // A repeated scalar key is read from its last occurrence, so it states its dimension once
    // however often it is written. The reader reports the repeat instead.

    @Test
    func ignoresARepeatedServingsKey() {
        #expect(validate("servings: 4\nservings: 6").isEmpty)
    }

    // A dimension is reported where it is first stated, because the diagnostic carries no
    // range and its place in the list is the only position a reader gets.

    @Test
    func reportsEachDimensionInDocumentOrder() {
        let diagnostics = validate("yield: [5 L, 4 L]\nservings: 4\nyield: [6 servings]")

        #expect(diagnostics.map(\.message) == [
            "Header states more than one yield in 'L'.",
            "Header states more than one yield in 'servings'."
        ])
    }

    @Test
    func reportsOneDiagnosticPerRepeatedDimension() {
        #expect(validate("yield: [4 servings, 6 servings, 8 servings]").map(\.kind) == [.repeatedYield])
        #expect(validate("yield: [4 servings, 6 servings, 800 g, 900 g]").map(\.kind) == [
            .repeatedYield, .repeatedYield
        ])
    }

    // The message names the dimension, because the diagnostic carries no range to point with.

    @Test(arguments: [
        (header: "yield: [800 g, 900 g]", message: "Header states more than one yield in 'g'."),
        (header: "yield: [12, 18]", message: "Header states more than one yield with no unit."),
        (
            header: "servings: 4\nyield: 6 servings",
            message: "Header states more than one yield in 'servings'."
        )
    ])
    func namesTheDimensionItReports(header: String, message: String) {
        #expect(validate(header).map(\.message) == [message])
    }

    // Validation is computed on demand and never stored, so a recipe scaled out of a clean one
    // stays clean and one scaled out of a reported one keeps its report.

    @Test
    func scalingDoesNotChangeWhatValidationReports() throws {
        let clean = SousParser().parseRecipe("---\nservings: 4\n---").value
        let repeated = SousParser().parseRecipe("---\nservings: 4\nyield: 6 servings\n---").value

        #expect(try clean.scaled(by: 2.0).validate().isEmpty)
        #expect(try repeated.scaled(by: 2.0).validate().map(\.kind) == [.repeatedYield])
    }
}
