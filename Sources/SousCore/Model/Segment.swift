/// One piece of a step: a run of prose, or an annotation.
public enum Segment: Equatable, Hashable, Sendable {
    /// A run of prose, with escapes resolved.
    case text(String)

    /// An ingredient annotation.
    case ingredient(Ingredient)

    /// A cookware annotation.
    case cookware(Cookware)

    /// A timer annotation.
    case timer(Timer)

    /// A reference annotation.
    case reference(Reference)

    /// The ingredient, or `nil` for any other segment.
    var ingredient: Ingredient? {
        if case let .ingredient(ingredient) = self { ingredient } else { nil }
    }

    /// The cookware, or `nil` for any other segment.
    var cookware: Cookware? {
        if case let .cookware(cookware) = self { cookware } else { nil }
    }

    /// The timer, or `nil` for any other segment.
    var timer: Timer? {
        if case let .timer(timer) = self { timer } else { nil }
    }

    /// The reference, or `nil` for any other segment.
    var reference: Reference? {
        if case let .reference(reference) = self { reference } else { nil }
    }
}
