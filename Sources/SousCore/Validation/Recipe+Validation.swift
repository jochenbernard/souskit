extension Recipe {
    /// Validates the recipe and returns any problems.
    ///
    /// Validation covers everything decidable from the recipe file alone, without reference data or other files.
    ///
    /// - Returns: The diagnostics describing any problems found.
    public func validate() -> [Diagnostic] {
        metadata.conflictingYields()
    }
}
