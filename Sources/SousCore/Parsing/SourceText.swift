// Shared, Foundation-free helpers for looking at raw Sous source text.

enum SourceText {
    /// The mark a UTF-8 file may open with. Reading and writing share it, so a mark a reader
    /// takes for the file's own is one a writer keeps out of that position.
    static let byteOrderMark = "\u{FEFF}"

    /// A leading byte-order mark is ignored, so a header still counts as starting the file.
    /// One anywhere else is ordinary text.
    static func withoutByteOrderMark(_ text: String) -> String {
        text.hasPrefix(byteOrderMark) ? String(text.dropFirst()) : text
    }

    /// Splits on any newline, so a CRLF file reads the same as an LF one. Swift treats
    /// "\r\n" as a single character, which a plain "\n" separator would never match.
    static func lines(of text: String) -> [Substring] {
        text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
    }

    static func isBlank(_ line: Substring) -> Bool {
        line.allSatisfy(\.isWhitespace)
    }

    /// The line that opens and closes a metadata header. Reading and writing share it, so
    /// a fence a reader recognizes is a fence a writer produces.
    static let fence = "---"

    /// A fence line is exactly three hyphens, optionally followed by trailing whitespace.
    static func isFence(_ line: Substring) -> Bool {
        withoutTrailingWhitespace(line) == fence
    }

    private static func withoutTrailingWhitespace(_ text: Substring) -> Substring {
        guard let last = text.lastIndex(where: { !$0.isWhitespace }) else { return text.prefix(0) }

        return text[...last]
    }

    static func trimmed(_ text: String) -> String {
        String(withoutTrailingWhitespace(text[...]).drop(while: \.isWhitespace))
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

    /// A reader escapes exactly the characters it gives a meaning to: the sigils it opens a
    /// span on, the brace that opens an amount fence, the two that open a flag, and the
    /// backslash itself. A sigil a later version introduces is none of them, so a backslash
    /// before one is ordinary text and is kept, which is what carries the escape through to
    /// the reader that does give that sigil a meaning.
    private static let escapable: Set<Character> = Set(Annotation.allCases.map(\.sigil))
        .union([Flag.separator, Flag.shorthand, AmountFence.opening, "\\"])

    /// Whether a backslash before the character produces that character literally inside an
    /// inline list value. A list's structure is its brackets and its separating comma rather
    /// than the body's sigils, so it escapes its own set.
    static func isEscapableInList(_ character: Character) -> Bool {
        listEscapable.contains(character)
    }

    private static let listEscapable: Set<Character> = [",", "[", "]", "\\"]

    /// Resolves each escape to the literal character it produces, dropping the backslash.
    /// A backslash before a character the context does not escape, or before nothing at
    /// all, is ordinary text and is kept.
    ///
    /// The body and an inline list escape different sets, so each passes its own.
    static func unescaped(
        _ characters: some Sequence<Character>,
        escaping isEscapable: (Character) -> Bool
    ) -> String {
        var result = ""
        var escaping = false

        for character in characters {
            if escaping {
                if !isEscapable(character) { result.append("\\") }
                escaping = false
            } else if character == "\\" {
                escaping = true
                continue
            }
            result.append(character)
        }

        if escaping { result.append("\\") }

        return result
    }
}
