/// Reads one paragraph into a step of prose and annotation segments.
enum StepParser {
    /// The result of scanning a span.
    ///
    /// A span that is not well-formed becomes literal text carrying the warning it earned, so
    /// every diagnostic a paragraph produces is appended in one place.
    private enum Span {
        case literal(String, next: Int, warnings: [Diagnostic] = [])
        case named(name: String, amount: Amount?, next: Int, warnings: [Diagnostic] = [])
    }

    /// Finds the brace an amount fence closes on, remembering the region already searched.
    ///
    /// Memoized: a line holding no closing brace would otherwise have every fence on it scan to
    /// the line end, which is quadratic. A search starting outside the remembered region starts
    /// over, so the answer never depends on the order the questions arrive in.
    private struct FenceSearch {
        private var searchedFrom = 0
        private var searchedTo = 0

        mutating func closingBrace(in characters: [Character], from start: Int) -> Int? {
            let from: Int
            if start >= searchedFrom, start <= searchedTo {
                from = searchedTo
            } else {
                from = start
                searchedFrom = start
            }

            let cursor = StepParser.firstUnescaped(AmountFence.closing, in: characters, from: from)
            searchedTo = cursor

            return cursor < characters.count && characters[cursor] == AmountFence.closing ? cursor : nil
        }
    }

    /// Where a paragraph sits in the source, so offsets within it can be reported.
    struct Origin {
        /// The paragraph's offset from the start of the source.
        let start: Int
        let map: SourceMap

        /// The range covering a length of characters at an offset within the paragraph.
        func range(offset: Int, length: Int) -> SourceRange {
            map.range(fromOffset: start + offset, length: length)
        }
    }

