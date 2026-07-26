/// Reads amount text into a quantity, a range, or an imprecise amount.
enum AmountParser {
    static let rangeSeparator: Character = "-"

    static let unitSeparator: Character = " "

    static let decimalPoint: Character = "."

    static let commaPoint: Character = ","

    static let fractionSeparator: Character = "/"

    /// A way an amount can open as a number and fail to finish one.
    enum Defect {
        /// A decimal point with no digits after it, or a comma used as one.
        case decimalPoint

        /// A fraction whose denominator is missing or zero.
        case fraction

        /// A number opening with a point, comma, or hyphen instead of a digit.
        case leadingCharacter

        /// The warning message for this defect.
        var message: String {
            switch self {
            case .decimalPoint:
                "Amount has a decimal point it cannot use; write a decimal as '.' between digits."
            case .fraction:
                "Amount has a fraction with a missing or zero denominator."
            case .leadingCharacter:
                "Amount opens as a number with no leading digit; write one, as in '0.5'."
            }
        }
    }

    /// The amount a fence's content describes, honoring the `=` marker.
    static func parse(_ fence: String) -> Amount {
        parse(fence, fenced: true)
    }

    /// The defect in the text, or `nil` when it opens as a usable number or as no number at all.
    ///
    /// Text with no leading number is imprecise rather than defective, so it reports nothing.
    /// Pass `fenced` when a leading `=` is a marker rather than part of the text.
    static func defect(in text: String, fenced: Bool = true) -> Defect? {
        let characters = Array(markerRemoved(from: SourceText.trimmed(text), fenced: fenced).text)

        guard let scanned = scannedQuantity(in: characters, from: 0) else {
            return leadingDefect(in: characters, from: 0)
        }

        return defect(in: characters, at: scanned.end)
    }

    /// The defect in text that opens with a point, comma, or hyphen before a digit.
    private static func leadingDefect(in characters: [Character], from start: Int) -> Defect? {
        guard let first = SourceText.character(in: characters, at: start),
              first == decimalPoint || first == commaPoint || first == rangeSeparator,
              let following = SourceText.character(in: characters, at: start + 1),
              SourceText.isDigit(following)
        else { return nil }

        return .leadingCharacter
    }

    /// The defect in the character a scanned number stops at.
    private static func defect(in characters: [Character], at end: Int) -> Defect? {
        switch SourceText.character(in: characters, at: end) {
        case decimalPoint, commaPoint: .decimalPoint
        case fractionSeparator: .fraction
        default: nil
        }
    }

    /// The amount a header value describes, where a leading `=` is ordinary text.
    static func parse(unfenced text: String) -> Amount {
        parse(text, fenced: false)
    }

    /// The text without a leading `=` marker, and whether one was present.
    private static func markerRemoved(from text: String, fenced: Bool) -> (text: String, isFixed: Bool) {
        guard fenced, text.first == AmountFence.fixedMarker else { return (text, false) }

        return (String(text.dropFirst().drop(while: \.isWhitespace)), true)
    }

    /// The amount the text describes. Text opening with no usable number is imprecise.
    private static func parse(_ value: String, fenced: Bool) -> Amount {
        let read = markerRemoved(from: SourceText.trimmed(value), fenced: fenced)
        let text = read.text
        let characters = Array(text)

        guard let quantity = quantity(in: characters, from: 0) else {
            return Amount(
                kind: .imprecise(text),
                unit: nil,
                isFixed: read.isFixed,
                text: text
            )
        }

        let cursor = SourceText.run(
            in: characters,
            from: quantity.end,
            while: \.isWhitespace
        )

        return Amount(
            kind: quantity.kind,
            unit: String(characters[cursor...]),
            isFixed: read.isFixed,
            text: text
        )
    }

    /// The quantity beginning at the index, or `nil` when none is there or it is defective.
    static func quantity(in characters: [Character], from start: Int) -> (kind: Amount.Kind, end: Int)? {
        guard let scanned = scannedQuantity(in: characters, from: start),
              defect(in: characters, at: scanned.end) == nil
        else { return nil }

        return scanned
    }

    /// The quantity beginning at the index, defective or not.
    private static func scannedQuantity(
        in characters: [Character],
        from start: Int
    ) -> (kind: Amount.Kind, end: Int)? {
        guard let first = number(in: characters, from: start) else { return nil }
        guard let second = rangeEnd(in: characters, from: first.end)
        else { return (.precise(first.quantity), first.end) }

        return (.range(first.quantity, second.quantity), second.end)
    }

