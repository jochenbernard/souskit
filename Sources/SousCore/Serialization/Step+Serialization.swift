// Renders one step back to source text, escaping exactly what the reader would otherwise
// read as something other than the text it stands for.
//
// The sigils and the opener rule come from the shared annotation table, so the writer
// never restates a rule the reader owns.

extension Step {
    var rendered: String {
        var result = ""

        for index in segments.indices {
            switch segments[index] {
            case let .text(text):
                // A run of prose is one segment, so whatever follows it opens with a sigil.
                // Escaping ahead of anything else would be harmless, so the test stays simple.
                result += Self.escapedProse(
                    text,
                    afterFlags: index > 0 && segments[index - 1].annotation?.allowsFlags == true,
                    beforeAnnotation: index + 1 < segments.count
                )
            case let .ingredient(ingredient):
                result += Self.rendered(ingredient)
            case let .cookware(cookware):
                result += Self.rendered(cookware.name, as: .cookware)
            case let .timer(timer):
                result += Self.rendered(timer.text, as: .timer)
            }
        }

        return result
    }

    /// The span an annotation that carries its content alone is written as.
    private static func rendered(_ content: String, as annotation: Annotation) -> String {
        annotation.span(around: escapedName(content, in: annotation))
    }

    private static func rendered(_ ingredient: Ingredient) -> String {
        let content: String

        if let amount = ingredient.amount {
            // The fence and the name are separated by a space, so a leading brace in the name
            // cannot open a second fence and needs no escape.
            let name = escapedName(ingredient.name, in: .ingredient, afterAmount: true)
            content = "\(AmountFence.around(amount.text)) \(name)"
        } else {
            content = escapedName(ingredient.name, in: .ingredient)
        }

        return Annotation.ingredient.span(around: content) + rendered(ingredient.flags)
    }

    /// Writes the flag chain in one canonical order: the named flags, then the unrecognized
    /// ones as they were written, and last of all the optional shorthand.
    ///
    /// The shorthand comes last because a flag word runs on through the letters after it, so
    /// a named flag written directly before prose that starts with one would read back as a
    /// single unrecognized flag. The shorthand is one character and cannot be run into.
    private static func rendered(_ flags: Flags) -> String {
        var result = ""

        // The shorthand stands for `:optional`, so that one flag is left to the end rather
        // than written as its word here.
        for flag in Flag.allCases where flag != .optional && flags[keyPath: flag.property] {
            result += flag.written
        }
        for word in flags.unrecognized {
            result += Flag.written(word)
        }
        if flags.isOptional { result.append(Flag.shorthand) }

        return result
    }

    /// Escapes each occurrence of the span's own closing sigil in a name, a backslash that
    /// would otherwise escape what follows it, and a leading brace where it could otherwise
    /// open an amount fence, so the name re-reads verbatim.
    private static func escapedName(_ name: String, in annotation: Annotation, afterAmount: Bool = false) -> String {
        let characters = Array(name)
        let escapesLeadingBrace = annotation.allowsAmount && !afterAmount
        var result = ""

        for index in characters.indices {
            let character = characters[index]
            // The closing sigil follows the last character, and a sigil is escapable, so a
            // name ending in a backslash escapes it.
            let following = index + 1 < characters.count ? characters[index + 1] : annotation.sigil
            let escaped = character == annotation.sigil
                || (character == "\\" && SourceText.isEscapable(following))
                || (escapesLeadingBrace && index == 0 && character == AmountFence.opening)

            if escaped { result.append("\\") }
            result.append(character)
        }

        return result
    }

    /// Escapes a prose character that would otherwise be read as something else: a sigil that
    /// would open a span, a character that would open a flag where a chain may follow, or a
    /// backslash that would escape the character after it.
    ///
    /// Whether a character needs an escape depends on whether the one after it gets one, so
    /// the run is decided from its end backwards.
    private static func escapedProse(_ text: String, afterFlags: Bool, beforeAnnotation: Bool) -> String {
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

        // A flag chain reads on from the closing sigil, so only the character right after one
        // can open a flag, and only there does prose need the escape.
        if afterFlags, let first = characters.first {
            escapes[0] = escapes[0]
                || Flag.opens(first, followedBy: characters.count > 1 ? characters[1] : nil)
        }

        var result = ""
        for (character, escaped) in zip(characters, escapes) {
            if escaped { result.append("\\") }
            result.append(character)
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
        // A backslash escapes whatever follows it, so a literal one is escaped in turn. An
        // annotation opens with a sigil, which is escapable.
        if character == "\\" {
            return following.map(SourceText.isEscapable) ?? beforeAnnotation
        }

        guard Annotation(rawValue: character) != nil else { return false }
        guard let following else { return beforeAnnotation }

        // A sigil opens a span when a non-whitespace character follows it. An adjacent pair
        // of identical sigils is left alone, because the reader closes the span the first one
        // opens on the second one at once and keeps both as text. That holds only while the
        // second stays unescaped: escaping it lets the span reach past it and swallow the
        // text beyond.
        return Annotation.opensSpan(before: following) && (following != character || escaped)
    }
}
