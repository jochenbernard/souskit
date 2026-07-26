/// A parser for Sous source text.
///
/// A parser holds no state, so one instance may be shared across isolation domains and reused
/// for any number of sources.
public struct SousParser: Sendable {
    /// Creates a parser.
    public init() {}

    /// Parses Sous source text into a recipe.
    ///
    /// Parsing always succeeds. Malformed constructs are recovered as literal text and reported
    /// as diagnostics, so a recipe is always returned. A leading byte order mark is dropped, and
    /// every line break is normalized to a line feed.
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
    /// surrounding whitespace is trimmed. A leading `=` is read as the marker fixing the amount.
    /// Text with no usable leading number parses as an imprecise amount rather than failing, so
    /// no diagnostics are returned.
    ///
    /// - Parameter text: The fence content to parse.
    /// - Returns: The parsed amount.
    public func parseAmount(_ text: String) -> Amount {
        AmountParser.parse(text)
    }
}