    /// The step a paragraph describes. An unclosed span, or an amount fence with no closing
    /// brace, is recovered as literal text with a warning, so the paragraph still reads.
    static func parse(_ text: String, origin: Origin, diagnostics: inout [Diagnostic]) -> Step {
        let characters = Array(text)
        var segments: [Segment] = []
        var prose = ""
        var cursor = 0
        // One search serves the whole paragraph, so no two fences scan the same text.
        var fences = FenceSearch()

        while cursor < characters.count {
            let character = characters[cursor]

            if opensEscape(characters, at: cursor) {
                prose.append(characters[cursor + 1])
                cursor += 2
                continue
            }

            if let annotation = Annotation(rawValue: character), opensSpan(characters, at: cursor) {
                switch scanSpan(characters, from: cursor, as: annotation, fences: &fences, origin: origin) {
                case let .literal(literal, next, warnings):
                    diagnostics.append(contentsOf: warnings)
                    prose += literal
                    cursor = next
                case let .named(name, amount, next, warnings):
                    diagnostics.append(contentsOf: warnings)
                    flush(&prose, into: &segments)
                    cursor = next
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

    /// The segment a well-formed span becomes. Only annotations that take them receive an amount
    /// and flags.
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
        case .reference: .reference(Reference(target: name, amount: amount, flags: flags))
        }
    }

    /// Appends the accumulated prose as a segment and clears it.
    private static func flush(_ prose: inout String, into segments: inout [Segment]) {
        guard !prose.isEmpty else { return }
        segments.append(.text(prose))
        prose = ""
    }

    /// Whether a sigil at this index opens a span.
    private static func opensSpan(_ characters: [Character], at index: Int) -> Bool {
        Annotation.opensSpan(before: SourceText.character(in: characters, at: index + 1))
    }

    /// Whether an escape begins at this index. A trailing backslash escapes nothing.
    private static func opensEscape(_ characters: [Character], at index: Int) -> Bool {
        characters[index] == SourceText.escape
            && index + 1 < characters.count
            && SourceText.isEscapable(characters[index + 1])
    }

    /// The index of the span's closing sigil, or `nil` when the line holds none.
    private static func closingSigil(_ sigil: Character, in characters: [Character], from start: Int) -> Int? {
        let end = firstUnescaped(sigil, in: characters, from: start)

        return end < characters.count && characters[end] == sigil ? end : nil
    }

    /// The index of the first unescaped occurrence of the character, or the index the line ends
    /// at when it holds none.
    ///
    /// An escape is stepped over whole, so `\@` inside `@...@` stays part of the name. The search
    /// stops at a line break, so a span closes on the line it opens on or not at all.
    private static func firstUnescaped(_ character: Character, in characters: [Character], from start: Int) -> Int {
        var cursor = start

        while cursor < characters.count, !characters[cursor].isNewline {
            if opensEscape(characters, at: cursor) {
                cursor += 2
                continue
            }
            if characters[cursor] == character { return cursor }
            cursor += 1
        }

        return cursor
    }

    /// Scans one annotation span opening at `start`.
    ///
    /// A span naming nothing is recovered as literal text rather than becoming an unnamed
    /// annotation. Discarding an amount along with it is warned about.
    private static func scanSpan(
        _ characters: [Character],
        from start: Int,
        as annotation: Annotation,
        fences: inout FenceSearch,
        origin: Origin
    ) -> Span {
        let sigil = annotation.sigil
        let contentStart = start + 1
        var nameStart = contentStart
        var amount: Amount?
        var warnings: [Diagnostic] = []

        // Every sigil is inert between the braces, so the fence is read before the closing sigil
        // is looked for.
        if annotation.allowsAmount, characters[contentStart] == AmountFence.opening {
            guard let closingBrace = fences.closingBrace(in: characters, from: contentStart + 1) else {
                return degradedFence(characters, from: start, as: annotation, origin: origin)
            }

            let fence = SourceText.unescaped(
                characters[(contentStart + 1)..<closingBrace],
                escaping: SourceText.isEscapable
            )
            amount = AmountParser.parse(fence)

            if let defect = AmountParser.defect(in: fence) {
                warnings.append(.warning(
                    .malformedQuantity,
                    defect.message,
                    at: origin.range(offset: contentStart, length: closingBrace - contentStart + 1)
                ))
            }

            nameStart = closingBrace + 1
        }

        guard let closingSigil = closingSigil(sigil, in: characters, from: nameStart) else {
            let unclosed = Diagnostic.warning(
                .unclosedSpan,
                "\(annotation.noun) span is missing a closing sigil.",
                at: origin.range(offset: start, length: 1)
            )

            return .literal(String(characters[start]), next: start + 1, warnings: [unclosed])
        }

        let name = SourceText.trimmed(
            SourceText.unescaped(characters[nameStart..<closingSigil], escaping: SourceText.isEscapable)
        )

        guard !name.isEmpty else {
            if amount != nil {
                warnings.append(.warning(
                    .unnamedAnnotation,
                    "\(annotation.noun) span has an amount but no name.",
                    at: origin.range(offset: start, length: closingSigil - start + 1)
                ))
            }

            return .literal(
                String(characters[start...closingSigil]),
                next: closingSigil + 1,
                warnings: warnings
            )
        }

        return .named(name: name, amount: amount, next: closingSigil + 1, warnings: warnings)
    }

    /// Recovers a span whose amount fence never closes.
    ///
    /// The span becomes literal text bounded by its closing sigil when it has one, and by the
    /// opening sigil alone when it has none.
    private static func degradedFence(
        _ characters: [Character],
        from start: Int,
        as annotation: Annotation,
        origin: Origin
    ) -> Span {
        let end = closingSigil(annotation.sigil, in: characters, from: start + 1) ?? start

        let unclosed = Diagnostic.warning(
            .unclosedSpan,
            "Amount fence is missing a closing brace.",
            at: origin.range(offset: start, length: end - start + 1)
        )

        return .literal(String(characters[start...end]), next: end + 1, warnings: [unclosed])
    }
}
