// Scans one paragraph into a step: ordered prose and annotation segments.
//
// A sigil opens a span only when immediately followed by a non-whitespace character. A
// span that is never closed, or an amount fence with no closing brace, degrades to
// literal text with a warning, so the surrounding paragraph still reads.

enum StepParser {
    private enum Outcome<Annotation> {
        case annotation(Annotation, next: Int)
        case literal(String, next: Int)
    }

    private static let escapable: Set<Character> = ["@", "#", "~", ">", "{"]

    static func parse(_ text: String, diagnostics: inout [Diagnostic]) -> Step {
        let characters = Array(text)
        var segments: [Segment] = []
        var ingredients: [Ingredient] = []
        var cookware: [Cookware] = []
        var prose = ""
        var cursor = 0

        while cursor < characters.count {
            let character = characters[cursor]

            // A backslash produces the literal sigil, kept verbatim so it round-trips.
            if character == "\\", cursor + 1 < characters.count, escapable.contains(characters[cursor + 1]) {
                prose.append(character)
                prose.append(characters[cursor + 1])
                cursor += 2
                continue
            }

            if character == "@", opensSpan(characters, at: cursor) {
                switch scanIngredient(characters, from: cursor, diagnostics: &diagnostics) {
                case let .annotation(ingredient, next):
                    flush(&prose, into: &segments)
                    segments.append(.ingredient(ingredient))
                    ingredients.append(ingredient)
                    cursor = next
                case let .literal(literal, next):
                    prose += literal
                    cursor = next
                }
                continue
            }

            if character == "#", opensSpan(characters, at: cursor) {
                switch scanCookware(characters, from: cursor, diagnostics: &diagnostics) {
                case let .annotation(piece, next):
                    flush(&prose, into: &segments)
                    segments.append(.cookware(piece))
                    cookware.append(piece)
                    cursor = next
                case let .literal(literal, next):
                    prose += literal
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

    private static func index(of character: Character, in characters: [Character], from start: Int) -> Int? {
        var cursor = start
        while cursor < characters.count {
            if characters[cursor] == character { return cursor }
            cursor += 1
        }
        return nil
    }

    private static func scanIngredient(
        _ characters: [Character],
        from start: Int,
        diagnostics: inout [Diagnostic]
    ) -> Outcome<Ingredient> {
        var cursor = start + 1
        var amount: Amount?

        if characters[cursor] == "{" {
            guard let closingBrace = index(of: "}", in: characters, from: cursor + 1) else {
                // An amount fence with no closing brace makes the whole span not well-formed.
                diagnostics.append(.warning(.unclosedSpan, "Amount fence is missing a closing brace."))
                if let closingSigil = index(of: "@", in: characters, from: cursor) {
                    return .literal(String(characters[start...closingSigil]), next: closingSigil + 1)
                }
                return .literal(String(characters[start...]), next: characters.count)
            }

            amount = AmountParser.parse(String(characters[(cursor + 1)..<closingBrace]))
            cursor = closingBrace + 1

            // One space separates the fence from the name.
            if cursor < characters.count, characters[cursor] == " " { cursor += 1 }
        }

        guard let closingSigil = index(of: "@", in: characters, from: cursor) else {
            diagnostics.append(.warning(.unclosedSpan, "Ingredient span is missing a closing sigil."))
            return .literal(String(characters[start]), next: start + 1)
        }

        let ingredient = Ingredient(
            name: String(characters[cursor..<closingSigil]),
            amount: amount
        )

        return .annotation(ingredient, next: closingSigil + 1)
    }

    private static func scanCookware(
        _ characters: [Character],
        from start: Int,
        diagnostics: inout [Diagnostic]
    ) -> Outcome<Cookware> {
        guard let closingSigil = index(of: "#", in: characters, from: start + 1) else {
            diagnostics.append(.warning(.unclosedSpan, "Cookware span is missing a closing sigil."))
            return .literal(String(characters[start]), next: start + 1)
        }

        return .annotation(Cookware(name: String(characters[(start + 1)..<closingSigil])), next: closingSigil + 1)
    }
}
