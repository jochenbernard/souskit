// The inline annotations version 0.1 reads, and the sigil rules that govern them.
//
// Reading and writing share this one table, so the sigil a writer wraps a span in is the
// sigil a reader opens it on, and a sigil a later version activates is added once.

enum Annotation: Character {
    case ingredient = "@"
    case cookware = "#"

    /// The sigil that opens and closes the span.
    var sigil: Character { rawValue }

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

    /// A sigil opens a span only when it is immediately followed by a non-whitespace
    /// character, so `bake @ 180C` and a line beginning `# ` stay ordinary text.
    static func opensSpan(before following: Character?) -> Bool {
        following.map({ !$0.isWhitespace }) ?? false
    }

    /// The span this annotation writes around the given content.
    func span(around content: String) -> String {
        "\(sigil)\(content)\(sigil)"
    }
}