    /// The high quantity of a range, or `nil` when no separator and number follow.
    ///
    /// Whitespace around the separator belongs to neither side, so `1-2`, `1 - 2`, and `1- 2`
    /// read alike.
    private static func rangeEnd(in characters: [Character], from start: Int) -> (quantity: Quantity, end: Int)? {
        let separator = SourceText.run(
            in: characters,
            from: start,
            while: \.isWhitespace
        )
        guard SourceText.character(in: characters, at: separator) == rangeSeparator else { return nil }

        return number(in: characters, from: SourceText.run(
            in: characters,
            from: separator + 1,
            while: \.isWhitespace
        ))
    }

    /// One number: a decimal, a fraction, or a whole number followed by a fraction.
    private static func number(in characters: [Character], from start: Int) -> (quantity: Quantity, end: Int)? {
        guard let leading = decimal(in: characters, from: start) else {
            guard let standalone = fraction(in: characters, from: start) else { return nil }

            return (
                Quantity(value: standalone.value, text: String(characters[start..<standalone.end])),
                standalone.end
            )
        }

        var end = leading.end
        var value = leading.value
        // Only a whole number takes a mixed fraction, so `1.5 1/2` is a number and a separate part.
        let isWhole = !characters[start..<end].contains(decimalPoint)

        if let bare = denominator(in: characters, from: end) {
            value /= bare.value
            end = bare.end
        } else if isWhole, let mixed = mixedFraction(in: characters, from: end) {
            value += mixed.value
            end = mixed.end
        }

        return (Quantity(value: value, text: String(characters[start..<end])), end)
    }

    /// The fractional part following a whole number, written `1 1/2` or `1` and a vulgar fraction.
    private static func mixedFraction(in characters: [Character], from start: Int) -> (value: Double, end: Int)? {
        if let single = vulgarFraction(in: characters, at: start) { return (single, start + 1) }

        let afterSeparator = SourceText.run(
            in: characters,
            from: start,
            while: \.isWhitespace
        )
        guard afterSeparator > start else { return nil }

        return fraction(in: characters, from: afterSeparator)
    }

    /// A fraction written `1/2`, or a single vulgar fraction character.
    private static func fraction(in characters: [Character], from start: Int) -> (value: Double, end: Int)? {
        if let single = vulgarFraction(in: characters, at: start) { return (single, start + 1) }

        guard let numerator = decimal(in: characters, from: start),
              let denominator = denominator(in: characters, from: numerator.end)
        else { return nil }

        return (numerator.value / denominator.value, denominator.end)
    }

    /// The value of a character such as one-half, or `nil` for any other character.
    ///
    /// A whole-valued numeric character such as a superscript digit is not a fraction.
    private static func vulgarFraction(in characters: [Character], at index: Int) -> Double? {
        guard let character = SourceText.character(in: characters, at: index),
              character.unicodeScalars.count == 1,
              let value = character.unicodeScalars.first?.properties.numericValue,
              value != value.rounded()
        else { return nil }

        return value
    }

    /// The denominator following a `/`, or `nil` when it is missing or zero.
    private static func denominator(in characters: [Character], from start: Int) -> (value: Double, end: Int)? {
        guard start < characters.count,
              characters[start] == fractionSeparator,
              let run = decimal(in: characters, from: start + 1),
              run.value != 0.0
        else { return nil }

        return (run.value, run.end)
    }

    /// A run of digits, optionally followed by a point and more digits.
    private static func decimal(in characters: [Character], from start: Int) -> (value: Double, end: Int)? {
        guard let leading = digits(in: characters, from: start) else { return nil }

        guard leading.end + 1 < characters.count,
              characters[leading.end] == decimalPoint,
              let decimals = digits(in: characters, from: leading.end + 1)
        else { return leading }

        return (Double(String(characters[start..<decimals.end])) ?? leading.value, decimals.end)
    }

    /// A run of ASCII digits, or `nil` when there is none.
    private static func digits(in characters: [Character], from start: Int) -> (value: Double, end: Int)? {
        let end = SourceText.run(
            in: characters,
            from: start,
            while: SourceText.isDigit
        )
        guard end > start else { return nil }

        return (Double(String(characters[start..<end])) ?? 0.0, end)
    }
}
