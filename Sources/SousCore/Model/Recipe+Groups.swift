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
        nil
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
        []
    }
}
