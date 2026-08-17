/// A run of steps, named by a `## Name` heading when it has one.
public struct StepGroup: Equatable, Hashable, Sendable {
    /// The heading name, trimmed of surrounding whitespace, or `nil` for steps written before any
    /// heading.
    public var name: String?

    /// The steps of the group, in document order.
    public var steps: [Step]

    /// The ingredients annotated across the group's steps, in document order.
    public var ingredients: [Ingredient] {
        steps.ingredients
    }

    /// The cookware annotated across the group's steps, in document order.
    public var cookware: [Cookware] {
        steps.cookware
    }

    /// The timers annotated across the group's steps, in document order.
    public var timers: [Timer] {
        steps.timers
    }

    /// The references annotated across the group's steps, in document order.
    public var references: [Reference] {
        steps.references
    }
}
