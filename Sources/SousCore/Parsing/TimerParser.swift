// Reads a timer span's content into the numeric parts it states.
//
// A part is a quantity and the unit after it, read exactly as an amount fence is. A new
// part starts only at a whitespace-separated word that begins with a digit, so a digit
// inside a unit stays with that unit. Content with no leading number states no numeric
// value at all: the duration is qualitative and only its text is kept.

enum TimerParser {
    static func parse(_ content: String) -> Timer {
        Timer(components: components(in: Array(content)), text: content)
    }

    private static func components(in characters: [Character]) -> [Amount] {
        var components: [Amount] = []
        var start = 0

        while start < characters.count, let quantity = AmountParser.quantity(in: characters, from: start) {
            let end = partEnd(in: characters, from: quantity.end)
            components.append(AmountParser.parse(SourceText.trimmed(String(characters[start..<end]))))
            // A part ends at the one whitespace before the next part's number, so the next
            // part starts just past it. Any whitespace before that is the unit's own, which
            // trimming the part removes.
            start = end + 1
        }

        return components
    }

    /// The index the part ends at: the unit runs to the end of the content, or to the
    /// whitespace before the number the next part opens with.
    private static func partEnd(in characters: [Character], from start: Int) -> Int {
        var cursor = start

        while cursor < characters.count {
            if characters[cursor].isWhitespace,
               cursor + 1 < characters.count,
               SourceText.isDigit(characters[cursor + 1]) {
                return cursor
            }

            cursor += 1
        }

        return characters.count
    }
}
