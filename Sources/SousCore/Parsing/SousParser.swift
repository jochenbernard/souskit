/// A parser for Sous source text.
///
/// A parser holds nothing of its own, so one may be shared across isolation domains and reused
/// for as many sources as an application reads.
public struct SousParser: Sendable {
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
        let groups = Self.groups(in: split.body, map: map, diagnostics: &diagnostics)

        return Parsed(
            value: Recipe(metadata: metadata, groups: groups),
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

    /// The groups the body's lines form. A heading opens one, and the lines from it up to the
    /// next heading are the steps of that group.
    ///
    /// The lines before the first heading form the unnamed default group, which is left out
    /// when it holds no step, so a body opening with a heading forms no default group and a
    /// body of nothing forms no group at all.
    private static func groups(
        in lines: [Substring],
        map: SourceMap,
        diagnostics: inout [Diagnostic]
    ) -> [StepGroup] {
        var groups: [StepGroup] = []

        for run in Self.runs(in: lines) {
            let steps = Self.steps(in: run.lines, map: map, diagnostics: &diagnostics)
            guard run.name != nil || !steps.isEmpty else { continue }

            groups.append(StepGroup(name: run.name, steps: steps))
        }

        return groups
    }

    /// The runs of body lines the headings divide the body into, each carrying the name of the
    /// group it opens. The first run is the default group's and carries none.
    ///
    /// A heading line belongs to no run, which is what ends the paragraph before it whether or
    /// not a blank line follows.
    private static func runs(in lines: [Substring]) -> [(name: String?, lines: [Substring])] {
        var runs: [(name: String?, lines: [Substring])] = [(name: nil, lines: [])]

        for line in lines {
            if let name = Heading.name(of: line) {
                runs.append((name: name, lines: []))
            } else {
                runs[runs.count - 1].lines.append(line)
            }
        }

        return runs
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
