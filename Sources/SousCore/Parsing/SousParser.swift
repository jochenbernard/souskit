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
        let groups = GroupParser.parse(split.body, map: map, diagnostics: &diagnostics)

        return Parsed(
            value: Recipe(metadata: metadata, groups: groups),
            diagnostics: diagnostics
        )
    }

    /// Parses the content of an amount fence into an amount.
    ///
    /// The text is what a fence holds without its braces, such as `200 g` or `18 pancakes`, and
    /// it is read exactly as one. The whitespace around it is layout rather than part of what
    /// it states, so it is trimmed away and a target states what the header value of the same
    /// text states.
    ///
    /// Reading an amount reports nothing, because text with no leading number is an imprecise
    /// amount rather than a defect, so the amount is returned on its own.
    ///
    /// - Parameter text: The fence content to parse.
    /// - Returns: The parsed amount.
    public func parseAmount(_ text: String) -> Amount {
        AmountParser.parse(text)
    }
}
