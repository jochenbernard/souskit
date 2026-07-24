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

    /// The character at the given position, or `nil` when the text holds no such position.
    ///
    /// Every rule that looks at the character after another asks through this one lookup, so
    /// no call site states its own bound and none can be off by one.
    static func character(in characters: [Character], at index: Int) -> Character? {
        characters.indices.contains(index) ? characters[index] : nil
    }

    /// The index just past the run of characters from `start` that satisfy the predicate.
    ///
    /// The run may be empty, so the returned index equals `start` when the character at it
    /// does not satisfy the predicate, or when `start` is already past the end.
    static func run(
        in characters: [Character],
        from start: Int,
        while predicate: (Character) -> Bool
    ) -> Int {
        var cursor = start
        while cursor < characters.count, predicate(characters[cursor]) { cursor += 1 }

        return cursor
    }

    /// The character a backslash escapes with. Reading and writing share it, so the character
    /// a reader drops before a literal is the one a writer puts there.
    static let escape: Character = "\\"

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
        .union([Flag.separator, Flag.shorthand, AmountFence.opening, escape])

    /// Whether the character would escape the one after it, which is what makes a literal
    /// backslash need an escape of its own. Every writer asks through this one rule, so none
    /// of them states where a backslash is bare and where it is not.
    static func escapesFollowing(_ character: Character, before following: Character?) -> Bool {
        character == escape && (following.map(isEscapable) ?? false)
    }

    /// Whether a backslash before the character produces that character literally inside an
    /// inline list value. A list's structure is its brackets and its separating comma rather
    /// than the body's sigils, so it escapes its own set.
    static func isEscapableInList(_ character: Character) -> Bool {
        listEscapable.contains(character)
    }

    private static let listEscapable: Set<Character> = [",", "[", "]", escape]

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
                if !isEscapable(character) { result.append(escape) }
                escaping = false
            } else if character == escape {
                escaping = true
                continue
            }
            result.append(character)
        }

        if escaping { result.append(escape) }

        return result
    }

    /// Inserts an escape before each character the predicate marks, the forward companion of
    /// ``unescaped(_:escaping:)``, so a value written through here reads back verbatim.
    static func escaped(
        _ characters: some Sequence<Character>,
        escaping needsEscape: (Character) -> Bool
    ) -> String {
        var result = ""

        for character in characters {
            if needsEscape(character) { result.append(escape) }
            result.append(character)
        }

        return result
    }

    /// Each character paired with whether an unescaped backslash escapes it.
    ///
    /// A backslash that escapes the character after it is paired like any other, so no
    /// character is dropped; its effect is that the following character is paired with `true`.
    /// A caller tells a separator or a bracket an escape produces apart from one that stands
    /// for itself by reading this flag rather than tracking the escapes itself.
    static func escapeScanned(
        _ characters: some Sequence<Character>
    ) -> [(character: Character, isEscaped: Bool)] {
        var scanned: [(character: Character, isEscaped: Bool)] = []
        var escaping = false

        for character in characters {
            scanned.append((character, escaping))
            escaping = !escaping && character == escape
        }

        return scanned
    }
}
