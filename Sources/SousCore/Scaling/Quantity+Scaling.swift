extension Quantity {
    /// The quantity a value states, with the text it is written back as.
    ///
    /// Scaling produces quantities no source text states, so this text is built from the value
    /// rather than read from what was written.
    init(_ value: Double) {
        self.init(value: value, text: Self.written(value))
    }

    /// The quantity a value states, written with a decimal point whatever the value.
    ///
    /// A mixed number is a whole number, one space, and a fraction, so a unit opening a
    /// fraction is read into a quantity written without a point. The point keeps the two
    /// apart and states the same value.
    init(pointed value: Double) {
        self.init(value: value, text: Self.pointed(value))
    }

    /// The quantity multiplied by a factor.
    func scaled(by factor: Double) -> Quantity {
        Quantity(value * factor)
    }

    /// Whether this writer can render a value as a quantity a reader reads back.
    ///
    /// A quantity is a leading run of digits, so a value that is not finite, and one that
    /// carries a sign, both write text that is not one. Reading produces neither: a quantity
    /// comes from digits alone and a factor is never negative, so only a mutated model states
    /// a negative value here.
    static func isWritable(_ value: Double) -> Bool {
        value.isFinite && value.sign == .plus
    }

    /// The shortest positional decimal that reads back as that same value: a whole value
    /// carries no point, so multiplying whole quantities keeps them whole, and nothing is ever
    /// rounded, because the language leaves convenient quantities to applications.
    private static func written(_ value: Double) -> String {
        let text = positional(String(value))

        return text.hasSuffix(wholeSuffix) ? String(text.dropLast(wholeSuffix.count)) : text
    }

    /// The same decimal with a point, added when the value is whole and so carries none.
    private static func pointed(_ value: Double) -> String {
        let text = positional(String(value))

        return text.contains(AmountParser.decimalPoint) ? text : text + wholeSuffix
    }

    /// What Swift writes after a value with nothing after the point.
    private static let wholeSuffix = "\(AmountParser.decimalPoint)0"

    /// The same digits placed around the point, for a value Swift writes in exponent notation.
    ///
    /// Only a leading run of digits is a quantity, so an exponent would end the number at the
    /// `e` and leave the rest to be read as the unit. Moving the point instead states the value
    /// the reader reads, and only from 1e16 up or below 1e-4 is there a point to move.
    ///
    /// A factor is never negative and a quantity is read from digits alone, so no value
    /// reaching here carries a sign.
    private static func positional(_ text: String) -> String {
        guard let mark = text.firstIndex(of: exponentMark),
              let exponent = Int(text[text.index(after: mark)...])
        else { return text }

        var digits = Array(text[..<mark])
        let point = digits.firstIndex(of: AmountParser.decimalPoint) ?? digits.count
        digits.removeAll(where: { $0 == AmountParser.decimalPoint })

        return placed(digits, pointAt: point + exponent)
    }

    /// The digits with the point at the given position, padded with the zeros that position
    /// needs on whichever side it falls outside them.
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
