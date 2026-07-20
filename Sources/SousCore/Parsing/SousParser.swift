/// A parser for Sous source text.
public struct SousParser {
    /// Creates a parser.
    public init() {}

    /// Parses Sous source text into a recipe.
    ///
    /// Parsing always succeeds; any well-formedness problems are reported as diagnostics on the result.
    ///
    /// - Parameter text: The Sous source text to parse.
    /// - Returns: The parsed recipe together with any diagnostics.
    public func parseRecipe(_ text: String) -> Parsed<Recipe> {
        var diagnostics: [Diagnostic] = []
        let lines = SourceText.lines(of: SourceText.withoutByteOrderMark(text))
        let split = HeaderParser.split(lines, diagnostics: &diagnostics)
        let metadata = HeaderParser.parse(split.header, diagnostics: &diagnostics)
        let steps = Self.steps(in: split.body, diagnostics: &diagnostics)

        return Parsed(
            value: Recipe(metadata: metadata, steps: steps),
            diagnostics: diagnostics
        )
    }

    /// A step is one paragraph: a maximal run of consecutive non-blank lines.
    private static func steps(in lines: [Substring], diagnostics: inout [Diagnostic]) -> [Step] {
        var steps: [Step] = []
        var paragraph: [Substring] = []

        func endParagraph() {
            guard !paragraph.isEmpty else { return }
            steps.append(StepParser.parse(paragraph.joined(separator: "\n"), diagnostics: &diagnostics))
            paragraph = []
        }

        for line in lines {
            if SourceText.isBlank(line) {
                endParagraph()
            } else {
                paragraph.append(line)
            }
        }

        endParagraph()

        return steps
    }
}
