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

    // Every problem must carry enough information to find and fix it by hand, so each
    // diagnostic describes itself and points at the construct it came from.

    @Test
    func describesAndLocatesEveryDiagnostic() {
        let sources = [
            "---\nchef: Alice\nchef: Bob\nstray line\ntags: [italian]\ntags: [quick]\n---",
            "---\ntitle: Buttered Toast",
            "Fry @garlic and warm a #pan.",
            "Cook @{200 g pasta",
            "Add @sauce@:homemade now.",
            "Spread the >sauce on top."
        ]

        let diagnostics = sources.flatMap({ SousParser().parseRecipe($0).diagnostics })
        // Every kind the reader can report, each describing itself and pointing at its
        // construct. Naming them rather than counting them says which one a failure is missing.
        // The three kinds validation reports carry no range, so they are stated there instead.
        #expect(Set(diagnostics.map(\.kind)) == [
            .unclosedSpan,
            .unterminatedHeader,
            .unknownHeaderKey,
            .repeatedScalarKey,
            .repeatedListKey,
            .malformedHeaderLine,
            .unknownFlag
        ])
        #expect(diagnostics.allSatisfy({ !$0.message.isEmpty }))
        #expect(diagnostics.allSatisfy({ $0.range != nil }))
    }

    @Test
    func locatesAnUnclosedSpan() throws {
        let parsed = SousParser().parseRecipe("Fry @garlic until fragrant.")

        let diagnostic = try parsed.firstDiagnostic(ofKind: .unclosedSpan)
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
        let diagnostic = try parsed.firstDiagnostic(ofKind: .unclosedSpan)
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
        let diagnostic = try parsed.firstDiagnostic(ofKind: .unknownHeaderKey)
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
        let diagnostic = try parsed.firstDiagnostic(ofKind: .repeatedScalarKey)
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
        let diagnostic = try parsed.firstDiagnostic(ofKind: .malformedHeaderLine)
        let range = try #require(diagnostic.range)
        #expect(range.start.line == 3)
        #expect(range.start.column == 1)
        #expect(diagnostic.severity == .warning)
    }

    @Test
    func locatesAnUnrecognizedFlag() throws {
        let parsed = SousParser().parseRecipe("Add @sauce@:homemade now.")

        let diagnostic = try parsed.firstDiagnostic(ofKind: .unknownFlag)
        let range = try #require(diagnostic.range)
        #expect(range.start.line == 1)
        #expect(range.start.column == 12)
        #expect(range.start.offset == 11)
        #expect(range.end.offset == 20)
        #expect(diagnostic.severity == .warning)
    }

    @Test
    func locatesAnUnclosedReferenceSpan() throws {
        let parsed = SousParser().parseRecipe("Spread the >sauce on top.")

        let diagnostic = try parsed.firstDiagnostic(ofKind: .unclosedSpan)
        let range = try #require(diagnostic.range)
        #expect(range.start.line == 1)
        #expect(range.start.column == 12)
        #expect(range.start.offset == 11)
        #expect(range.end.offset == 12)
        #expect(diagnostic.severity == .warning)
    }

    @Test
    func locatesAnUnterminatedHeaderAtItsOpeningFence() throws {
        let parsed = SousParser().parseRecipe("---\ntitle: Buttered Toast")

        let diagnostic = try parsed.firstDiagnostic(ofKind: .unterminatedHeader)
        let range = try #require(diagnostic.range)
        #expect(range.start.line == 1)
        #expect(range.start.column == 1)
        #expect(range.start.offset == 0)
    }
}
