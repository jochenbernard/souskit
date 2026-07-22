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
        let source = SourceText.withoutByteOrderMark(text)
        let lines = SourceText.lines(of: source)
        let map = SourceMap(source, lines: lines)
        let split = HeaderParser.split(lines, map: map, diagnostics: &diagnostics)
        let metadata = HeaderParser.parse(split.header, map: map, diagnostics: &diagnostics)
        let steps = Self.steps(in: split.body, map: map, diagnostics: &diagnostics)

        return Parsed(
            value: Recipe(metadata: metadata, groups: Self.groups(of: steps)),
            diagnostics: diagnostics
        )
    }

    /// Parses the content of an amount fence into an amount.
    ///
    /// The text is what a fence holds without its braces, such as `200 g` or `18 pancakes`, and
    /// it is read exactly as one, with nothing trimmed. So a target opening with whitespace is
    /// imprecise, where the same header value would not be.
    ///
    /// Reading an amount reports nothing, because text with no leading number is an imprecise
    /// amount rather than a defect, so the amount is returned on its own.
    ///
    /// - Parameter text: The fence content to parse.
    /// - Returns: The parsed amount.
    public func parseAmount(_ text: String) -> Amount {
        AmountParser.parse(text)
    }

    /// The groups the body's steps belong to. Reading a heading is this version's own work, so
    /// until it lands every step belongs to the one unnamed group.
    private static func groups(of steps: [Step]) -> [StepGroup] {
        steps.isEmpty ? [] : [StepGroup(name: nil, steps: steps)]
    }

    /// A step is one paragraph: a maximal run of consecutive non-blank lines.
    private static func steps(
        in lines: [Substring],
        map: SourceMap,
        diagnostics: inout [Diagnostic]
    ) -> [Step] {
        var steps: [Step] = []

        for paragraph in lines.split(whereSeparator: SourceText.isBlank) {
            guard let first = paragraph.first else { continue }

            steps.append(StepParser.parse(
                paragraph.joined(separator: "\n"),
                origin: StepParser.Origin(start: map.offset(of: first.startIndex), map: map),
                diagnostics: &diagnostics
            ))
        }

        return steps
    }
}
