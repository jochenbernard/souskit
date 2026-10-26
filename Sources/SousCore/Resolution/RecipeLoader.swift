/// A source of recipe text, read by path.
public protocol RecipeLoader: Sendable {
    /// Reads the source text of the recipe at a path.
    ///
    /// - Parameter path: The path of the recipe.
    /// - Returns: The source text, or `nil` when no recipe exists at the path.
    /// - Throws: An error when a recipe exists at the path but cannot be read.
    func text(at path: RecipePath) throws -> String?
}

extension RecipeLoader {
    /// Reads and parses the recipe at a path.
    ///
    /// - Parameter path: The path of the recipe.
    /// - Returns: The parsed recipe with its diagnostics, or `nil` when no recipe exists at the path.
    /// - Throws: The error ``text(at:)`` throws.
    public func recipe(at path: RecipePath) throws -> Parsed<Recipe>? {
        try text(at: path).map(SousParser().parseRecipe)
    }
}
