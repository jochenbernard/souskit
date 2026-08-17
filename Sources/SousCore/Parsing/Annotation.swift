/// The four kinds of annotation span, identified by the sigil that delimits them.
enum Annotation: Character, CaseIterable {
    case ingredient = "@"
    case cookware = "#"
    case timer = "~"
    case reference = ">"

    /// The character opening and closing this annotation's span.
    var sigil: Character { rawValue }

    /// The capitalized name used in diagnostic messages.
    var noun: String {
        switch self {
        case .ingredient: "Ingredient"
        case .cookware: "Cookware"
        case .timer: "Timer"
        case .reference: "Reference"
        }
    }

    /// Whether this annotation may carry an amount fence.
    var allowsAmount: Bool {
        switch self {
        case .ingredient, .reference: true
        case .cookware, .timer: false
        }
    }

    /// Whether this annotation may carry flags after its closing sigil.
    var allowsFlags: Bool {
        switch self {
        case .ingredient, .reference: true
        case .cookware, .timer: false
        }
    }

    /// Whether a sigil opens a span, given the character after it.
    ///
    /// A sigil followed by whitespace or by nothing is ordinary text, so prose such as
    /// `Bake @ 180C` opens no span.
    static func opensSpan(before following: Character?) -> Bool {
        following.map({ !$0.isWhitespace }) ?? false
    }

    /// Wraps content in this annotation's sigils.
    func span(around content: String) -> String {
        "\(sigil)\(content)\(sigil)"
    }
}
