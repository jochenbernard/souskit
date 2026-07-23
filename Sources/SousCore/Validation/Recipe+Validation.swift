extension Recipe {
    /// Validates the recipe and returns any problems.
    ///
    /// Validation covers everything this version can decide from the recipe file alone, without
    /// reference data or other files. Four rules apply: the header states a yield in each unit
    /// at most once, counting `servings` and every `yield` entry together; no two
    /// group headings state one name; every reference names a group; and no group consumes an
    /// intermediate that depends on it.
    ///
    /// A failed scaling request is not reported here. It is a property of the request rather
    /// than of the file, so ``scaled(to:)`` throws instead.
    ///
    /// - Returns: The diagnostics describing any problems found.
    public func validate() -> [Diagnostic] {
        metadata.repeatedYields() + repeatedGroupNames() + unresolvedReferences() + referenceCycles()
    }
}
