/// A yield a header declares: what it measures, and how much of it the recipe makes.
///
/// A yield reaches exactly as far as its own unit, so a target of `1 kg` finds no yield of
/// `800 g`. ``Recipe/scaled(to:)`` states why.
struct DeclaredYield {
    /// The unit the yield is matched by, with the whitespace around it removed: the unit as
    /// written, or `servings` for the alias. An amount stating no unit carries the empty one,
    /// which matches a target that states none either.
    var unit: String

    /// How much the recipe makes.
    var kind: Amount.Kind

    /// The unit a written yield or a target is matched by. Both sides of that comparison
    /// normalize through here, so the two can never drift apart. The `servings` alias needs
    /// none, because the key it is named by carries no whitespace.
    static func matching(_ unit: String?) -> String {
        SourceText.trimmed(unit ?? "")
    }
}

extension Metadata {
    /// Every yield the header declares that states a quantity, in document order, which is the
    /// order ``repeatedYields()`` reports a unit in.
    ///
    /// The `servings` value is read as the portion yield it is an alias for, and stands where
    /// the entry it is read from stands: a repeated scalar key is read from its last
    /// occurrence. The alias is named by the unit it stands for rather than by whatever follows
    /// its number, so `servings: 6 people` states six portions and not six people.
    var declaredYields: [DeclaredYield] {
        // A value stating no quantity states no dimension, so it stands for none, and it hides
        // no yield of the unit it was written with either.
        yieldRoles().flatMap(Self.declaredYields(from:)).filter({ !$0.kind.values.isEmpty })
    }

    /// The declared yields a header entry states, by the role scaling reads it as. An entry
    /// stating no yield states none.
    private static func declaredYields(from role: YieldRole) -> [DeclaredYield] {
        switch role {
        case let .servings(value):
            [DeclaredYield(unit: HeaderField.servings, kind: AmountParser.parse(unfenced: value).kind)]
        case let .yieldList(items):
            items.map({ item in
                let yield = AmountParser.parse(unfenced: item)

                return DeclaredYield(unit: DeclaredYield.matching(yield.unit), kind: yield.kind)
            })
        case .other:
            []
        }
    }

    /// Where the `servings` alias stands: the entry its value is read from, which is the last
    /// scalar one, or `nil` when the header states none.
    ///
    /// Reading the alias and restating it share this, so the entry that states the portions is
    /// the entry a target rewrites, and an earlier one it shadows is left to the factor.
    var aliasIndex: Int? {
        entries.lastIndex(where: { entry in
            guard entry.key == HeaderField.servings, case .scalar = entry.value else { return false }

            return true
        })
    }

    /// How scaling reads a header entry that may state a yield.
    enum YieldRole {
        /// The `servings` alias, carrying the scalar value the portion yield is read from.
        case servings(String)

        /// A `yield` entry, carrying the list of amounts it states.
        case yieldList([String])

        /// An entry that states no yield.
        case other
    }

    /// Each entry classified by the yield it states, in document order alongside ``entries``.
    ///
    /// Reading the yields and restating them to a target share this one recognition, so the two
    /// can never disagree on which entry states a yield.
    func yieldRoles() -> [YieldRole] {
        let alias = aliasIndex

        return entries.enumerated().map({ index, entry in
            switch entry.value {
            case let .scalar(value) where index == alias:
                .servings(value)
            case let .list(items) where entry.key == HeaderField.yield:
                .yieldList(items)
            default:
                .other
            }
        })
    }
}
