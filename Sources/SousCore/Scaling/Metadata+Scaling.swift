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
        Metadata(entries: entries.map({ entry in
            switch entry.value {
            case let .scalar(value) where entry.key == HeaderField.servings
                && unit == HeaderField.servings:
                Entry(key: entry.key, value: .scalar(Self.stating(target, in: value)))
            case let .list(items) where entry.key == HeaderField.yield:
                Entry(key: entry.key, value: .list(items.map({ item in
                    DeclaredYield.matching(AmountParser.parse(unfenced: item).unit) == unit
                        ? Self.stating(target, in: item)
                        : item
                })))
            default:
                entry
            }
        }))
    }

    /// A value restated as a target, keeping the unit it was written with. A value stating no
    /// single quantity names no dimension, and one already stating the target has nothing to
    /// restate, so both come back exactly as written.
    private static func stating(_ target: Double, in value: String) -> String {
        let amount = AmountParser.parse(unfenced: value)
        guard let stated = amount.kind.soleValue, stated != target else { return value }

        return Amount([Quantity(target)], unit: amount.unit ?? "").text
    }
}
