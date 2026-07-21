// Scans one paragraph into a step: ordered prose and annotation segments.
//
// A sigil opens a span only when immediately followed by a non-whitespace character. A
// span that is never closed, or an amount fence with no closing brace, degrades to
// literal text with a warning, so the surrounding paragraph still reads.

enum StepParser {
    /// A kind of annotation span, together with the sigil-specific rules that drive it.
    private enum Annotation {
        case ingredient
        case cookware

        /// The annotation opened by the given sigil, or `nil` for an ordinary character.
        init?(_ character: Character) {
            switch character {
            case "@": self = .ingredient
            case "#": self = .cookware
            default: return nil
            }
        }

        /// The sigil that opens and closes the span.
        var sigil: Character {
            switch self {
            case .ingredient: "@"
            case .cookware: "#"
            }
        }

        /// The name used to describe the span in a diagnostic.
        var noun: String {
            switch self {
            case .ingredient: "Ingredient"
            case .cookware: "Cookware"
            }
        }

        /// Whether the span may open with an `{...}` amount fence.
        var allowsAmount: Bool {
            switch self {
            case .ingredient: true
            case .cookware: false
            }
        }
    }

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
            map.range(from: index, offset: offset, length: length)
        }
    }

    private static let escapable: Set<Character> = ["@", "#", "~", ">", "{"]

    static func parse(_ text: String, origin: Origin, diagnostics: inout [Diagnostic]) -> Step {
        let characters = Array(text)
        var segments: [Segment] = []
        var ingredients: [Ingredient] = []
        var cookware: [Cookware] = []
        var prose = ""
        var cursor = 0

        while cursor < characters.count {
            let character = characters[cursor]

            // A backslash produces the literal character, so the escape is resolved and the
            // backslash dropped. Serialization escapes the character again where needed.
            if character == "\\", cursor + 1 < characters.count, escapable.contains(characters[cursor + 1]) {
                prose.append(characters[cursor + 1])
                cursor += 2
                continue
            }

            if let annotation = Annotation(character), opensSpan(characters, at: cursor) {
                switch scanSpan(characters, from: cursor, as: annotation, origin: origin, diagnostics: &diagnostics) {
                case let .literal(literal, next):
                    prose += literal
                    cursor = next
                case let .named(name, amount, next):
                    flush(&prose, into: &segments)
                    switch annotation {
                    case .ingredient:
                        let ingredient = Ingredient(name: name, amount: amount)
                        segments.append(.ingredient(ingredient))
                        ingredients.append(ingredient)
                    case .cookware:
                        let piece = Cookware(name: name)
                        segments.append(.cookware(piece))
                        cookware.append(piece)
                    }
                    cursor = next
                }
                continue
            }

            prose.append(character)
            cursor += 1
        }

        flush(&prose, into: &segments)

        return Step(
            segments: segments,
            ingredients: ingredients,
            cookware: cookware,
            text: text
        )
    }

    private static func flush(_ prose: inout String, into segments: inout [Segment]) {
        guard !prose.isEmpty else { return }
        segments.append(.text(prose))
        prose = ""
    }

    private static func opensSpan(_ characters: [Character], at index: Int) -> Bool {
        index + 1 < characters.count && !characters[index + 1].isWhitespace
    }

    /// Finds the span's closing sigil, skipping any escaped sigil so `\@` inside `@...@`
    /// stays part of the name rather than closing it. The escape is kept verbatim.
    private static func closingSigil(_ sigil: Character, in characters: [Character], from start: Int) -> Int? {
        var cursor = start
        while cursor < characters.count {
            if characters[cursor] == "\\", cursor + 1 < characters.count, escapable.contains(characters[cursor + 1]) {
                cursor += 2
                continue
            }
            if characters[cursor] == sigil { return cursor }
            cursor += 1
        }
        return nil
    }

    /// Scans one annotation span that opens at `start`. A well-formed span becomes a named
    /// annotation; an unclosed span, or an amount fence with no closing brace before the
    /// closing sigil, degrades to literal text with a warning so the surrounding paragraph
    /// still reads.
    private static func scanSpan(
        _ characters: [Character],
        from start: Int,
        as annotation: Annotation,
        origin: Origin,
        diagnostics: inout [Diagnostic]
    ) -> Span {
        let sigil = annotation.sigil
        let contentStart = start + 1

        // The closing sigil bounds the span, so it is located before the amount fence: a
        // fence brace past it belongs to a later span, not to this one.
        guard let closingSigil = closingSigil(sigil, in: characters, from: contentStart) else {
            diagnostics.append(.warning(
                .unclosedSpan,
                "\(annotation.noun) span is missing a closing sigil.",
                at: origin.range(offset: start, length: 1)
            ))

            return .literal(String(characters[start]), next: start + 1)
        }

        var nameStart = contentStart
        var amount: Amount?

        if annotation.allowsAmount, characters[contentStart] == "{" {
            guard let closingBrace = characters[(contentStart + 1)..<closingSigil].firstIndex(of: "}") else {
                // An amount fence with no closing brace before the closing sigil makes the
                // whole span not well-formed.
                diagnostics.append(.warning(
                    .unclosedSpan,
                    "Amount fence is missing a closing brace.",
                    at: origin.range(offset: start, length: closingSigil - start + 1)
                ))

                return .literal(String(characters[start...closingSigil]), next: closingSigil + 1)
            }

            amount = AmountParser.parse(String(characters[(contentStart + 1)..<closingBrace]))
            nameStart = closingBrace + 1

            // One space usually separates the fence from the name, but it is optional.
            if nameStart < closingSigil, characters[nameStart] == " " { nameStart += 1 }
        }

        let name = unescaped(characters, from: nameStart, to: closingSigil)

        // A span that names nothing is ordinary text, not an annotation of nothing.
        guard !name.isEmpty else {
            return .literal(String(characters[start...closingSigil]), next: closingSigil + 1)
        }

        return .named(name: name, amount: amount, next: closingSigil + 1)
    }

    /// Resolves each escape in a range of characters to the literal character it produces,
    /// dropping the backslash.
    private static func unescaped(_ characters: [Character], from start: Int, to end: Int) -> String {
        var result = ""
        var cursor = start
        while cursor < end {
            if characters[cursor] == "\\", cursor + 1 < end, escapable.contains(characters[cursor + 1]) {
                result.append(characters[cursor + 1])
                cursor += 2
            } else {
                result.append(characters[cursor])
                cursor += 1
            }
        }

        return result
    }
}
