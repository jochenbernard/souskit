extension Amount {
    /// An amount built from quantities and a unit, taken from reading the text they are written
    /// as.
    ///
    /// Building by reading back keeps ``Amount/text`` and ``Amount/kind`` in agreement. When the
    /// round trip does not reproduce the values, the quantities are rewritten with an explicit
    /// decimal point, which reads back unambiguously.
    init(_ quantities: [Quantity], unit: String?) {
        let read = AmountParser.parse(Self.written(quantities, unit: unit))
        if read.kind.values == quantities.values, read.unit == unit {
            self = read
            return
        }

        let pointed = quantities.map({ Quantity(pointed: $0.value) })

        self = AmountParser.parse(Self.written(pointed, unit: unit))
    }

    /// The amount scaled, or `nil` when it does not move.
    ///
    /// A fixed amount and an imprecise one never move, and neither does one whose scaled values
    /// equal its current ones. Throws ``ScalingError/unwritableQuantity`` when a scaled value is
    /// no longer finite.
    func scaled(by factor: Double) throws -> Amount? {
        guard !isFixed else { return nil }

        let scaled = kind.quantities.map({ $0.scaled(by: factor) })
        let values = scaled.values

        guard values != kind.values else { return nil }
        guard values.allSatisfy(Quantity.isWritable) else { throw ScalingError.unwritableQuantity }

        return Amount(scaled, unit: unit)
    }

    /// The text quantities and a unit are written as, a range joined by its separator.
    private static func written(_ quantities: [Quantity], unit: String?) -> String {
        let text = quantities.map(\.text).joined(separator: String(AmountParser.rangeSeparator))

        guard let unit else { return text }

        return "\(text)\(AmountParser.unitSeparator)\(unit)"
    }
}
