extension Recipe {
    /// Returns the group a name refers to.
    ///
    /// Names are matched normalized, so `bechamel` refers to a group named `Bechamel`. The
    /// default group has no name and is referred to by nothing.
    ///
    /// A file naming two groups the same is not valid, and ``validate()`` reports it. The first
    /// of them is returned, so a reference to that name still resolves to one group.
    ///
    /// - Parameter name: The name to match, such as a reference's target.
    /// - Returns: The group the name refers to, or `nil` when no group carries it.
    public func group(named name: String) -> StepGroup? {
        index(ofGroupNamed: name).map({ groups[$0] })
    }

    /// Returns the groups a group depends on.
    ///
    /// A group depends on every group its steps consume an intermediate of. The dependency
    /// follows from that consumption rather than from position, so a group may be written
    /// before or after the groups it depends on.
    ///
    /// Each group is listed once, in the order its first reference appears, and a target
    /// naming no group is left out, because a group the file does not hold cannot be depended
    /// on. ``validate()`` reports such a target.
    ///
    /// - Parameter group: The group whose dependencies are wanted.
    /// - Returns: The groups it depends on.
    public func dependencies(of group: StepGroup) -> [StepGroup] {
        dependencyIndices(of: group).map({ groups[$0] })
    }

    /// The position of the group a name refers to. Resolving a name and reaching the group it
    /// names are the same lookup, so the two can never disagree on which group that is.
    func index(ofGroupNamed name: String) -> Int? {
        let normalized = Normalization.normalized(name)

        return groups.firstIndex(where: { $0.name.map(Normalization.normalized) == normalized })
    }

    /// The positions of the groups a group depends on, each listed once and in the order its
    /// first reference appears.
    func dependencyIndices(of group: StepGroup) -> [Int] {
        var seen: Set<Int> = []

        return group.references.compactMap({ reference in
            guard let index = index(ofGroupNamed: reference.target), seen.insert(index).inserted
            else { return nil }

            return index
        })
    }
}
