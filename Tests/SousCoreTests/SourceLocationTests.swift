import SousCore
import Testing

// Where diagnostics point, and in what order they arrive. Lines and columns are one-based
// and counted in characters; the offset is a zero-based character offset.

@Suite("Source locations")
struct SourceLocationTests {
    @Test
    func locatesADiagnosticOnALaterLineOfTheSameStep() throws {
        let parsed = SousParser().parseRecipe("First line here.\nFry @garlic now.")

        let range = try #require(parsed.diagnostics.first?.range)
        #expect(range.start.line == 2)
        #expect(range.start.column == 5)
        #expect(range.start.offset == 21)
    }

    @Test
    func countsAWindowsLineEndingAsOneCharacter() throws {
        let parsed = SousParser().parseRecipe("First line.\r\nFry @garlic now.")

        let range = try #require(parsed.diagnostics.first?.range)
        #expect(range.start.line == 2)
        #expect(range.start.column == 5)
        #expect(range.start.offset == 16)
    }

    @Test
    func countsOffsetsFromAfterAByteOrderMark() throws {
        // The mark is not part of the text, so it does not shift what follows it.
        let parsed = SousParser().parseRecipe("\u{FEFF}Fry @garlic now.")

        let range = try #require(parsed.diagnostics.first?.range)
        #expect(range.start.line == 1)
        #expect(range.start.column == 5)
        #expect(range.start.offset == 4)
    }

    @Test
    func countsColumnsInCharactersRatherThanUnicodeScalars() throws {
        // A letter with a combining accent is one character, as is the emoji.
        let parsed = SousParser().parseRecipe("Cafe\u{301} \u{1F642} @garlic now.")

        let range = try #require(parsed.diagnostics.first?.range)
        #expect(range.start.column == 8)
        #expect(range.start.offset == 7)
    }

    @Test
    func coversTheWholeSpanWhenAnAmountFenceIsUnclosed() throws {
        let parsed = SousParser().parseRecipe("Cook @{200 g pasta@ now.")

        let range = try #require(parsed.diagnostics.first?.range)
        #expect(range.start.offset == 5)
        #expect(range.end.offset == 19)
    }

    @Test
    func reportsHeaderDiagnosticsBeforeBodyDiagnostics() {
        let source = "---\nchef: Alice\n---\n\nFry @garlic now."

        let kinds = SousParser().parseRecipe(source).diagnostics.map(\.kind)
        #expect(kinds == [.unknownHeaderKey, .unclosedSpan])
    }

    @Test
    func reportsOneWarningForEveryRepeatedOccurrence() {
        let source = "---\ntitle: First\ntitle: Second\ntitle: Third\n---"

        let diagnostics = SousParser().parseRecipe(source).diagnostics
        #expect(diagnostics.count == 2)
        #expect(diagnostics.allSatisfy({ $0.kind == .repeatedScalarKey }))
    }

    @Test
    func reportsBothAnUnknownAndARepeatedWarningForARepeatedUnknownKey() {
        let source = "---\nchef: Alice\nchef: Bob\n---"

        let kinds = SousParser().parseRecipe(source).diagnostics.map(\.kind)
        #expect(kinds == [.unknownHeaderKey, .unknownHeaderKey, .repeatedScalarKey])
    }

    @Test
    func reportsEveryProblemAsAWarning() {
        // Version 0.2 recovers from everything it can flag, so nothing is an error.
        let source = """
        ---
        chef: Alice
        chef: Bob
        stray line
        ---

        Fry @garlic and warm a #pan.
        """

        let parsed = SousParser().parseRecipe(source)
        #expect(parsed.diagnostics.count == 6)
        #expect(parsed.diagnostics.allSatisfy({ $0.severity == .warning }))
    }
}
