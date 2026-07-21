// Reads the chain of flags that may follow an annotation's closing sigil.
//
// A flag is a colon and the flag word after it, or the `?` shorthand for `:optional`. The
// chain ends at the first character that opens neither, so a colon with no flag word after
// it, and any punctuation after a flag, stay in the prose. An unrecognized flag word is
// preserved and warned about, never dropped.

enum FlagParser {
    /// The flags following an annotation's closing sigil. Only some annotations carry them, and
    /// one that does not reads none and leaves the cursor where it stands.
    static func parse(
        after annotation: Annotation,
        in characters: [Character],
        from cursor: inout Int,
        origin: StepParser.Origin,
        diagnostics: inout [Diagnostic]
    ) -> Flags {
        var flags = Flags(isOptional: false, isStaple: false, isNonFood: false, unrecognized: [])
        guard annotation.allowsFlags else { return flags }

        while cursor < characters.count,
              Flag.opens(characters[cursor], followedBy: following(characters, after: cursor)) {
            if characters[cursor] == Flag.shorthand {
                flags.isOptional = true
                cursor += 1
                continue
            }

            // The chain opened on the separator, so a flag word follows it.
            let end = wordEnd(in: characters, from: cursor + 1)
            let word = String(characters[(cursor + 1)..<end])

            if let flag = Flag(rawValue: word) {
                flags[keyPath: flag.property] = true
            } else {
                flags.unrecognized.append(word)
                diagnostics.append(.warning(
                    .unknownFlag,
                    "Unrecognized flag '\(word)'.",
                    at: origin.range(offset: cursor, length: end - cursor)
                ))
            }

            cursor = end
        }

        return flags
    }

    /// The index just past the flag word starting at `start`, which the chain only opens on
    /// when at least one character belongs to that word.
    private static func wordEnd(in characters: [Character], from start: Int) -> Int {
        var cursor = start
        while cursor < characters.count, Flag.continuesWord(characters[cursor]) { cursor += 1 }

        return cursor
    }

    private static func following(_ characters: [Character], after index: Int) -> Character? {
        index + 1 < characters.count ? characters[index + 1] : nil
    }
}
