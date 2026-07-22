// Renders one step back to source text, escaping exactly what the reader would otherwise
// read as something other than the text it stands for.
//
// The sigils and the opener rule come from the shared annotation table, so the writer
// never restates a rule the reader owns.

extension Step {
    var rendered: String {
        Self.rendered(segments)
    }

    /// Segments render on their own, so a step can be built already stating the text it now
    /// holds rather than being given a placeholder and corrected.
    static func rendered(_ segments: [Segment]) -> String {
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
                result += Self.rendered(
                    ingredient.name,
                    as: .ingredient,
                    amount: ingredient.amount,
                    flags: ingredient.flags
                )
            case let .cookware(cookware):
                result += Self.rendered(cookware.name, as: .cookware)
            case let .timer(timer):
                result += Self.rendered(timer.text, as: .timer)
            }
        }

        return result
    }

    /// The span an annotation is written as: its fence, when it carries an amount, then its
    /// escaped name, then the chain of flags attached to it.
    ///
    /// One composition serves every annotation, so what an annotation may carry is asked of
    /// the shared table rather than stated again per kind. An annotation that carries neither
    /// an amount nor a flag passes neither.
    private static func rendered(
        _ name: String,
        as annotation: Annotation,
        amount: Amount? = nil,
        flags: Flags = .empty
    ) -> String {
        // The fence and the name are separated by a space, so a leading brace in the name
        // cannot open a second fence and needs no escape.
        var content = escapedName(name, in: annotation, afterAmount: amount != nil)
        if let amount {
            content = "\(AmountFence.around(amount.text)) \(content)"
        }

        return annotation.span(around: content) + rendered(flags)
    }

    /// Writes the flag chain in one canonical order: the named flags, then the unrecognized
    /// ones as they were written, and last of all the optional shorthand.
    ///
    /// The shorthand comes last because a flag word runs on through the letters after it, so
    /// a named flag written directly before prose that starts with one would read back as a
    /// single unrecognized flag. The shorthand is one character and cannot be run into.
    private static func rendered(_ flags: Flags) -> String {
        var result = ""

        for flag in Flag.allCases where flag != .shorthanded && flags[keyPath: flag.property] {
            result += Flag.written(flag.rawValue)
        }
        for word in flags.unrecognized {
            result += Flag.written(word)
        }
        if flags[keyPath: Flag.shorthanded.property] { result.append(Flag.shorthand) }

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
            let following = SourceText.character(in: characters, at: index + 1) ?? annotation.sigil
            let escaped = character == annotation.sigil
                || (character == SourceText.escape && SourceText.isEscapable(following))
                || (escapesLeadingBrace && index == 0 && character == AmountFence.opening)

            if escaped { result.append(SourceText.escape) }
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
            escapes[index] = needsEscape(
                characters[index],
                followedBy: SourceText.character(in: characters, at: index + 1),
                escaped: index + 1 < characters.count && escapes[index + 1],
                beforeAnnotation: beforeAnnotation
            )
        }

        // A flag chain reads on from the closing sigil, so only the character right after one
        // can open a flag, and only there does prose need the escape.
        if afterFlags, let first = characters.first {
            escapes[0] = escapes[0]
                || Flag.opens(first, followedBy: SourceText.character(in: characters, at: 1))
        }

        var result = ""
        for (character, escaped) in zip(characters, escapes) {
            if escaped { result.append(SourceText.escape) }
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
        if character == SourceText.escape {
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
