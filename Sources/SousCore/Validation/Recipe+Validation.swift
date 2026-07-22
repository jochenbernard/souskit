extension Recipe {
    /// Validates the recipe and returns any problems.
    ///
    /// Validation covers everything this version can decide from the recipe file alone, without
    /// reference data or other files. One rule applies: the header states a yield of each
    /// dimension at most once, counting `servings` and every `yield` entry together.
    ///
    /// A failed scaling request is not reported here. It is a property of the request rather
    /// than of the file, so ``scaled(to:)`` throws instead.
    ///
    /// - Returns: The diagnostics describing any problems found.
    public func validate() -> [Diagnostic] {
        metadata.repeatedYields()
    }
}
