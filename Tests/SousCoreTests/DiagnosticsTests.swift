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

    @Test
    func locatesAnUnclosedSpan() throws {
        let parsed = SousParser().parseRecipe("Fry @garlic until fragrant.")

        let diagnostic = try #require(parsed.diagnostics.first(where: { $0.kind == .unclosedSpan }))
        let range = try #require(diagnostic.range)
        #expect(range.start.line == 1)
        #expect(range.start.column == 5)
        #expect(range.start.offset == 4)
        #expect(range.end.offset == 5)
    }

    @Test
    func locatesADiagnosticInALaterStep() throws {
        let source = """
        First step.

        Fry @garlic until fragrant.
        """

        let parsed = SousParser().parseRecipe(source)
        let diagnostic = try #require(parsed.diagnostics.first(where: { $0.kind == .unclosedSpan }))
        let range = try #require(diagnostic.range)
        #expect(range.start.line == 3)
        #expect(range.start.column == 5)
        #expect(range.start.offset == 17)
    }

    @Test
    func locatesAnUnrecognizedHeaderKey() throws {
        let source = """
        ---
        title: Toast
        chef: Alice
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        let diagnostic = try #require(parsed.diagnostics.first(where: { $0.kind == .unknownHeaderKey }))
        let range = try #require(diagnostic.range)
        #expect(range.start.line == 3)
        #expect(range.start.column == 1)
        #expect(range.start.offset == 17)
        #expect(range.end.column == 5)
    }

    @Test
    func locatesTheRepeatedOccurrenceOfAScalarKey() throws {
        let source = """
        ---
        title: First
        title: Second
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        let diagnostic = try #require(parsed.diagnostics.first(where: { $0.kind == .repeatedScalarKey }))
        let range = try #require(diagnostic.range)
        #expect(range.start.line == 3)
        #expect(range.start.column == 1)
    }

    @Test
    func locatesAMalformedHeaderLine() throws {
        let source = """
        ---
        title: Toast
        stray line
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        let diagnostic = try #require(parsed.diagnostics.first(where: { $0.kind == .malformedHeaderLine }))
        let range = try #require(diagnostic.range)
        #expect(range.start.line == 3)
        #expect(range.start.column == 1)
        #expect(diagnostic.severity == .warning)
    }

    @Test
    func locatesAnUnterminatedHeaderAtItsOpeningFence() throws {
        let parsed = SousParser().parseRecipe("---\ntitle: Buttered Toast")

        let diagnostic = try #require(parsed.diagnostics.first(where: { $0.kind == .unterminatedHeader }))
        let range = try #require(diagnostic.range)
        #expect(range.start.line == 1)
        #expect(range.start.column == 1)
        #expect(range.start.offset == 0)
    }
}
