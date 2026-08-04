extension Recipe {
    /// Finds the first group whose heading matches the given name.
    ///
    /// Names are matched normalized: case, accents, surrounding whitespace, and leading
    /// connectives (`a`, `an`, `of`, `the`) do not affect the result.
    ///
    /// - Parameter name: The group name to match.
    /// - Returns: The matching group, or `nil` when no heading matches.
    public func group(named name: String) -> StepGroup? {
        index(ofGroupNamed: name).map({ groups[$0] })
    }

    /// The groups a group consumes through its references.
    ///
    /// Each group appears once, in the order its first reference occurs. A reference matching no
    /// heading contributes nothing.
    ///
    /// - Parameter group: The group whose references to resolve.
    /// - Returns: The groups it depends on.
    public func dependencies(of group: StepGroup) -> [StepGroup] {
        dependencyIndices(of: group).map({ groups[$0] })
    }

    /// The index in ``groups`` of the first group whose heading matches, normalized.
    func index(ofGroupNamed name: String) -> Int? {
        let normalized = Normalization.normalized(name)

        return groups.firstIndex(where: { $0.name.map(Normalization.normalized) == normalized })
    }

    /// The indices in ``groups`` of the groups this group consumes, deduplicated.
    func dependencyIndices(of group: StepGroup) -> [Int] {
        var seen: Set<Int> = []

        return group.references.compactMap { reference in
            guard let index = index(ofGroupNamed: reference.target), seen.insert(index).inserted
            else { return nil }

            return index
        }
    }
}
