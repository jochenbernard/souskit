extension Metadata {
    /// Reports each dimension the header states more than one value for.
    ///
    /// A recipe declares at most one yield per dimension, counting `servings` and every `yield`
    /// entry together, so that scaling to a target of a dimension has a single value to divide
    /// by. Stating one twice is fine while both state the same amount.
    ///
    /// A dimension reaches exactly as far as the unit written, because telling that `800 g` and
    /// `1 kg` measure the same thing needs reference data. A value stating no quantity states
    /// no dimension either, and so disagrees with nothing.
    func conflictingYields() -> [Diagnostic] {
        var units: [String] = []
        var stated: [String: Set<[Double]>] = [:]

        for yield in declaredYields where !yield.kind.values.isEmpty {
            if stated[yield.unit] == nil { units.append(yield.unit) }
            stated[yield.unit, default: []].insert(yield.kind.values)
        }

        return units
            .filter({ stated[$0].map({ $0.count > 1 }) ?? false })
            .map({ .error(.conflictingYields, Self.conflictMessage(in: $0)) })
    }

    private static func conflictMessage(in unit: String) -> String {
        unit.isEmpty
            ? "Header states more than one yield with no unit."
            : "Header states more than one yield in '\(unit)'."
    }
}
