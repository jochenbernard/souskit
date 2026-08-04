/// A yield a recipe declares, which a scaling target can be divided by.
struct DeclaredYield {
    /// The unit, trimmed, or `servings` for the servings alias.
    var unit: String

    /// The quantity or range declared.
    var kind: Amount.Kind

    /// The form a unit is matched in, so a target and a yield compare alike.
    static func matching(_ unit: String?) -> String {
        SourceText.trimmed(unit ?? "")
    }
}

extension Metadata {
    /// Every yield the header declares, in document order, omitting those with no usable number.
    var declaredYields: [DeclaredYield] {
        yieldRoles().flatMap(Self.declaredYields(from:)).filter({ !$0.kind.values.isEmpty })
    }

    /// The yields one entry declares.
    private static func declaredYields(from role: YieldRole) -> [DeclaredYield] {
        switch role {
        case let .servings(value):
            [DeclaredYield(unit: HeaderField.servings, kind: AmountParser.parse(unfenced: value).kind)]
        case let .yieldList(items):
            items.map { item in
                let yield = AmountParser.parse(unfenced: item)

                return DeclaredYield(unit: DeclaredYield.matching(yield.unit), kind: yield.kind)
            }
        case .other:
            []
        }
    }

    /// The index of the entry acting as the servings alias: the last scalar `servings` entry.
    var aliasIndex: Int? {
        entries.lastIndex(where: { entry in
            guard entry.key == HeaderField.servings, case .scalar = entry.value else { return false }

            return true
        })
    }

    /// The part an entry plays in declaring a yield.
    enum YieldRole {
        /// The servings alias, carrying its value.
        case servings(String)

        /// A `yield` list, carrying its items.
        case yieldList([String])

        /// An entry declaring no yield.
        case other
    }

    /// The role of each entry, positionally matching ``entries``.
    func yieldRoles() -> [YieldRole] {
        let alias = aliasIndex

        return entries.enumerated().map { index, entry in
            switch entry.value {
            case let .scalar(value) where index == alias:
                .servings(value)
            case let .list(items) where entry.key == HeaderField.yield:
                .yieldList(items)
            default:
                .other
            }
        }
    }
}
