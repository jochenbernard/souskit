// The three conditional requirements groups and references carry. Each leaves the file
// well-formed but not valid, so each is an error, and each is reported once per problem, where
// that problem is first stated.

extension Recipe {
    /// Reports each name more than one heading states.
    ///
    /// Names are matched normalized, so two headings collide while they normalize to one name,
    /// which leaves a reference to that name unable to resolve to one of them. The name is
    /// reported as the first heading writes it, because the diagnostic carries no range.
    func repeatedGroupNames() -> [Diagnostic] {
        let names = groups.compactMap(\.name)
        var stated: [String: Int] = [:]
        var reported: Set<String> = []

        for name in names { stated[Normalization.normalized(name), default: 0] += 1 }

        return names.compactMap({ name in
            let normalized = Normalization.normalized(name)
            guard stated[normalized] ?? 0 > 1, reported.insert(normalized).inserted else { return nil }

            return .error(.repeatedGroupName, "Recipe states more than one group named '\(name)'.")
        })
    }

    /// Reports each target that names no group of this recipe.
    ///
    /// A target is reported once however often it is written, because the diagnostic carries no
    /// range and its place in the list is the only position a reader gets.
    func unresolvedReferences() -> [Diagnostic] {
        var reported: Set<String> = []

        return references.compactMap({ reference in
            let normalized = Normalization.normalized(reference.target)
            guard index(ofGroupNamed: reference.target) == nil,
                  reported.insert(normalized).inserted
            else { return nil }

            return .error(.unresolvedReference, "Reference to '\(reference.target)' matches no group.")
        })
    }

    /// Reports each loop the groups consume each other's intermediates in.
    ///
    /// A loop is one problem however many groups it runs through, so it is reported once, under
    /// the first of them. The default group is consumed by nothing, so it is part of no loop.
    func referenceCycles() -> [Diagnostic] {
        let reaches = consumptionReach
        var reported: Set<Int> = []

        return groups.indices.compactMap({ index in
            guard let name = groups[index].name, reaches[index][index], !reported.contains(index)
            else { return nil }

            for other in groups.indices where reaches[index][other] && reaches[other][index] {
                reported.insert(other)
            }

            return .error(.referenceCycle, "Group '\(name)' consumes an intermediate that depends on it.")
        })
    }

    /// Which groups each group reaches by consuming intermediates, through as many other groups
    /// as the consumption runs. A group reaching itself is one consuming its own intermediate,
    /// which is what a loop is.
    private var consumptionReach: [[Bool]] {
        var reaches = groups.map({ group in
            let dependencies = Set(dependencyIndices(of: group))

            return groups.indices.map(dependencies.contains)
        })

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
