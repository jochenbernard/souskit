// The line-level construct version 0.4 reads: the heading that opens a step group.
//
// Reading and writing share this one table, so the line a writer opens a group with is the
// line a reader opens one on.

enum Heading {
    /// What a heading line opens with: the two hashes, and the one space that separates them
    /// from the name and belongs to neither.
    static let marker = "## "

    /// Whether the line is shaped as a heading.
    ///
    /// A heading is the marker and a name, so a line stating no name after the marker, and a
    /// line the marker does not open, are ordinary body text. Where the line stands decides
    /// with its shape, because a heading opens a group only where no step line stands directly
    /// before it, and that is the caller's to know.
    ///
    /// A reader holds the whole line and asks with nothing continuing it. A writer is composing
    /// one and knows what it is about to write next, so content ending at the bare marker opens
    /// a heading exactly when something follows it on that line to name.
    ///
    /// - Parameters:
    ///   - line: The line, or the part of it written so far.
    ///   - continuedByContent: Whether more is written on the same line after it.
    /// - Returns: Whether a reader takes the line for a heading.
    static func opens(_ line: some Collection<Character>, continuedByContent: Bool) -> Bool {
        line.starts(with: marker) && (continuedByContent || line.count > marker.count)
    }

    /// The name the line opens a group with, or `nil` when the line is not a heading.
    ///
    /// The name is what follows the marker, with each escape resolved and nothing stripped, so
    /// a second space begins the name.
    static func name(of line: some Collection<Character>) -> String? {
        guard opens(line, continuedByContent: false) else { return nil }

        return SourceText.unescaped(line.dropFirst(marker.count), escaping: SourceText.isEscapable)
    }

    /// The line a group with the given name is written as.
    ///
    /// A heading holds no annotation, so a sigil in a name needs no escape to read back as
    /// itself. Only a backslash that would otherwise escape what follows it does.
    static func line(naming name: String) -> String {
        let characters = Array(name)
        var result = marker

        for index in characters.indices {
            let character = characters[index]
            let following = SourceText.character(in: characters, at: index + 1)

            if SourceText.escapesFollowing(character, before: following) {
                result.append(SourceText.escape)
            }
            result.append(character)
        }

        return result
    }
}
