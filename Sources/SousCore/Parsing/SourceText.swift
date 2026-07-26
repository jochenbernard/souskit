/// Character-level helpers shared by the parsers and the serializers.
enum SourceText {
    static let byteOrderMark = "\u{FEFF}"

    /// The text without a leading byte order mark.
    static func withoutByteOrderMark(_ text: String) -> String {
        text.hasPrefix(byteOrderMark) ? String(text.dropFirst()) : text
    }

    /// The lines of the text, splitting on any character Unicode breaks a line on and keeping
    /// empty lines.
    static func lines(of text: String) -> [Substring] {
        text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
    }

    /// Whether the line is empty or holds only whitespace.
    static func isBlank(_ line: Substring) -> Bool {
        line.allSatisfy(\.isWhitespace)
    }

    static let fence = "---"

    /// Whether the line is a header fence, ignoring trailing whitespace.
    static func isFence(_ line: Substring) -> Bool {
        withoutTrailingWhitespace(line) == fence
    }

    private static func withoutTrailingWhitespace(_ text: Substring) -> Substring {
        guard let last = text.lastIndex(where: { !$0.isWhitespace }) else { return text.prefix(0) }

        return text[...last]
    }

    /// The text without leading or trailing whitespace.
    static func trimmed(_ text: String) -> String {
        String(withoutTrailingWhitespace(text[...]).drop(while: \.isWhitespace))
    }

    /// Whether the character is an ASCII digit.
    ///
    /// A quantity is read from ASCII digits only, so digits from other scripts are not numbers
    /// here.
    static func isDigit(_ character: Character) -> Bool {
        character.isASCII && character.isNumber
    }

    /// The character at the index, or `nil` when the index is out of bounds.
    static func character(in characters: [Character], at index: Int) -> Character? {
        characters.indices.contains(index) ? characters[index] : nil
    }

    /// The index after the run of characters satisfying the predicate.
    static func run(
        in characters: [Character],
        from start: Int,
        while predicate: (Character) -> Bool
    ) -> Int {
        var cursor = start
        while cursor < characters.count, predicate(characters[cursor]) { cursor += 1 }

        return cursor
    }

    static let escape: Character = "\\"

    /// Whether a backslash before this character forms an escape.
    static func isEscapable(_ character: Character) -> Bool {
        escapable.contains(character)
    }

    private static let escapable: Set<Character> = Set(Annotation.allCases.map(\.sigil))
        .union([Flag.separator, Flag.shorthand, AmountFence.opening, AmountFence.closing, escape])

    /// Whether the character opens an escape, given the character after it.
    static func escapesFollowing(_ character: Character, before following: Character?) -> Bool {
        character == escape && (following.map(isEscapable) ?? false)
    }

    /// Whether an escape begins at this index. A trailing backslash escapes nothing.
    static func opensEscape(in characters: [Character], at index: Int) -> Bool {
        escapesFollowing(characters[index], before: character(in: characters, at: index + 1))
    }

    /// The index of the first unescaped occurrence of the character, or the index the line ends at
    /// when it holds none.
    ///
    /// An escape is stepped over whole, so `\@` inside `@...@` stays part of the name. The search
    /// stops at a line break, so a span closes on the line it opens on or not at all.
    static func firstUnescaped(
        _ character: Character,
        in characters: [Character],
        from start: Int
    ) -> Int {
        var cursor = start

        while cursor < characters.count, !characters[cursor].isNewline {
            if opensEscape(in: characters, at: cursor) {
                cursor += 2
                continue
            }
            if characters[cursor] == character { return cursor }
            cursor += 1
        }

        return cursor
    }

    /// Whether a backslash before this character forms an escape inside an inline list.
    static func isEscapableInList(_ character: Character) -> Bool {
        listEscapable.contains(character)
    }

    private static let listEscapable: Set<Character> = [",", "[", "]", escape]

    /// The characters with escapes resolved.
    ///
    /// A backslash before a character the predicate rejects is kept, so it stays literal text
    /// rather than disappearing.
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

    /// The characters with a backslash inserted before each one the predicate accepts.
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

    /// Each character paired with whether a backslash escapes it.
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
