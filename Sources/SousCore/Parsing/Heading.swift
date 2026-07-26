/// The `## Name` line introducing a group.
enum Heading {
    /// The characters opening a heading.
    static let marker = "##"

    /// The single space written between the marker and the name.
    static let separator: Character = " "

    /// Whether a line opens a heading.
    ///
    /// Pass `continuedByContent` when more will be written to the same line. Serializing tests a
    /// partial line, where the name may not be written yet; reading tests a whole line, where a
    /// marker with no name is a step.
    static func opens(_ line: some Collection<Character>, continuedByContent: Bool) -> Bool {
        let separated = line.dropFirst(marker.count)
        guard line.starts(with: marker), separated.first?.isWhitespace == true else { return false }

        return continuedByContent || separated.contains(where: { !$0.isWhitespace })
    }

    /// The name a heading line carries, or `nil` when the line opens no heading.
    static func name(of line: some Collection<Character>) -> String? {
        guard opens(line, continuedByContent: false) else { return nil }

        return SourceText.trimmed(
            SourceText.unescaped(line.dropFirst(marker.count), escaping: SourceText.isEscapable)
        )
    }

    /// The heading line naming a group, with any backslash that would otherwise escape the next
    /// character doubled, so the name reads back unchanged.
    static func line(naming name: String) -> String {
        let characters = Array(name)
        var result = marker + String(separator)

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
