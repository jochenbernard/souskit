extension Step {
    /// Where the output has reached, so a segment can tell whether it is starting a line.
    ///
    /// A heading is decided by the shape of a whole output line, not by one segment in
    /// isolation, so the text written so far travels with the position.
    private enum Position {
        /// Still on the step's first line, carrying what has been written to it.
        case firstLine([Character])

        /// Past a line break, where no heading can open.
        case insideStep

        /// The position after one more character is written.
        func continued(by character: Character) -> Self {
            guard case let .firstLine(written) = self else { return .insideStep }

            return .firstLine(written + [character])
        }
    }

    /// The step as Sous source text.
    func serialized() -> String {
        Self.serialized(segments)
    }

    /// The segments as Sous source text, escaping whatever would otherwise read back as
    /// something else.
    static func serialized(_ segments: [Segment]) -> String {
        var result = ""

        for index in segments.indices {
            let position = Self.position(after: result)

            switch segments[index] {
            case let .text(text):
                result += Self.renderedProse(
                    text,
                    at: index,
                    in: segments,
                    at: position
                )
            case let .ingredient(ingredient):
                result += Self.renderedSpan(
                    ingredient.name,
                    as: .ingredient,
                    at: position,
                    amount: ingredient.amount,
                    flags: ingredient.flags
                )
            case let .cookware(cookware):
                result += Self.renderedSpan(
                    cookware.name,
                    as: .cookware,
                    at: position
                )
            case let .timer(timer):
                result += Self.renderedSpan(
                    timer.text,
                    as: .timer,
                    at: position
                )
            case let .reference(reference):
                result += Self.renderedSpan(
                    reference.target,
                    as: .reference,
                    at: position,
                    amount: reference.amount,
                    flags: reference.flags
                )
            }
        }

        return result
    }

    /// Renders a prose segment, told whether a flag chain precedes it and an annotation follows.
    private static func renderedProse(
        _ text: String,
        at index: Int,
        in segments: [Segment],
        at position: Position
    ) -> String {
        escapedProse(
            text,
            afterFlags: index > 0 && segments[index - 1].annotation?.allowsFlags == true,
            beforeAnnotation: index + 1 < segments.count,
            at: position
        )
    }

    /// Renders one annotation span, with its fence and flag chain.
    private static func renderedSpan(
        _ name: String,
        as annotation: Annotation,
        at position: Position,
        amount: Amount? = nil,
        flags: Flags = .empty
    ) -> String {
        var content = escapedName(
            name,
            in: annotation,
            afterAmount: amount != nil,
            at: position.continued(by: annotation.sigil)
        )
        if let amount {
            content = "\(AmountFence.around(escapedAmount(amount))) \(content)"
        }

        return annotation.span(around: content) + renderedFlags(flags)
    }

    /// The fence content with its closing brace escaped, so an amount holding one does not close
    /// the fence early.
    private static func escapedAmount(_ amount: Amount) -> String {
        let characters = Array(AmountFence.content(of: amount))
        var result = ""

        for index in characters.indices {
            let character = characters[index]
            let following = SourceText.character(in: characters, at: index + 1)

            if character == AmountFence.closing || SourceText.escapesFollowing(character, before: following) {
                result.append(SourceText.escape)
            }
            result.append(character)
        }

        return result
    }

    /// The flag chain, flags written as words first, then unrecognized ones, then shorthands.
    private static func renderedFlags(_ flags: Flags) -> String {
        let worded = Flag.allCases
            .filter({ $0.shorthand == nil && flags[keyPath: $0.property] })
            .map({ Flag.written($0.rawValue) })
            .joined()
        let unrecognized = flags.unrecognized.map(Flag.written).joined()
        let shorthands = String(Flag.allCases.compactMap({ flags[keyPath: $0.property] ? $0.shorthand : nil }))

        return worded + unrecognized + shorthands
    }

    /// The name with its own sigil escaped, plus a leading brace that would otherwise open a
    /// fence, plus anything that would open a heading.
    private static func escapedName(
        _ name: String,
        in annotation: Annotation,
        afterAmount: Bool,
        at position: Position
    ) -> String {
        let characters = Array(name)
        let escapesLeadingBrace = annotation.allowsAmount && !afterAmount
        var result = ""

        for index in characters.indices {
            let character = characters[index]
            let following = SourceText.character(in: characters, at: index + 1) ?? annotation.sigil
            let escaped = character == annotation.sigil
                || SourceText.escapesFollowing(character, before: following)
                || (escapesLeadingBrace && index == 0 && character == AmountFence.opening)
                || opensHeading(
                    characters,
                    at: index,
                    at: position,
                    followedByContent: true
                )

            if escaped { result.append(SourceText.escape) }
            result.append(character)
        }

        return result
    }

    /// The position reached after writing the given output.
    private static func position(after text: String) -> Position {
        text.contains(where: \.isNewline) ? .insideStep : .firstLine(Array(text))
    }

    /// Whether writing this segment from this index would complete a heading.
    ///
    /// The test joins what is already on the line to what is about to be written, because a
    /// heading can be completed across two segments. Judging a segment alone would let a step
    /// serialize into a heading and be lost.
    private static func opensHeading(
        _ characters: [Character],
        at index: Int,
        at position: Position,
        followedByContent: Bool
    ) -> Bool {
        guard index == 0, case let .firstLine(written) = position else { return false }

        let line = characters.prefix(while: { !$0.isNewline })

        return Heading.opens(
            written + line,
            continuedByContent: followedByContent && line.endIndex == characters.endIndex
        )
    }

    /// Prose with every character escaped that would otherwise open a span, an escape, a flag
    /// chain, or a heading.
    ///
    /// Scanned back to front: whether a sigil opens a span depends on what follows it, including
    /// whether that character is itself escaped.
    private static func escapedProse(
        _ text: String,
        afterFlags: Bool,
        beforeAnnotation: Bool,
        at position: Position
    ) -> String {
        let characters = Array(text)
        var escapes = [Bool](repeating: false, count: characters.count)

        for index in characters.indices.reversed() {
            escapes[index] = needsEscape(
                characters[index],
                followedBy: SourceText.character(in: characters, at: index + 1),
                escaped: index + 1 < characters.count && escapes[index + 1],
                beforeAnnotation: beforeAnnotation
            ) || opensHeading(
                characters,
                at: index,
                at: position,
                followedByContent: beforeAnnotation
            )
        }

        // Prose following a flag chain must not begin with something the chain would swallow.
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

    /// Whether a prose character needs escaping.
    ///
    /// A character at the very end of a segment is judged by whether an annotation follows, since
    /// that annotation's sigil becomes the character after it.
    private static func needsEscape(
        _ character: Character,
        followedBy following: Character?,
        escaped: Bool,
        beforeAnnotation: Bool
    ) -> Bool {
        if character == SourceText.escape {
            guard let following else { return beforeAnnotation }

            return SourceText.escapesFollowing(character, before: following)
        }

        guard Annotation(rawValue: character) != nil else { return false }
        guard let following else { return beforeAnnotation }

        return Annotation.opensSpan(before: following) && (following != character || escaped)
    }
}
