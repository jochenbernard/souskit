/// Reads the content of a timer span into its components.
enum TimerParser {
    /// The timer a span's content describes.
    static func parse(_ content: String) -> Timer {
        Timer(components: components(in: Array(content)), text: content)
    }

    /// The amounts the content is written as, such as `1 h` and `30 min` for `1 h 30 min`.
    ///
    /// Content opening with no usable number, such as `until golden`, is one imprecise amount.
    private static func components(in characters: [Character]) -> [Amount] {
        var components: [Amount] = []
        var start = 0

        while start < characters.count, let quantity = AmountParser.quantity(in: characters, from: start) {
            let end = partEnd(in: characters, from: quantity.end)
            components.append(AmountParser.parse(unfenced: String(characters[start..<end])))
            start = end + 1
        }

        guard components.isEmpty, !characters.isEmpty else { return components }

        return [AmountParser.parse(unfenced: String(characters))]
    }

    /// The index where a component ends: the whitespace before the next digit, or the end.
    private static func partEnd(in characters: [Character], from start: Int) -> Int {
        var cursor = start

        while cursor < characters.count {
            if
                characters[cursor].isWhitespace,
                cursor + 1 < characters.count,
                SourceText.isDigit(characters[cursor + 1])
            {
                return cursor
            }

            cursor += 1
        }

        return characters.count
    }
}
