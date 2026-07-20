// Parses the verbatim content of an `{...}` amount fence.
//
// The leading run of numeric characters is the quantity and everything after it is the
// unit. The split is purely positional, so no unit vocabulary is involved. Content with
// no leading digit is an imprecise amount, kept verbatim.

enum AmountParser {
    static func parse(_ fence: String) -> Amount {
        let characters = Array(fence)

        guard let first = number(in: characters, from: 0) else {
            return Amount(
                kind: .imprecise(fence),
                unit: nil,
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
            text: fence
        )
    }

    /// Scans one quantity: an integer, a decimal, a fraction, or a mixed number.
    private static func number(in characters: [Character], from start: Int) -> (quantity: Quantity, end: Int)? {
        guard let leading = digits(in: characters, from: start) else { return nil }

        var end = leading.end
        var value = leading.value

        // The decimal point is always ".", so "3,2" stops at the comma.
        if end + 1 < characters.count,
           characters[end] == ".",
           let decimals = digits(in: characters, from: end + 1) {
            value = Double(String(characters[start..<decimals.end])) ?? value
            end = decimals.end
        }

        if let bare = denominator(in: characters, from: end) {
            // A bare fraction, whose numerator is the run just scanned.
            value /= bare.value
            end = bare.end
        } else if end < characters.count,
                  characters[end] == " ",
                  let mixed = fraction(in: characters, from: end + 1) {
            // A mixed number: a whole number, a single space, then a fraction.
            value += mixed.value
            end = mixed.end
        }

        return (Quantity(value: value, text: String(characters[start..<end])), end)
    }

    /// Scans an `n/n` fraction, returning its value and the index just past it.
    private static func fraction(in characters: [Character], from start: Int) -> (value: Double, end: Int)? {
        guard let numerator = digits(in: characters, from: start),
              let denominator = denominator(in: characters, from: numerator.end)
        else { return nil }

        return (numerator.value / denominator.value, denominator.end)
    }

    /// Scans a `/n` denominator with a non-zero value, returning its value and the index
    /// just past it. A zero denominator does not match, so it is never divided by.
    private static func denominator(in characters: [Character], from start: Int) -> (value: Double, end: Int)? {
        guard start < characters.count,
              characters[start] == "/",
              let run = digits(in: characters, from: start + 1),
              run.value != 0.0
        else { return nil }

        return (run.value, run.end)
    }

    /// Scans a run of ASCII digits, returning its value and the index just past it.
    private static func digits(in characters: [Character], from start: Int) -> (value: Double, end: Int)? {
        var cursor = start
        while cursor < characters.count, SourceText.isDigit(characters[cursor]) { cursor += 1 }
        guard cursor > start else { return nil }

        return (Double(String(characters[start..<cursor])) ?? 0.0, cursor)
    }
}
