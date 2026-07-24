extension Metadata {
    /// The header with the fields that state how much the recipe makes multiplied by a factor,
    /// so a scaled recipe still states what it makes.
    ///
    /// Everything else, an unknown key and a preserved line included, is carried through as
    /// written, because a number elsewhere in the header states something scaling has no
    /// business multiplying.
    ///
    /// - Throws: ``ScalingError/unwritableQuantity`` when a product cannot be written back.
    func scaled(by factor: Double) throws -> Metadata {
        Metadata(entries: try entries.map({ entry in
            guard HeaderField.scaling.contains(entry.key) else { return entry }

            switch entry.value {
            case let .scalar(value):
                return Entry(key: entry.key, value: .scalar(try Self.scaled(value, by: factor)))
            case let .list(items):
                return Entry(key: entry.key, value: .list(try items.map({ try Self.scaled($0, by: factor) })))
            // A preserved line carries the empty key, which no scaling field is, so this arm
            // is exhaustiveness rather than a case any header reaches.
            case .raw:
                return entry
            }
        }))
    }

    /// A value stating an amount, multiplied by a factor. A value stating none, and one the
    /// factor leaves where it is, come back exactly as written, whitespace and all. One that
    /// moves is rewritten from what it states, so the whitespace around it goes with the value.
    private static func scaled(_ value: String, by factor: Double) throws -> String {
        try AmountParser.parse(unfenced: value).scaled(by: factor)?.text ?? value
    }

    /// The header with every yield in a unit stating a target exactly.
    ///
    /// A factor is derived by dividing and applied by multiplying, and the two do not always
    /// land back on the number the division started from. The target is a value its caller
    /// stated, so the yields naming its unit are written as that value rather than as the
    /// product the factor left. Every other yield is that product, because nothing else was
    /// asked for.
    func stating(_ target: Double, in unit: String) -> Metadata {
        Metadata(entries: zip(entries, yieldRoles()).map({ entry, role in
            switch role {
            case let .servings(value) where unit == HeaderField.servings:
                Entry(
                    key: entry.key,
                    value: .scalar(Self.restated(target, of: AmountParser.parse(unfenced: value)) ?? value)
                )
            case let .yieldList(items):
                Entry(key: entry.key, value: .list(items.map({ item in
                    let amount = AmountParser.parse(unfenced: item)

                    return DeclaredYield.matching(amount.unit) == unit
                        ? Self.restated(target, of: amount) ?? item
                        : item
                })))
            default:
                entry
            }
        }))
    }

    /// The amount restated as the target, keeping the unit it was written with, or `nil` when it
    /// already states the target or states no single quantity to restate.
    private static func restated(_ target: Double, of amount: Amount) -> String? {
        guard let stated = amount.kind.soleValue, stated != target else { return nil }

        return Amount([Quantity(target)], unit: amount.unit ?? "").text
    }
}
