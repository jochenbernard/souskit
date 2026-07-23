// Parses the verbatim content of an `{...}` amount fence.
//
// The leading run of numeric characters is the quantity and everything after it is the
// unit. The split is purely positional, so no unit vocabulary is involved. Content with
// no leading digit is an imprecise amount, kept verbatim.

enum AmountParser {
    /// The character between the two ends of a range. Reading and writing share it, so a range
    /// a reader recognizes is a range a writer produces.
    static let rangeSeparator: Character = "-"

    /// The one space that may separate a quantity from its unit, belonging to neither. Reading
    /// and writing share it, so the unit a writer sets apart is the unit a reader reads.
    static let unitSeparator: Character = " "

    /// The character between a number's whole and fractional parts. Reading and writing share
    /// it, so a decimal a writer produces is a decimal a reader recognizes, which is what keeps
    /// a written quantity from running into a unit that opens a fraction.
    static let decimalPoint: Character = "."

    /// Parses the content of an amount fence, where a leading `=` marks the amount fixed.
    static func parse(_ fence: String) -> Amount {
        parse(fence, fenced: true)
    }

    /// Parses a value stating an amount that no fence holds, such as a header field's or one
    /// part of a timer.
    ///
    /// The fixed marker belongs to the fence, so a leading `=` is ordinary text here, which
    /// leaves the amount imprecise as any other content with no leading number is. The
    /// whitespace around such a value is layout rather than part of what it states, so it is
    /// removed before reading, which a fence's own content never is.
    static func parse(unfenced text: String) -> Amount {
        parse(SourceText.trimmed(text), fenced: false)
    }

    private static func parse(_ text: String, fenced: Bool) -> Amount {
        let characters = Array(text)
        // The marker fixes an amount only immediately before a numeric quantity. Anywhere
        // else it is ordinary text, and the amount it opens is imprecise like any other,
        // which is what the quantity scan failing below already reports.
        let isMarked = fenced && characters.first == AmountFence.fixedMarker

        guard let quantity = quantity(in: characters, from: isMarked ? 1 : 0) else {
            return Amount(
                kind: .imprecise(text),
                unit: nil,
                isFixed: false,
                text: text
            )
        }

        // A single space separates the quantity from the unit; anything else belongs to the unit.
        var cursor = quantity.end
        if cursor < characters.count, characters[cursor] == unitSeparator {
            cursor += 1
        }

        return Amount(
            kind: quantity.kind,
            unit: String(characters[cursor...]),
            isFixed: isMarked,
            text: text
        )
    }

    /// Scans the quantity at `start`: one number, or a range between two of them. Returns the
    /// form it takes and the index just past it.
    ///
    /// The fixed marker is the fence's own rather than the quantity's, so it is not read here.
    /// A caller that reads one scans from the index after it, and a caller with no fence, such
    /// as a timer, never reads one at all.
    static func quantity(in characters: [Character], from start: Int) -> (kind: Amount.Kind, end: Int)? {
        guard let first = number(in: characters, from: start) else { return nil }

        guard first.end < characters.count,
              characters[first.end] == rangeSeparator,
              let second = number(in: characters, from: first.end + 1)
        else { return (.precise(first.quantity), first.end) }

        return (.range(first.quantity, second.quantity), second.end)
    }

    /// Scans one quantity: a number, a fraction, or a mixed number.
    private static func number(in characters: [Character], from start: Int) -> (quantity: Quantity, end: Int)? {
        guard let leading = decimal(in: characters, from: start) else { return nil }

        var end = leading.end
        var value = leading.value
        // The mixed form follows a whole number, so a decimal one never opens one.
        let isWhole = !characters[start..<end].contains(decimalPoint)

        if let bare = denominator(in: characters, from: end) {
            // A bare fraction, whose numerator is the number just scanned.
            value /= bare.value
            end = bare.end
        } else if isWhole,
                  end < characters.count,
                  characters[end] == unitSeparator,
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
              characters[leading.end] == decimalPoint,
              let decimals = digits(in: characters, from: leading.end + 1)
        else { return leading }

        return (Double(String(characters[start..<decimals.end])) ?? leading.value, decimals.end)
    }

    /// Scans a run of ASCII digits, returning its value and the index just past it.
    private static func digits(in characters: [Character], from start: Int) -> (value: Double, end: Int)? {
        let end = SourceText.run(in: characters, from: start, while: SourceText.isDigit)
        guard end > start else { return nil }

        return (Double(String(characters[start..<end])) ?? 0.0, end)
    }
}
