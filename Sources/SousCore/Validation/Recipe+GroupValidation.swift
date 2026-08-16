extension Recipe {
    /// One warning per name carried by more than one heading, reported at the first occurrence.
    ///
    /// Names are compared normalized, so two headings differing only in case collide.
    func repeatedGroupNames() -> [Diagnostic] {
        Repetition.firstOfEachRepeated(in: groups.compactMap(\.name), by: Normalization.normalized)
            .map({ Diagnostic(.repeatedGroupName, "Recipe has more than one group named '\($0)'.") })
    }

    /// One warning per reference target matching no group, reported at its first occurrence.
    func unresolvedReferences() -> [Diagnostic] {
        var reported: Set<String> = []

        return references.compactMap { reference in
            let normalized = Normalization.normalized(reference.target)
            guard
                index(ofGroupNamed: reference.target) == nil,
                reported.insert(normalized).inserted
            else {
                return nil
            }

            return Diagnostic(.unresolvedReference, "Reference to '\(reference.target)' matches no group.")
        }
    }

    /// One warning per cycle of groups consuming each other, reported at the first group in it.
    ///
    /// Every group in a cycle reaches itself, so reporting each would repeat one problem. The
    /// whole cycle is marked when its first member is reported.
    func referenceCycles() -> [Diagnostic] {
        let reaches = consumptionReach
        var reported: Set<Int> = []

        return groups.indices.compactMap { index in
            guard
                let name = groups[index].name,
                reaches[index][index],
                !reported.contains(index)
            else {
                return nil
            }

            for other in groups.indices where reaches[index][other] && reaches[other][index] {
                reported.insert(other)
            }

            return Diagnostic(.referenceCycle, "Group '\(name)' consumes an intermediate that depends on it.")
        }
    }

    /// Which groups each group reaches through its references, directly or through others.
    ///
    /// Transitive closure, so a group in a cycle reaches itself and the diagonal marks it.
    private var consumptionReach: [[Bool]] {
        var reaches = groups.map { group in
            let dependencies = Set(dependencyIndices(of: group))

            return groups.indices.map(dependencies.contains)
        }

        for through in groups.indices {
            for consumer in groups.indices where reaches[consumer][through] {
                for consumed in groups.indices where reaches[through][consumed] {
                    reaches[consumer][consumed] = true
                }
            }
        }

        return reaches
    }
}
