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
        let recipe = Recipe(
            metadata: Metadata(
                title: nil,
                language: nil,
                version: nil,
                servings: nil,
                tags: [],
                source: nil,
                entries: []
            ),
            steps: []
        )

        return Parsed(
            value: recipe,
            diagnostics: []
        )
    }
}
