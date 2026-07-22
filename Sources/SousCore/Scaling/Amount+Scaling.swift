extension Amount {
    /// The amount a kind and a unit state, with the text it is written back as.
    ///
    /// An amount built this way is one nobody wrote, so its text comes from what it states.
    /// None is fixed, because a fixed amount never moves and so is never rebuilt.
    init(kind: Kind, unit: String?) {
        self.init(kind: kind, unit: unit, isFixed: false, text: Self.written(kind, unit: unit))
    }

    /// The amount multiplied by a factor, or `nil` when it states nothing that moves.
    ///
    /// A fixed amount never moves and an imprecise one states no quantity to move. Neither
    /// does a quantity the factor leaves where it is, so an amount is rewritten exactly where
    /// its value changed, which is what leaves a fraction a factor divides out of alone and
    /// makes scaling by one rewrite nothing at all.
    func scaled(by factor: Double) -> Amount? {
        guard !isFixed else { return nil }

        let scaled = kind.scaled(by: factor)
        guard scaled.values != kind.values else { return nil }

        return Amount(kind: scaled, unit: unit)
    }

    /// One space separates the quantity from the unit and belongs to neither, which is the
    /// same one the reader steps over. A quantity with no unit is followed by nothing.
    private static func written(_ kind: Kind, unit: String?) -> String {
        guard let unit, !unit.isEmpty else { return kind.text }

        return "\(kind.text) \(unit)"
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
