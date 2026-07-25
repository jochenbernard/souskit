// Parses the verbatim content of an `{...}` amount fence.
//
// The leading run of numeric characters is the quantity and everything after it is the
// unit. The split is purely positional, so no unit vocabulary is involved. Content with
// no leading digit is an imprecise amount, kept verbatim.

enum AmountParser {
    /// The character between the two ends of a range. Reading and writing share it, so a range
    /// a reader recognizes is a range a writer produces.
    static let rangeSeparator: Character = "-"

    /// The one space a writer separates a unit from its quantity with. A reader takes any run
    /// of whitespace for that separation and trims it away, so what a writer produces is the
    /// one form of it that states nothing extra.
    static let unitSeparator: Character = " "

    /// The character between a number's whole and fractional parts. Reading and writing share
    /// it, so a decimal a writer produces is a decimal a reader recognizes, which is what keeps
    /// a written quantity from running into a unit that opens a fraction.
    static let decimalPoint: Character = "."

    /// The character many languages write a decimal point with and Sous never does. It states
    /// no decimal here, and it is also the separator an inline list is written with, so reading
    /// one would state something different inside a list than outside it. A quantity running
    /// into one is reported rather than read as the number standing before it.
    static let commaPoint: Character = ","

    /// The character between a fraction's numerator and its denominator.
    static let fractionSeparator: Character = "/"

    /// What an amount opened as a number and could not finish with, which leaves it stating no
    /// quantity at all rather than the number standing before the defect.
    ///
    /// Reading reports one where it can point at it, so a wrong quantity neither scales nor
    /// aggregates and the author is told which spelling the language reads.
    enum Defect {
        /// A decimal point the quantity cannot use: a comma, or a point no digit follows.
        case decimalPoint

        /// A fraction with no number, or a zero, where its denominator belongs.
        case fraction

        /// A number-shaped text with no leading digit, such as `.5` or `-2`.
        case leadingCharacter

        /// What a reader states about the defect.
        var message: String {
            switch self {
            case .decimalPoint:
                "Amount states a decimal point it cannot use; a decimal is written '.' between digits."
            case .fraction:
                "Amount states a fraction with no number other than zero under it."
            case .leadingCharacter:
                "Amount opens as a number with no leading digit; a quantity opens with one, as in '0.5'."
            }
        }
    }

    /// Parses the content of an amount fence, where a leading `=` marks the amount fixed.
    static func parse(_ fence: String) -> Amount {
        parse(fence, fenced: true)
    }

    /// What the text opened as a number and could not finish with, or `nil` where it states a
    /// quantity or states no number at all.
    ///
    /// Reading an amount and reporting one are separate, because an amount is read where no
    /// diagnostic can be attached to it and a defect is worth reporting only where one can.
    ///
    /// - Parameters:
    ///   - text: The text the amount is read from.
    ///   - fenced: Whether a fence holds it, which is what gives a leading `=` its meaning.
    static func defect(in text: String, fenced: Bool = true) -> Defect? {
        let characters = Array(SourceText.trimmed(text))
        let start = fenced && characters.first == AmountFence.fixedMarker ? 1 : 0

        guard let scanned = scannedQuantity(in: characters, from: start) else {
            return leadingDefect(in: characters, from: start)
        }

        return defect(in: characters, at: scanned.end)
    }

    /// The defect a text with no quantity opens with, which is a number's own punctuation
    /// standing where its leading digit belongs.
    private static func leadingDefect(in characters: [Character], from start: Int) -> Defect? {
        guard let first = SourceText.character(in: characters, at: start),
              first == decimalPoint || first == commaPoint || first == rangeSeparator,
              let following = SourceText.character(in: characters, at: start + 1),
              SourceText.isDigit(following)
        else { return nil }

        return .leadingCharacter
    }

    /// The defect the character just past a scanned number states, that character being the one
    /// a number would have run on through had it been written the way the language reads.
    private static func defect(in characters: [Character], at end: Int) -> Defect? {
        switch SourceText.character(in: characters, at: end) {
        case decimalPoint, commaPoint: .decimalPoint
        case fractionSeparator: .fraction
        default: nil
        }
    }

    /// Parses a value stating an amount that no fence holds, such as a header field's or one
    /// part of a timer.
    ///
    /// The fixed marker belongs to the fence, so a leading `=` is ordinary text here, which
    /// leaves the amount imprecise as any other content with no leading number is.
    static func parse(unfenced text: String) -> Amount {
        parse(text, fenced: false)
    }

