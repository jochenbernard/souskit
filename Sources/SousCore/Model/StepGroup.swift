/// A part of a recipe's body: the steps a `## Name` heading opens, and what they annotate.
public struct StepGroup: Equatable, Hashable, Sendable {
    /// The group's name, or `nil` for the default group the steps before the first heading form.
    ///
    /// The name is captured trimmed of the whitespace around it and with each escape resolved.
    /// Only a named group produces an intermediate a reference can consume, so the default
    /// group is consumed by nothing.
    ///
    /// Writing opens the group with a heading, so a name that is empty or that is nothing but
    /// whitespace leaves a line a reader takes for prose rather than for a heading, and one
    /// that holds a line break ends the heading at that break and leaves the rest to be read as
    /// the body after it. Reading produces none of them, and a name the whitespace around it
    /// survives writing reads back without it.
    public var name: String?

    /// The group's steps, in document order.
    ///
    /// The steps are the store the annotation lists read, so editing them moves the lists with them.
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
