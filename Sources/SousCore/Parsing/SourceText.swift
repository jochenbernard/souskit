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
        String(withoutTrailingWhitespace(text).drop(while: \.isWhitespace))
    }

    static func trimmed(_ text: String) -> String {
        trimmed(text[...])
    }

    static func isDigit(_ character: Character) -> Bool {
        character.isASCII && character.isNumber
    }

    /// Whether a backslash before the character produces that character literally. The
    /// backslash is itself escapable, so a literal one can sit directly before a sigil.
    ///
    /// Reading and writing share this one set, so an escape a reader resolves is an escape
    /// a writer produces.
    static func isEscapable(_ character: Character) -> Bool {
        escapable.contains(character)
    }

    private static let escapable: Set<Character> = ["@", "#", "~", ">", "{", "\\"]

    /// Whether a backslash before the character produces that character literally inside an
    /// inline list value. A list's structure is its brackets and its separating comma rather
    /// than the body's sigils, so it escapes its own set.
    static func isEscapableInList(_ character: Character) -> Bool {
        listEscapable.contains(character)
    }

    private static let listEscapable: Set<Character> = [",", "[", "]", "\\"]
}
