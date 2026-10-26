/// A recipe loader reading from source texts held in memory.
public struct InMemoryRecipeLoader: RecipeLoader {
    /// The source texts, keyed by path.
    private let texts: [RecipePath: String]

    /// Creates a loader over the given source texts.
    ///
    /// - Parameter texts: The source texts, keyed by the path of each recipe.
    public init(_ texts: [RecipePath: String]) {
        self.texts = texts
    }

    /// Returns the source text held at a path, matched exactly.
    ///
    /// - Parameter path: The path of the recipe.
    /// - Returns: The source text, or `nil` when none is held at the path.
    public func text(at path: RecipePath) -> String? {
        texts[path]
    }
}
