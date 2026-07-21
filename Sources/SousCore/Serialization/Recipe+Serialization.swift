extension Recipe {
    /// Renders the recipe back to Sous source text.
    ///
    /// Content is preserved, while incidental layout such as repeated blank lines is
    /// normalized, so re-reading the result yields the same recipe.
    ///
    /// - Returns: The recipe rendered as Sous source text.
    public func serialized() -> String {
        var blocks: [String] = []

        if !metadata.entries.isEmpty {
            blocks.append(Self.rendered(metadata))
        }

        if !steps.isEmpty {
            blocks.append(steps.map(Self.rendered).joined(separator: "\n\n"))
        }

        let text = blocks.joined(separator: "\n\n")

        // With no header block in front of it, a body that opens with a fence line would read
        // back as a header, so a blank line keeps it in the body where it belongs.
        guard metadata.entries.isEmpty, opensWithFence(text) else { return text }

        return "\n" + text
    }

    private func opensWithFence(_ text: String) -> Bool {
        SourceText.isFence(text.prefix(while: { !$0.isNewline }))
    }

    private static func rendered(_ metadata: Metadata) -> String {
        var lines = ["---"]

        for entry in metadata.entries {
            switch entry.value {
            case let .scalar(value):
                // An empty value ends the line at the separator, where a trailing space
                // would be incidental layout.
                lines.append(value.isEmpty ? "\(entry.key):" : "\(entry.key): \(value)")
            case let .list(items):
                lines.append("\(entry.key): \(rendered(items))")
            case let .raw(line):
                lines.append(line)
            }
        }

        lines.append("---")

        return lines.joined(separator: "\n")
    }

    /// Renders a list value in the inline form, which every item survives because the
    /// characters the list gives a meaning of its own are escaped inside it.
    private static func rendered(_ items: [String]) -> String {
        "[\(items.map(escapedItem).joined(separator: ", "))]"
    }

    /// Escapes each character an inline list reads as its own structure, so an item holding a
    /// separator, a bracket, or a backslash reads back verbatim.
    private static func escapedItem(_ item: String) -> String {
        var result = ""

        for character in item {
            if SourceText.isEscapableInList(character) { result.append("\\") }
            result.append(character)
        }

        return result
    }

    private static func rendered(_ step: Step) -> String {
        var result = ""

        for index in step.segments.indices {
            switch step.segments[index] {
            case let .text(text):
                result += escapedProse(text, beforeAnnotation: annotationFollows(step.segments, after: index))
            case let .ingredient(ingredient):
                result += rendered(ingredient)
            case let .cookware(cookware):
                result += "#\(escapedName(cookware.name, closing: "#", escapeLeadingBrace: false))#"
            }
        }

        return result
    }

    private static func rendered(_ ingredient: Ingredient) -> String {
        guard let amount = ingredient.amount else {
            return "@\(escapedName(ingredient.name, closing: "@", escapeLeadingBrace: true))@"
        }

        // The fence and the name are separated by a space, so a leading brace in the name
        // cannot open a second fence and needs no escape.
        return "@{\(amount.text)} \(escapedName(ingredient.name, closing: "@", escapeLeadingBrace: false))@"
    }

    /// Whether an annotation follows the segment at the given index. A run of prose is one
    /// segment, so whatever follows a run of prose is an annotation.
    private static func annotationFollows(_ segments: [Segment], after index: Int) -> Bool {
        index + 1 < segments.count
    }

    /// Escapes each occurrence of the span's own closing sigil in a name, a backslash that
    /// would otherwise escape what follows it, and a leading brace where it could otherwise
    /// open an amount fence, so the name re-reads verbatim.
    private static func escapedName(_ name: String, closing sigil: Character, escapeLeadingBrace: Bool) -> String {
        let characters = Array(name)
        var result = ""

        for index in characters.indices {
            let character = characters[index]
            // The closing sigil follows the last character, and a sigil is escapable, so a
            // name ending in a backslash escapes it.
            let following = index + 1 < characters.count ? characters[index + 1] : sigil

            if character == sigil {
                result.append("\\")
            } else if character == "\\", SourceText.isEscapable(following) {
                result.append("\\")
            } else if escapeLeadingBrace, index == 0, character == "{" {
                result.append("\\")
            }
            result.append(character)
        }

        return result
    }

    /// Escapes a prose character that would otherwise be read as something else: a sigil that
    /// would open a span, or a backslash that would escape the character after it.
    ///
    /// Whether a character needs an escape depends on whether the one after it gets one, so
    /// the run is decided from its end backwards.
    private static func escapedProse(_ text: String, beforeAnnotation: Bool) -> String {
        let characters = Array(text)
        var escapes = [Bool](repeating: false, count: characters.count)

        for index in characters.indices.reversed() {
            let hasFollowing = index + 1 < characters.count

            escapes[index] = needsEscape(
                characters[index],
                followedBy: hasFollowing ? characters[index + 1] : nil,
                escaped: hasFollowing && escapes[index + 1],
                beforeAnnotation: beforeAnnotation
            )
        }

        var result = ""
        for index in characters.indices {
            if escapes[index] { result.append("\\") }
            result.append(characters[index])
        }

        return result
    }

    /// Whether a prose character needs an escape, given the character that follows it in the
    /// output and whether that character is itself escaped there. The last character of a run
    /// is followed by the annotation's opening sigil, when one follows, and by nothing
    /// otherwise.
    private static func needsEscape(
        _ character: Character,
        followedBy following: Character?,
        escaped: Bool,
        beforeAnnotation: Bool
    ) -> Bool {
        switch character {
        case "\\":
            // A backslash escapes whatever follows it, so a literal one is escaped in turn.
            // An annotation opens with a sigil, which is escapable.
            following.map(SourceText.isEscapable) ?? beforeAnnotation
        case "@", "#":
            // A sigil opens a span when a non-whitespace character follows it. An adjacent
            // pair of identical sigils is left alone, because the reader closes the span the
            // first one opens on the second one at once and keeps both as text. That holds
            // only while the second stays unescaped: escaping it lets the span reach past it
            // and swallow the text beyond.
            following.map({ !$0.isWhitespace && ($0 != character || escaped) }) ?? beforeAnnotation
        default:
            false
        }
    }
}