    /// The whitespace around a value is layout rather than part of what it states, so it is
    /// removed before reading and a fence states what the header value of the same text does.
    private static func parse(_ value: String, fenced: Bool) -> Amount {
        let text = SourceText.trimmed(value)
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

        // The whitespace between the quantity and the unit separates the two and belongs to
        // neither, so the unit opens where that run ends.
        let cursor = SourceText.run(in: characters, from: quantity.end, while: \.isWhitespace)

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
        // A number the text could not finish states none, so what stands before the defect is
        // never read as the quantity the author meant.
        guard let scanned = scannedQuantity(in: characters, from: start),
              defect(in: characters, at: scanned.end) == nil
        else { return nil }

        return scanned
    }

    /// The quantity the text states, read without asking whether it finishes: one number, or a
    /// range between two of them.
    private static func scannedQuantity(
        in characters: [Character],
        from start: Int
    ) -> (kind: Amount.Kind, end: Int)? {
        guard let first = number(in: characters, from: start) else { return nil }

        guard first.end < characters.count,
              characters[first.end] == rangeSeparator,
              let second = number(in: characters, from: first.end + 1)
        else { return (.precise(first.quantity), first.end) }

        return (.range(first.quantity, second.quantity), second.end)
    }

    /// Scans one quantity: a number, a fraction, or a mixed number.
    private static func number(in characters: [Character], from start: Int) -> (quantity: Quantity, end: Int)? {
        guard let leading = decimal(in: characters, from: start) else {
            // A character stating a fraction is a quantity of its own, standing where a digit
            // would otherwise have to.
            guard let standalone = fraction(in: characters, from: start) else { return nil }

            return (
                Quantity(value: standalone.value, text: String(characters[start..<standalone.end])),
                standalone.end
            )
        }

        var end = leading.end
        var value = leading.value
        // The mixed form follows a whole number, so a decimal one never opens one.
        let isWhole = !characters[start..<end].contains(decimalPoint)

        if let bare = denominator(in: characters, from: end) {
            // A bare fraction, whose numerator is the number just scanned.
            value /= bare.value
            end = bare.end
        } else if isWhole, let mixed = mixedFraction(in: characters, from: end) {
            // A mixed number: a whole number, whitespace, then a fraction.
            value += mixed.value
            end = mixed.end
        }

        return (Quantity(value: value, text: String(characters[start..<end])), end)
    }

    /// Scans the fraction a mixed number states after its whole number: the whitespace
    /// separating the two, which belongs to neither, and then the fraction itself.
    private static func mixedFraction(in characters: [Character], from start: Int) -> (value: Double, end: Int)? {
        // A character stating a fraction runs into no digit of the number before it, so it
        // needs nothing to separate the two.
        if let single = vulgarFraction(in: characters, at: start) { return (single, start + 1) }

        let afterSeparator = SourceText.run(in: characters, from: start, while: \.isWhitespace)
        guard afterSeparator > start else { return nil }

        return fraction(in: characters, from: afterSeparator)
    }

    /// Scans a fraction, a character stating one or a `/` between two numbers, returning its
    /// value and the index just past it.
    private static func fraction(in characters: [Character], from start: Int) -> (value: Double, end: Int)? {
        if let single = vulgarFraction(in: characters, at: start) { return (single, start + 1) }

        guard let numerator = decimal(in: characters, from: start),
              let denominator = denominator(in: characters, from: numerator.end)
        else { return nil }

        return (numerator.value / denominator.value, denominator.end)
    }

    /// The value a single character states as a fraction, or `nil` for a character stating
    /// none.
    ///
    /// A character states a fraction where Unicode gives it a numeric value that is not whole,
    /// which is what tells the fractions apart from the digits, the superscripts, and the
    /// numerals, each of which states a whole value.
    private static func vulgarFraction(in characters: [Character], at index: Int) -> Double? {
        guard let character = SourceText.character(in: characters, at: index),
              character.unicodeScalars.count == 1,
              let value = character.unicodeScalars.first?.properties.numericValue,
              value != value.rounded()
        else { return nil }

        return value
    }

    /// Scans a `/` and the number after it, whose value must be non-zero, so a fraction is
    /// never divided by zero.
    private static func denominator(in characters: [Character], from start: Int) -> (value: Double, end: Int)? {
        guard start < characters.count,
              characters[start] == fractionSeparator,
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
