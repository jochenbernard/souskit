import SousCore
import Testing

@Suite("Diagnostics")
struct DiagnosticsTests {
    @Test
    func aWellFormedRecipeHasNoDiagnostics() {
        #expect(SousParser().parseRecipe(Fixtures.wellFormedSource).diagnostics.isEmpty)
    }

    @Test
    func aWarningPreservesTheContentSoTheFileRemainsUsable() {
        let source = """
        ---
        title: Vinaigrette
        stray line
        ---
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.diagnostics.map(\.severity) == [.warning])
        #expect(parsed.value.metadata.title == "Vinaigrette")
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
            "---\nchef: Camille\nchef: Bruno\nstray line\ntags: [french]\ntags: [quick]\n---",
            "---\ntitle: Vinaigrette",
            "Fry @garlic and warm a #casserole.",
            "Sift @{200 g flour",
            "Spread the >bechamel on top.",
            "Add @{3,2 kg} flour@.",
            "Add @{200 g}@ now.",
            "---\nservings: 3,2\n---",
            "---\n: Camille\n---"
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
    func locatesAnUnclosedAmountFenceAtItsOpeningSigilAlone() throws {
        let parsed = SousParser().parseRecipe("Sift @{200 g flour")

        let range = try #require(parsed.firstDiagnostic(ofKind: .unclosedSpan).range)
        #expect(range.start.offset == 5)
        #expect(range.end.offset == 6)
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
    func locatesARepeatedHeaderKeyAtTheKeyItRepeats() throws {
        let parsed = SousParser().parseRecipe("---\ntitle: First\ntitle: Second\n---")

        let range = try #require(parsed.firstDiagnostic(ofKind: .repeatedScalarKey).range)
        #expect(range.start.offset == 17)
        #expect(range.end.offset == 22)
    }

    @Test
    func locatesAMalformedHeaderLine() throws {
        let source = """
        ---
        title: Vinaigrette
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
    func locatesAMalformedHeaderLineAcrossTheWholeLine() throws {
        let parsed = SousParser().parseRecipe("---\nstray line\n---")

        let range = try #require(parsed.firstDiagnostic(ofKind: .malformedHeaderLine).range)
        #expect(range.start.offset == 4)
        #expect(range.end.offset == 14)
    }

    @Test
    func locatesAnUnclosedReferenceSpan() throws {
        let parsed = SousParser().parseRecipe("Spread the >bechamel on top.")

        let diagnostic = try parsed.firstDiagnostic(ofKind: .unclosedSpan)
        let range = try #require(diagnostic.range)
        #expect(range.start.line == 1)
        #expect(range.start.column == 12)
        #expect(range.start.offset == 11)
        #expect(range.end.offset == 12)
        #expect(diagnostic.severity == .warning)
    }

    @Test(arguments: [
        "---\nservings: 3,2\n---",
        "---\nservings: 3,2  \n---",
        "---\nservings: 3,2\n---\n\nWhisk the vinegar."
    ])
    func locatesAMalformedQuantityAtTheHeaderValueItWasReadFrom(source: String) throws {
        let parsed = SousParser().parseRecipe(source)

        let diagnostic = try parsed.firstDiagnostic(ofKind: .malformedQuantity)
        let range = try #require(diagnostic.range)
        #expect(range.start.line == 2)
        #expect(range.start.column == 11)
        #expect(range.start.offset == 14)
        #expect(range.end.offset == 17)
    }

    @Test
    func locatesAMalformedQuantityAtTheAmountFenceItWasReadFrom() throws {
        let parsed = SousParser().parseRecipe("Add @{3,2 kg} flour@.")

        let range = try #require(parsed.firstDiagnostic(ofKind: .malformedQuantity).range)
        #expect(range.start.offset == 5)
        #expect(range.end.offset == 13)
    }

    @Test
    func locatesAnUnnamedAnnotationAcrossTheWholeSpan() throws {
        let parsed = SousParser().parseRecipe("Add @{200 g}@ now.")

        let range = try #require(parsed.firstDiagnostic(ofKind: .unnamedAnnotation).range)
        #expect(range.start.offset == 4)
        #expect(range.end.offset == 13)
    }

    @Test(arguments: ["---\ntitle: Vinaigrette", "---"])
    func locatesAnUnterminatedHeaderAtItsOpeningFence(source: String) throws {
        let parsed = SousParser().parseRecipe(source)

        let diagnostic = try parsed.firstDiagnostic(ofKind: .unterminatedHeader)
        let range = try #require(diagnostic.range)
        #expect(range.start.line == 1)
        #expect(range.start.column == 1)
        #expect(range.start.offset == 0)
        #expect(range.end.offset == 3)
    }

    @Test(arguments: [
        (source: "Fry @garlic until fragrant.", message: "Ingredient span is missing a closing sigil."),
        (source: "Warm a #casserole now.", message: "Cookware span is missing a closing sigil."),
        (source: "Simmer ~40 min now.", message: "Timer span is missing a closing sigil."),
        (source: "Spread the >bechamel on top.", message: "Reference span is missing a closing sigil.")
    ])
    func namesTheAnnotationItReports(source: String, message: String) throws {
        let parsed = SousParser().parseRecipe(source)

        #expect(try parsed.firstDiagnostic(ofKind: .unclosedSpan).message == message)
    }

    @Test
    func readsAFenceThatClosesOnTheLastCharacterAsAClosedFence() throws {
        let parsed = SousParser().parseRecipe("Add @{200 g}")

        #expect(try parsed.firstDiagnostic(ofKind: .unclosedSpan).message
            == "Ingredient span is missing a closing sigil.")
    }

    @Test(arguments: [
        (
            source: "Add @{200 g}@ now.",
            kind: Diagnostic.Kind.unnamedAnnotation,
            message: "Ingredient span has an amount but no name."
        ),
        (
            source: "Sift @{200 g flour",
            kind: .unclosedSpan,
            message: "Amount fence is missing a closing brace."
        ),
        (
            source: "---\ntitle: Vinaigrette",
            kind: .unterminatedHeader,
            message: "Header is missing a closing fence."
        ),
        (
            source: "---\nstray line\n---",
            kind: .malformedHeaderLine,
            message: "Header line is not a top-level 'key: value' entry."
        ),
        (
            source: "---\ntitle: First\ntitle: Second\n---",
            kind: .repeatedScalarKey,
            message: "Repeated header key 'title'."
        ),
        (
            source: "---\n: Camille\n---",
            kind: .emptyHeaderKey,
            message: "Header line has a value but no key."
        )
    ])
    func describesTheProblemItReports(
        source: String,
        kind: Diagnostic.Kind,
        message: String
    ) throws {
        let parsed = SousParser().parseRecipe(source)

        #expect(try parsed.firstDiagnostic(ofKind: kind).message == message)
    }
}
