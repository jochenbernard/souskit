/// A single element of a step's body: a run of prose or an inline annotation.
public enum Segment: Equatable, Hashable, Sendable {
    /// A run of ordinary prose.
    case text(String)

    /// An ingredient annotation.
    case ingredient(Ingredient)

    /// A cookware annotation.
    case cookware(Cookware)

    /// A timer annotation.
    case timer(Timer)

    /// A reference annotation.
    case reference(Reference)
}

extension Segment {
    /// The ingredient the segment annotates, or `nil` for any other kind of segment.
    var ingredient: Ingredient? {
        if case let .ingredient(ingredient) = self { ingredient } else { nil }
    }

    /// The cookware the segment annotates, or `nil` for any other kind of segment.
    var cookware: Cookware? {
        if case let .cookware(cookware) = self { cookware } else { nil }
    }

    /// The timer the segment annotates, or `nil` for any other kind of segment.
    var timer: Timer? {
        if case let .timer(timer) = self { timer } else { nil }
    }

    /// The reference the segment annotates, or `nil` for any other kind of segment.
    var reference: Reference? {
        if case let .reference(reference) = self { reference } else { nil }
    }
}
