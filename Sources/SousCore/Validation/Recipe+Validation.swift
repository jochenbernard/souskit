extension Recipe {
    /// Validates the recipe and returns any problems.
    ///
    /// Five rules apply: the header declares each unit's yield at most once, counting `servings`
    /// and every `yield` item together; it declares no yield of zero; no two group headings share
    /// a name; every reference matches a group; and no group consumes an intermediate that
    /// depends on it.
    ///
    /// A failed scaling request is not reported here; ``scaled(to:)`` throws instead. No
    /// diagnostic carries a range, because validation reads a recipe rather than source text.
    ///
    /// - Returns: The diagnostics describing any problems found.
    public func validate() -> [Diagnostic] {
        metadata.repeatedYields() + metadata.zeroYields()
            + repeatedGroupNames() + unresolvedReferences() + referenceCycles()
    }
}
