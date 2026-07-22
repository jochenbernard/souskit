extension Quantity {
    /// The quantity a value states, with the text it is written back as.
    ///
    /// Scaling produces quantities no source text states, so this text is built from the value
    /// rather than read from what was written.
    init(_ value: Double) {
        self.init(value: value, text: Self.written(value))
    }

    /// The quantity multiplied by a factor.
    func scaled(by factor: Double) -> Quantity {
        Quantity(value * factor)
    }

    /// The shortest decimal that reads back as that same value, written positionally: a whole
    /// value carries no point, so multiplying whole quantities keeps them whole, and nothing
    /// is ever rounded, because the language leaves convenient quantities to applications.
    private static func written(_ value: Double) -> String {
        let text = positional(String(value))

        return text.hasSuffix(wholeSuffix) ? String(text.dropLast(wholeSuffix.count)) : text
    }

    /// What Swift writes after a value with nothing behind the point.
    private static let wholeSuffix = ".0"

    /// The same digits placed around the point, for a value Swift writes in exponent notation.
    ///
    /// Only a leading run of digits is a quantity, so an exponent would end the number at the
    /// `e` and leave the rest to be read as the unit. Moving the point instead states the value
    /// the reader reads, and only past 1e16 or below 1e-4 is there a point to move.
    ///
    /// A factor is never negative and a quantity is read from digits alone, so no value
    /// reaching here carries a sign.
    private static func positional(_ text: String) -> String {
        guard let mark = text.firstIndex(of: exponentMark),
              let exponent = Int(text[text.index(after: mark)...])
        else { return text }

        var digits = Array(text[..<mark])
        let point = digits.firstIndex(of: decimalPoint) ?? digits.count
        digits.removeAll(where: { $0 == decimalPoint })

        return placed(digits, pointAt: point + exponent)
    }

    /// The digits with the point at the given position, padded with the zeros that position
    /// needs on whichever side it falls outside them.
    private static func placed(_ digits: [Character], pointAt position: Int) -> String {
        if position <= 0 {
            return "0\(decimalPoint)" + String(repeating: zero, count: -position) + String(digits)
        }
        if position >= digits.count {
            return String(digits) + String(repeating: zero, count: position - digits.count)
        }

        return String(digits[..<position]) + String(decimalPoint) + String(digits[position...])
    }

    private static let exponentMark: Character = "e"
    private static let decimalPoint: Character = "."
    private static let zero: Character = "0"
}
