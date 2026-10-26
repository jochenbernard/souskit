extension Recipe {
    /// Finds the first group whose heading matches the given name.
    ///
    /// Names are matched normalized: case, accents, and surrounding whitespace do not affect the
    /// result.
    ///
    /// - Parameter name: The group name to match.
    /// - Returns: The matching group, or `nil` when no heading matches.
    public func group(named name: String) -> StepGroup? {
        index(ofGroupNamed: name).map({ groups[$0] })
    }

    /// The groups a group consumes through its references.
    ///
    /// Each group appears once, in the order its first reference occurs. A reference to a recipe
    /// file contributes nothing.
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

    /// The index in ``groups`` of the group a reference consumes, or `nil` when it leads to a recipe file.
    func groupIndex(of reference: Reference) -> Int? {
        reference.target.contains("/") ? nil : index(ofGroupNamed: reference.target)
    }

    /// The indices in ``groups`` of the groups this group consumes, deduplicated.
    func dependencyIndices(of group: StepGroup) -> [Int] {
        var seen: Set<Int> = []

        return group.references.compactMap { reference in
            guard
                let index = groupIndex(of: reference),
                seen.insert(index).inserted
            else {
                return nil
            }

            return index
        }
    }
}
