extension Amount.Kind {
    /// The quantities this kind holds: one for a precise amount, two for a range, none for an
    /// imprecise amount.
    var quantities: [Quantity] {
        switch self {
        case let .precise(quantity):
            [quantity]
        case let .range(low, high):
            [low, high]
        case .imprecise:
            []
        }
    }

    /// The numeric values of ``quantities``.
    var values: [Double] {
        quantities.values
    }

    /// The single numeric value, or `nil` for a range or an imprecise amount.
    var soleValue: Double? {
        // swiftlint:disable:next variable_shadowing
        let values = self.values
        return values.count == 1 ? values[0] : nil
    }
}

extension [Quantity] {
    /// The numeric values of these quantities.
    var values: [Double] {
        map(\.value)
    }
}
