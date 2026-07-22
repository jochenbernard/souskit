// The quantities an amount states, read the same way wherever they are needed: scaling
// multiplies them, validation compares them, and scaling to a target divides by one.

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
        quantities.map(\.value)
    }

    /// The one value the kind states, or `nil` when it states none or more than one. A range
    /// states two, so it serves as neither a divisor nor a target.
    var soleValue: Double? {
        values.count == 1 ? values[0] : nil
    }

    /// The text the quantities are written back as, without the unit that follows them.
    var text: String {
        switch self {
        case let .precise(quantity):
            quantity.text
        case let .range(low, high):
            "\(low.text)\(AmountParser.rangeSeparator)\(high.text)"
        case let .imprecise(text):
            text
        }
    }
}
