extension Amount {
    /// The amount some quantities and a unit state, read back from the text they are written
    /// as, so a scaled amount states what a reader would read back from it.
    ///
    /// One space separates the quantity from the unit and belongs to neither, which is the
    /// same one the reader steps over. A mixed number is written with that space too, though,
    /// so a unit opening a fraction is read into a whole quantity. The text is therefore read
    /// back before it is taken, rather than the writer second-guessing the reader.
    ///
    /// It is read as fence content, where a leading `=` would fix the amount. A quantity's text
    /// is digits, so none can open with one and no rebuilt amount is ever fixed.
    init(_ quantities: [Quantity], unit: String) {
        let read = AmountParser.parse(Self.written(quantities, unit: unit))
        if read.kind.values == quantities.values, read.unit == unit {
            self = read
            return
        }

        // The unit was read into the quantity, so the quantity is spelled with a decimal
        // point, which no fraction can follow into a mixed number.
        let pointed = quantities.map({ Quantity(pointed: $0.value) })

        self = AmountParser.parse(Self.written(pointed, unit: unit))
    }

    /// The amount multiplied by a factor, or `nil` when it states nothing that moves.
    ///
    /// A fixed amount is held constant, an imprecise one states no quantity to move, and a
    /// quantity the factor leaves where it is has not moved either. An amount is rewritten
    /// exactly where a value changed, which is what makes scaling by one rewrite nothing.
    ///
    /// - Throws: ``ScalingError/unwritableQuantity`` when a product cannot be written back.
    func scaled(by factor: Double) throws -> Amount? {
        guard !isFixed else { return nil }

        let scaled = kind.scaled(by: factor)
        let values = scaled.values

        guard values != kind.values else { return nil }
        guard values.allSatisfy(Quantity.isWritable) else { throw ScalingError.unwritableQuantity }

        return Amount(scaled.quantities, unit: unit ?? "")
    }

    /// A quantity with no unit is followed by nothing.
    private static func written(_ quantities: [Quantity], unit: String) -> String {
        let text = quantities.map(\.text).joined(separator: String(AmountParser.rangeSeparator))

        return unit.isEmpty ? text : "\(text)\(AmountParser.unitSeparator)\(unit)"
    }
}

extension Amount.Kind {
    /// The kind with every quantity it states multiplied by a factor. One stating none comes
    /// back as it was.
    func scaled(by factor: Double) -> Self {
        switch self {
        case let .precise(quantity):
            .precise(quantity.scaled(by: factor))
        case let .range(low, high):
            .range(low.scaled(by: factor), high.scaled(by: factor))
        case .imprecise:
            self
        }
    }
}
