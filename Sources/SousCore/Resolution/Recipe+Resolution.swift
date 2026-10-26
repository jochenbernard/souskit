extension Recipe {
    /// What a reference consumes once resolved.
    public enum Resolution: Equatable, Hashable, Sendable {
        /// A group of the recipe holding the reference.
        case group(StepGroup)

        /// A recipe read from another file, with the path it was read from.
        case recipe(Parsed<Recipe>, path: RecipePath)
    }

    /// Where a reference leads, decided without reading any file.
    ///
    /// A target holding a slash leads to a file, even when a group carries the same name. Any other target leads
    /// to the first group it matches, normalized, and otherwise to the file of that name in the same folder.
    ///
    /// - Parameter reference: The reference to classify.
    /// - Returns: The group, or the relative path of the file.
    public func destination(of reference: Reference) -> Reference.Destination {
        if let index = groupIndex(of: reference) {
            return .group(groups[index])
        }

        var path = reference.target
        while path.hasPrefix("./") {
            path.removeFirst(2)
        }

        return .file(path)
    }

    /// Resolves a reference to the group or the recipe it consumes.
    ///
    /// File names are matched as written, with no normalization. A path climbing above the root, or ending in no
    /// name, resolves to `nil` without reading.
    ///
    /// - Parameters:
    ///   - reference: The reference to resolve.
    ///   - path: The path of this recipe, which a relative path in the reference starts from.
    ///   - loader: The loader reading the referenced recipe.
    /// - Returns: The group or the parsed recipe, or `nil` when the reference leads to no recipe.
    /// - Throws: The error the loader throws when the referenced recipe cannot be read.
    public func resolve(
        _ reference: Reference,
        from path: RecipePath,
        using loader: some RecipeLoader
    ) throws -> Resolution? {
        switch destination(of: reference) {
        case let .group(group):
            return .group(group)

        case let .file(relativePath):
            guard
                let target = path.resolving(relativePath),
                let parsed = try loader.recipe(at: target)
            else {
                return nil
            }

            return .recipe(parsed, path: target)
        }
    }
}
