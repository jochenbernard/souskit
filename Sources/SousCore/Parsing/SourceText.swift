// Shared, Foundation-free helpers for looking at raw Sous source text.

enum SourceText {
    /// A leading byte-order mark is ignored, so a header still counts as starting the file.
    static func withoutByteOrderMark(_ text: String) -> String {
        text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text
    }

    /// Splits on any newline, so a CRLF file reads the same as an LF one. Swift treats
    /// "\r\n" as a single character, which a plain "\n" separator would never match.
    static func lines(of text: String) -> [Substring] {
        text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
    }

    static func isBlank(_ line: Substring) -> Bool {
        line.allSatisfy(\.isWhitespace)
    }

    /// A fence line is exactly three hyphens, optionally followed by trailing whitespace.
    static func isFence(_ line: Substring) -> Bool {
        withoutTrailingWhitespace(line) == "---"
    }

    static func withoutTrailingWhitespace(_ text: Substring) -> Substring {
        var end = text.endIndex
        while end > text.startIndex {
            let previous = text.index(before: end)
            guard text[previous].isWhitespace else { break }
            end = previous
        }
        return text[text.startIndex..<end]
    }

    static func trimmed(_ text: Substring) -> String {
        let withoutTrailing = withoutTrailingWhitespace(text)
        var start = withoutTrailing.startIndex
        while start < withoutTrailing.endIndex, withoutTrailing[start].isWhitespace {
            start = withoutTrailing.index(after: start)
        }
        return String(withoutTrailing[start..<withoutTrailing.endIndex])
    }

    static func isDigit(_ character: Character) -> Bool {
        character.isASCII && character.isNumber
    }
}
