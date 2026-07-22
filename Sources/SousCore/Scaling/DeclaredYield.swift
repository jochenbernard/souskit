/// A yield a header declares: what it measures, and how much of it the recipe makes.
///
/// A dimension is what a unit measures, and recognizing two spellings of one needs reference
/// data. So a yield reaches exactly as far as its own unit here, and scaling to a target of
/// `1 kg` finds no yield of `800 g`.
struct DeclaredYield {
    /// The unit as written, with the whitespace around it removed. An amount stating no unit
    /// carries the empty one, which matches a target that states none either.
    var unit: String

    /// How much the recipe makes.
    var kind: Amount.Kind
}

extension Metadata {
    /// Every yield the header declares, in the order a target is matched against them, with
    /// the `servings` value read as the portion yield it is an alias for.
    ///
    /// The alias is named by the unit it stands for rather than by whatever follows its
    /// number, so `servings: 6 people` states six portions and not six people.
    var declaredYields: [DeclaredYield] {
        var declared: [DeclaredYield] = []

        if let servings = entries.lastScalar(HeaderField.servings) {
            declared.append(DeclaredYield(
                unit: HeaderField.servings,
                kind: AmountParser.parse(SourceText.trimmed(servings)).kind
            ))
        }

        return declared + yields.map({ yield in
            DeclaredYield(unit: SourceText.trimmed(yield.unit ?? ""), kind: yield.kind)
        })
    }
}
