extension Metadata {
    /// The header with every yield-bearing value multiplied by the factor.
    ///
    /// Only `servings` and `yield` scale. Every other key is literal text and is carried over
    /// unchanged.
    func scaled(by factor: Double) throws -> Metadata {
        Metadata(entries: try entries.map({ entry in
            guard HeaderField.scaling.contains(entry.key) else { return entry }

            switch entry.value {
            case let .scalar(value):
                return Entry(key: entry.key, value: .scalar(try Self.scaled(value, by: factor)))
            case let .list(items):
                return Entry(key: entry.key, value: .list(try items.map({ try Self.scaled($0, by: factor) })))
            case .raw:
                return entry
            }
        }))
    }

    /// The value scaled, or the original when it holds no scalable amount.
    private static func scaled(_ value: String, by factor: Double) throws -> String {
        try AmountParser.parse(unfenced: value).scaled(by: factor)?.text ?? value
    }

    /// The header with the yields matching the unit rewritten to the target exactly.
    ///
    /// Scaling by a factor can land just off the requested target through rounding, so the
    /// declared yield is restated rather than left as the multiplication produced it.
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

    /// The amount rewritten to the target, or `nil` when it already holds that value or holds no
    /// single quantity.
    private static func restated(_ target: Double, of amount: Amount) -> String? {
        guard let stated = amount.kind.soleValue, stated != target else { return nil }

        return Amount([Quantity(target)], unit: amount.unit ?? "").text
    }
}
