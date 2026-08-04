extension Quantity {
    /// A quantity whose text is the value written without a trailing `.0`.
    init(_ value: Double) {
        self.init(value: value, text: Self.written(value))
    }

    /// A quantity whose text always carries a decimal point, so a whole number reads back as one
    /// number rather than as the start of a mixed fraction.
    init(pointed value: Double) {
        self.init(value: value, text: Self.pointed(value))
    }

    /// The quantity multiplied by the factor.
    func scaled(by factor: Double) -> Quantity {
        Quantity(value * factor)
    }

    /// Whether a value can be written back as a quantity.
    static func isWritable(_ value: Double) -> Bool {
        value.isFinite && value.sign == .plus
    }

    /// The value written without a trailing `.0`.
    private static func written(_ value: Double) -> String {
        let text = positional(String(value))

        return text.hasSuffix(wholeSuffix) ? String(text.dropLast(wholeSuffix.count)) : text
    }

    /// The value written with a decimal point, adding `.0` when it has none.
    private static func pointed(_ value: Double) -> String {
        let text = positional(String(value))

        return text.contains(AmountParser.decimalPoint) ? text : text + wholeSuffix
    }

    private static let wholeSuffix = "\(AmountParser.decimalPoint)0"

    /// The text with any exponent expanded into positional digits.
    ///
    /// Swift writes large and small values as `1e-05`, which reads back as the quantity `1`
    /// followed by the unit `e-05`.
    private static func positional(_ text: String) -> String {
        guard
            let mark = text.firstIndex(of: exponentMark),
            let exponent = Int(text[text.index(after: mark)...])
        else {
            return text
        }

        var digits = Array(text[..<mark])
        let point = digits.firstIndex(of: AmountParser.decimalPoint) ?? digits.count
        digits.removeAll(where: { $0 == AmountParser.decimalPoint })

        return placed(digits, pointAt: point + exponent)
    }

    /// The digits with the decimal point at the given position, padding with zeros on whichever
    /// side the position falls outside.
    private static func placed(_ digits: [Character], pointAt position: Int) -> String {
        if position <= 0 {
            return "0\(AmountParser.decimalPoint)" + String(repeating: zero, count: -position) + String(digits)
        }
        if position >= digits.count {
            return String(digits) + String(repeating: zero, count: position - digits.count)
        }

        return String(digits[..<position]) + String(AmountParser.decimalPoint) + String(digits[position...])
    }

    private static let exponentMark: Character = "e"
    private static let zero: Character = "0"
}
