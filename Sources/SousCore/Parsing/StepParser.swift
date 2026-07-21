// Scans one paragraph into a step: ordered prose and annotation segments.
//
// A sigil opens a span only when immediately followed by a non-whitespace character. A
// span that is never closed, or an amount fence with no closing brace, degrades to
// literal text with a warning, so the surrounding paragraph still reads.

enum StepParser {
    /// The result of scanning a span: a well-formed annotation, or literal text recovered
    /// from a span that is not well-formed.
    private enum Span {
        case literal(String, next: Int)
        case named(name: String, amount: Amount?, next: Int)
    }

    /// Where a paragraph sits in the source, so offsets within it can be reported.
    struct Origin {
        var index: String.Index
        var map: SourceMap

        func range(offset: Int, length: Int) -> SourceRange {
            map.range(from: map.index(index, offsetBy: offset), length: length)
        }
    }

    static func parse(_ text: String, origin: Origin, diagnostics: inout [Diagnostic]) -> Step {
        let characters = Array(text)
        var segments: [Segment] = []
        var prose = ""
        var cursor = 0

        while cursor < characters.count {
            let character = characters[cursor]

            // A backslash produces the literal character, so the escape is resolved and the
            // backslash dropped. Serialization escapes the character again where needed.
            if opensEscape(characters, at: cursor, end: characters.count) {
                prose.append(characters[cursor + 1])
                cursor += 2
                continue
            }

            if let annotation = Annotation(rawValue: character), opensSpan(characters, at: cursor) {
                switch scanSpan(characters, from: cursor, as: annotation, origin: origin, diagnostics: &diagnostics) {
                case let .literal(literal, next):
                    prose += literal
                    cursor = next
                case let .named(name, amount, next):
                    flush(&prose, into: &segments)
                    cursor = next
                    // An ingredient reads the flag chain that follows its closing sigil, so
                    // the cursor moves on past that chain too.
                    let flags = FlagParser.parse(
                        after: annotation,
                        in: characters,
                        from: &cursor,
                        origin: origin,
                        diagnostics: &diagnostics
                    )
                    segments.append(annotated(annotation, name: name, amount: amount, flags: flags))
                }
                continue
            }

            prose.append(character)
            cursor += 1
        }

        flush(&prose, into: &segments)

        return Step(segments: segments, text: text)
    }

    /// The segment a well-formed span stands for. Only the annotations that carry an amount or
    /// flags are given them; the others read their content alone.
    private static func annotated(
        _ annotation: Annotation,
        name: String,
        amount: Amount?,
        flags: Flags
    ) -> Segment {
        switch annotation {
        case .ingredient: .ingredient(Ingredient(name: name, amount: amount, flags: flags))
        case .cookware: .cookware(Cookware(name: name))
        case .timer: .timer(TimerParser.parse(name))
        }
    }

    private static func flush(_ prose: inout String, into segments: inout [Segment]) {
        guard !prose.isEmpty else { return }
        segments.append(.text(prose))
        prose = ""
    }

    private static func opensSpan(_ characters: [Character], at index: Int) -> Bool {
        Annotation.opensSpan(before: index + 1 < characters.count ? characters[index + 1] : nil)
    }

    /// Whether an escape begins at the given index, within the given end. A trailing
    /// backslash escapes nothing, so it is ordinary text.
    private static func opensEscape(_ characters: [Character], at index: Int, end: Int) -> Bool {
        characters[index] == "\\" && index + 1 < end && SourceText.isEscapable(characters[index + 1])
    }

    /// Finds the span's closing sigil, skipping any escape so `\@` inside `@...@` stays
    /// part of the name rather than closing it.
    private static func closingSigil(_ sigil: Character, in characters: [Character], from start: Int) -> Int? {
        var cursor = start
        while cursor < characters.count {
            if opensEscape(characters, at: cursor, end: characters.count) {
                cursor += 2
                continue
            }
            if characters[cursor] == sigil { return cursor }
            cursor += 1
        }
        return nil
    }

    /// Scans one annotation span that opens at `start`. A well-formed span becomes a named
    /// annotation; an unclosed span, or an amount fence with no closing brace, degrades to
    /// literal text with a warning so the surrounding paragraph still reads.
    private static func scanSpan(
        _ characters: [Character],
        from start: Int,
        as annotation: Annotation,
        origin: Origin,
        diagnostics: inout [Diagnostic]
    ) -> Span {
        let sigil = annotation.sigil
        let contentStart = start + 1
        var nameStart = contentStart
        var amount: Amount?

        // Every sigil is inert between the braces, the span's own included, so the fence is
        // read first and the closing sigil is looked for after it.
        if annotation.allowsAmount, characters[contentStart] == AmountFence.opening {
            guard let closingBrace = characters[(contentStart + 1)...].firstIndex(of: AmountFence.closing) else {
                return degradedFence(characters, from: start, as: annotation, origin: origin, diagnostics: &diagnostics)
            }

            amount = AmountParser.parse(String(characters[(contentStart + 1)..<closingBrace]))
            nameStart = closingBrace + 1

            // One space usually separates the fence from the name, but it is optional.
            if nameStart < characters.count, characters[nameStart] == " " { nameStart += 1 }
        }

        guard let closingSigil = closingSigil(sigil, in: characters, from: nameStart) else {
            diagnostics.append(.warning(
                .unclosedSpan,
                "\(annotation.noun) span is missing a closing sigil.",
                at: origin.range(offset: start, length: 1)
            ))

            return .literal(String(characters[start]), next: start + 1)
        }

        let name = SourceText.unescaped(characters[nameStart..<closingSigil], escaping: SourceText.isEscapable)

        // A span that names nothing is ordinary text, not an annotation of nothing.
        guard !name.isEmpty else {
            return .literal(String(characters[start...closingSigil]), next: closingSigil + 1)
        }

        return .named(name: name, amount: amount, next: closingSigil + 1)
    }

    /// Recovers from an amount fence that never closes, which makes the whole span not
    /// well-formed. The span degrades to literal text, bounded by its closing sigil when it
    /// has one and by the opening sigil alone when it has none.
    private static func degradedFence(
        _ characters: [Character],
        from start: Int,
        as annotation: Annotation,
        origin: Origin,
        diagnostics: inout [Diagnostic]
    ) -> Span {
        let end = closingSigil(annotation.sigil, in: characters, from: start + 1) ?? start

        diagnostics.append(.warning(
            .unclosedSpan,
            "Amount fence is missing a closing brace.",
            at: origin.range(offset: start, length: end - start + 1)
        ))

        return .literal(String(characters[start...end]), next: end + 1)
    }
}
