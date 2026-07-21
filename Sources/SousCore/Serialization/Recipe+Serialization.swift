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

        return blocks.joined(separator: "\n\n")
    }

    private static func rendered(_ metadata: Metadata) -> String {
        var lines = ["---"]

        for entry in metadata.entries {
            switch entry.value {
            case let .scalar(value):
                lines.append("\(entry.key): \(value)")
            case let .list(items):
                lines.append("\(entry.key): [\(items.joined(separator: ", "))]")
            case let .raw(line):
                lines.append(line)
            }
        }

        lines.append("---")

        return lines.joined(separator: "\n")
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

    private static func annotationFollows(_ segments: [Segment], after index: Int) -> Bool {
        let next = index + 1
        guard next < segments.count else { return false }

        switch segments[next] {
        case .ingredient, .cookware:
            return true
        case .text:
            return false
        }
    }

    /// Escapes each occurrence of the span's own closing sigil in a name, and a leading brace
    /// where it could otherwise open an amount fence, so the name re-reads verbatim.
    private static func escapedName(_ name: String, closing sigil: Character, escapeLeadingBrace: Bool) -> String {
        let characters = Array(name)
        var result = ""

        for index in characters.indices {
            let character = characters[index]
            if character == sigil {
                result.append("\\")
            } else if escapeLeadingBrace, index == 0, character == "{" {
                result.append("\\")
            }
            result.append(character)
        }

        return result
    }

    /// Escapes a prose sigil that would otherwise open a span when the text is read back: one
    /// directly before a different non-whitespace character, or before a following annotation.
    /// A sigil pair such as `##` is left alone, because it re-reads as the same ordinary text.
    private static func escapedProse(_ text: String, beforeAnnotation: Bool) -> String {
        let characters = Array(text)
        var result = ""

        for index in characters.indices {
            let character = characters[index]
            if character == "@" || character == "#" {
                let needsEscape: Bool
                if index == characters.count - 1 {
                    needsEscape = beforeAnnotation
                } else {
                    let following = characters[index + 1]
                    needsEscape = !following.isWhitespace && following != character
                }
                if needsEscape { result.append("\\") }
            }
            result.append(character)
        }

        return result
    }
}
