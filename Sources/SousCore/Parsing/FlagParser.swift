/// Reads the chain of flags following an annotation's closing sigil.
enum FlagParser {
    /// The flags a chain sets, moving the cursor past it. An unrecognized flag is recorded, and a
    /// flag repeated in one chain is recorded once.
    static func parse(
        after annotation: Annotation,
        in characters: [Character],
        from cursor: inout Int
    ) -> Flags {
        var flags = Flags.empty
        guard annotation.allowsFlags else { return flags }

        while cursor < characters.count,
              Flag.opens(characters[cursor], followedBy: SourceText.character(in: characters, at: cursor + 1)) {
            if let flag = Flag(shorthand: characters[cursor]) {
                flags[keyPath: flag.property] = true
                cursor += 1
                continue
            }

            let end = wordEnd(in: characters, from: cursor + 1)
            let word = String(characters[(cursor + 1)..<end])

            if let flag = Flag(rawValue: word) {
                flags[keyPath: flag.property] = true
            } else if !flags.unrecognized.contains(word) {
                flags.unrecognized.append(word)
            }

            cursor = end
        }

        return flags
    }

    /// The index after the flag word beginning at the given index.
    private static func wordEnd(in characters: [Character], from start: Int) -> Int {
        SourceText.run(
            in: characters,
            from: start,
            while: Flag.continuesWord
        )
    }
}
