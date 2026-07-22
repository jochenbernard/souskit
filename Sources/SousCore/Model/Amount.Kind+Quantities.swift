// The quantities an amount states, read the same way wherever they are needed: scaling
// multiplies them, a unit stated more than once has to agree on them, and scaling to a
// target divides by one.

extension Amount.Kind {
    /// The quantities the kind states, in order. An imprecise amount states none.
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

    /// The values those quantities state, which is what a factor moves and what two statements
    /// of one dimension have to agree on.
    var values: [Double] {
        quantities.values
    }

    /// The one value the kind states, or `nil` when it states none or more than one. A range
    /// states two, so it serves as neither a divisor nor a target.
    var soleValue: Double? {
        values.count == 1 ? values[0] : nil
    }
}

extension [Quantity] {
    /// The values the quantities state. A kind reads its own through here, and so does the
    /// writer, so what a factor moves is one thing however it is reached.
    var values: [Double] {
        map(\.value)
    }
}
