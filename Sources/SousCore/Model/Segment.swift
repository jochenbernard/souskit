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
}
