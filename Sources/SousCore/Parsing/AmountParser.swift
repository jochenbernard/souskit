// Parses the verbatim content of an `{...}` amount fence.
//
// The leading run of numeric characters is the quantity and everything after it is the
// unit. The split is purely positional, so no unit vocabulary is involved. Content with
// no leading digit is an imprecise amount, kept verbatim.

enum AmountParser {
    /// The value of the leading numeric quantity in `text`, or `nil` when it has no leading
    /// number. Integers, decimals, fractions, and mixed numbers are all recognized, exactly
    /// as in an amount fence.
    static func leadingValue(in text: String) -> Double? {
        number(in: Array(text), from: 0)?.quantity.value
    }

    static func parse(_ fence: String) -> Amount {
        let characters = Array(fence)

        // The `=` marker is read when version 0.2 is implemented, so no amount is fixed yet.
        guard let first = number(in: characters, from: 0) else {
            return Amount(
                kind: .imprecise(fence),
                unit: nil,
                isFixed: false,
                text: fence
            )
        }

        let kind: Amount.Kind
        var cursor = first.end

        if cursor < characters.count,
           characters[cursor] == "-",
           let second = number(in: characters, from: cursor + 1) {
            kind = .range(first.quantity, second.quantity)
            cursor = second.end
        } else {
            kind = .precise(first.quantity)
        }

        // A single space separates the quantity from the unit; anything else belongs to the unit.
        if cursor < characters.count, characters[cursor] == " " {
            cursor += 1
        }

        return Amount(
            kind: kind,
            unit: String(characters[cursor...]),
            isFixed: false,
            text: fence
        )
    }

    /// Scans one quantity: a number, a fraction, or a mixed number.
    private static func number(in characters: [Character], from start: Int) -> (quantity: Quantity, end: Int)? {
        guard let leading = decimal(in: characters, from: start) else { return nil }

        var end = leading.end
        var value = leading.value
        // The mixed form follows a whole number, so a decimal one never opens one.
        let isWhole = !characters[start..<end].contains(".")

        if let bare = denominator(in: characters, from: end) {
            // A bare fraction, whose numerator is the number just scanned.
            value /= bare.value
            end = bare.end
        } else if isWhole,
                  end < characters.count,
                  characters[end] == " ",
                  let mixed = fraction(in: characters, from: end + 1) {
            // A mixed number: a whole number, a single space, then a fraction.
            value += mixed.value
            end = mixed.end
        }

        return (Quantity(value: value, text: String(characters[start..<end])), end)
    }

    /// Scans a fraction, a `/` between two numbers, returning its value and the index just
    /// past it.
    private static func fraction(in characters: [Character], from start: Int) -> (value: Double, end: Int)? {
        guard let numerator = decimal(in: characters, from: start),
              let denominator = denominator(in: characters, from: numerator.end)
        else { return nil }

        return (numerator.value / denominator.value, denominator.end)
    }

    /// Scans a `/` and the number after it, whose value must be non-zero, so a fraction is
    /// never divided by zero.
    private static func denominator(in characters: [Character], from start: Int) -> (value: Double, end: Int)? {
        guard start < characters.count,
              characters[start] == "/",
              let run = decimal(in: characters, from: start + 1),
              run.value != 0.0
        else { return nil }

        return (run.value, run.end)
    }

    /// Scans a number: a run of digits, optionally followed by a decimal point and another
    /// run. The point belongs to the number only between digits, so `3.` stops at the `3`
    /// and `3,2` stops at the comma.
    private static func decimal(in characters: [Character], from start: Int) -> (value: Double, end: Int)? {
        guard let leading = digits(in: characters, from: start) else { return nil }

        guard leading.end + 1 < characters.count,
              characters[leading.end] == ".",
              let decimals = digits(in: characters, from: leading.end + 1)
        else { return leading }

        return (Double(String(characters[start..<decimals.end])) ?? leading.value, decimals.end)
    }

    /// Scans a run of ASCII digits, returning its value and the index just past it.
    private static func digits(in characters: [Character], from start: Int) -> (value: Double, end: Int)? {
        var cursor = start
        while cursor < characters.count, SourceText.isDigit(characters[cursor]) { cursor += 1 }
        guard cursor > start else { return nil }

        return (Double(String(characters[start..<cursor])) ?? 0.0, cursor)
    }
}
