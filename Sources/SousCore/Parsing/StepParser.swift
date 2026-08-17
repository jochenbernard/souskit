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

    /// What reading the amount fence at the front of a span produced.
    private struct Fence {
        /// The amount the fence declares, or `nil` when the span opens with none.
        let amount: Amount?

        /// The index the name begins at, past the fence when the span opens with one.
        let nameStart: Int

        /// The warnings reading the fence produced.
        let warnings: [Diagnostic]
    }

    /// The step a paragraph describes. An unclosed span, or an amount fence with no closing
    /// brace, is recovered as literal text with a warning, so the paragraph still reads.
    static func parse(
        _ text: String,
        origin: Origin,
        diagnostics: inout [Diagnostic]
    ) -> Step {
        let characters = Array(text)
        var segments: [Segment] = []
        var prose = ""
        var cursor = 0
        // One search serves the whole paragraph, so no two fences scan the same text.
        var fences = FenceSearch()

        while cursor < characters.count {
            let character = characters[cursor]

            if SourceText.opensEscape(in: characters, at: cursor) {
                prose.append(characters[cursor + 1])
                cursor += 2
                continue
            }

            if let annotation = Annotation(rawValue: character), opensSpan(characters, at: cursor) {
                switch scanSpan(
                    characters,
                    from: cursor,
                    as: annotation,
                    fences: &fences,
                    origin: origin
                ) {
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
                        from: &cursor
                    )
                    segments.append(annotated(
                        annotation,
                        name: name,
                        amount: amount,
                        flags: flags
                    ))
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
        case .ingredient: .ingredient(Ingredient(
            name: name,
            amount: amount,
            flags: flags
        ))
        case .cookware: .cookware(Cookware(name: name))
        case .timer: .timer(TimerParser.parse(name))
        case .reference: .reference(Reference(
            target: name,
            amount: amount,
            flags: flags
        ))
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

    /// Scans one annotation span opening at `start`.
    private static func scanSpan(
        _ characters: [Character],
        from start: Int,
        as annotation: Annotation,
        fences: inout FenceSearch,
        origin: Origin
    ) -> Span {
        guard
            let fence = scanFence(
                characters,
                from: start + 1,
                as: annotation,
                fences: &fences,
                origin: origin
            )
        else {
            return degradedFence(
                characters,
                from: start,
                as: annotation,
                origin: origin
            )
        }

        guard
            let closing = closingSigil(
                annotation.sigil,
                in: characters,
                from: fence.nameStart
            )
        else {
            let unclosed = Diagnostic(
                .unclosedSpan,
                "\(annotation.noun) span is missing a closing sigil.",
                at: origin.range(offset: start, length: 1)
            )

            return .literal(
                String(characters[start]),
                next: start + 1,
                warnings: [unclosed]
            )
        }

        return span(
            characters,
            in: start...closing,
            fence: fence,
            as: annotation,
            origin: origin
        )
    }

    /// The fence a span opens with, or `nil` when the fence never closes.
    ///
    /// Every sigil is inert between the braces, so the fence is read before the closing sigil is
    /// looked for.
    private static func scanFence(
        _ characters: [Character],
        from contentStart: Int,
        as annotation: Annotation,
        fences: inout FenceSearch,
        origin: Origin
    ) -> Fence? {
        guard annotation.allowsAmount, characters[contentStart] == AmountFence.opening else {
            return Fence(
                amount: nil,
                nameStart: contentStart,
                warnings: []
            )
        }

        guard let closingBrace = fences.closingBrace(in: characters, from: contentStart + 1) else {
            return nil
        }

        let text = SourceText.unescaped(
            characters[(contentStart + 1)..<closingBrace],
            escaping: SourceText.isEscapable
        )
        var warnings: [Diagnostic] = []

        if let defect = AmountParser.defect(in: text) {
            warnings.append(Diagnostic(
                .malformedQuantity,
                defect.message,
                at: origin.range(offset: contentStart, length: closingBrace - contentStart + 1)
            ))
        }

        return Fence(
            amount: AmountParser.parse(text),
            nameStart: closingBrace + 1,
            warnings: warnings
        )
    }

    /// The span a closed pair of sigils encloses.
    ///
    /// A span naming nothing is recovered as literal text rather than becoming an unnamed
    /// annotation. Discarding an amount along with it is warned about.
    private static func span(
        _ characters: [Character],
        in bounds: ClosedRange<Int>,
        fence: Fence,
        as annotation: Annotation,
        origin: Origin
    ) -> Span {
        let name = SourceText.trimmed(
            SourceText.unescaped(characters[fence.nameStart..<bounds.upperBound], escaping: SourceText.isEscapable)
        )

        guard !name.isEmpty else {
            var warnings = fence.warnings
            if fence.amount != nil {
                warnings.append(Diagnostic(
                    .unnamedAnnotation,
                    "\(annotation.noun) span has an amount but no name.",
                    at: origin.range(offset: bounds.lowerBound, length: bounds.count)
                ))
            }

            return .literal(
                String(characters[bounds]),
                next: bounds.upperBound + 1,
                warnings: warnings
            )
        }

        return .named(
            name: name,
            amount: fence.amount,
            next: bounds.upperBound + 1,
            warnings: fence.warnings
        )
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
        let end = closingSigil(
            annotation.sigil,
            in: characters,
            from: start + 1
        ) ?? start

        let unclosed = Diagnostic(
            .unclosedSpan,
            "Amount fence is missing a closing brace.",
            at: origin.range(offset: start, length: end - start + 1)
        )

        return .literal(
            String(characters[start...end]),
            next: end + 1,
            warnings: [unclosed]
        )
    }

    /// The index of the span's closing sigil, or `nil` when the line holds none.
    private static func closingSigil(
        _ sigil: Character,
        in characters: [Character],
        from start: Int
    ) -> Int? {
        let end = SourceText.firstUnescaped(
            sigil,
            in: characters,
            from: start
        )

        return end < characters.count && characters[end] == sigil ? end : nil
    }
}
