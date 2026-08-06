import SousCore
import Testing

@Suite("Diagnostics")
struct DiagnosticsTests {
    @Test
    func aWellFormedRecipeHasNoDiagnostics() {
        #expect(SousParser().parseRecipe(Recipe.wellFormedSource).diagnostics.isEmpty)
    }

    @Test
    func aWarningPreservesTheContentSoTheFileRemainsUsable() {
        let source = """
        ---
        title: Toast
        stray line
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.diagnostics.map(\.severity) == [.warning])
        #expect(parsed.value.metadata.title == "Toast")
        #expect(parsed.value.serialized() == source)
    }

    @Test(arguments: [
        (Diagnostic.Kind.unterminatedHeader, Diagnostic.Severity.error),
        (.malformedHeaderLine, .warning),
        (.emptyHeaderKey, .warning),
        (.repeatedScalarKey, .warning),
        (.repeatedListKey, .warning),
        (.repeatedYield, .warning),
        (.zeroYield, .warning),
        (.repeatedGroupName, .warning),
        (.unclosedSpan, .warning),
        (.malformedQuantity, .warning),
        (.unnamedAnnotation, .warning),
        (.unresolvedReference, .warning),
        (.referenceCycle, .warning)
    ])
    func severityFollowsFromTheKind(kind: Diagnostic.Kind, severity: Diagnostic.Severity) {
        #expect(kind.severity == severity)
    }

    @Test
    func describesAndLocatesEveryDiagnostic() {
        let sources = [
            "---\nchef: Alice\nchef: Bob\nstray line\ntags: [italian]\ntags: [quick]\n---",
            "---\ntitle: Buttered Toast",
            "Fry @garlic and warm a #pan.",
            "Cook @{200 g pasta",
            "Spread the >sauce on top.",
            "Add @{3,2 kg} flour@.",
            "Add @{200 g}@ now.",
            "---\nservings: 3,2\n---",
            "---\n: Alice\n---"
        ]

        let diagnostics = sources.flatMap({ SousParser().parseRecipe($0).diagnostics })
        #expect(Set(diagnostics.map(\.kind)) == [
            .unclosedSpan,
            .unterminatedHeader,
            .repeatedScalarKey,
            .repeatedListKey,
            .malformedHeaderLine,
            .malformedQuantity,
            .unnamedAnnotation,
            .emptyHeaderKey
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
