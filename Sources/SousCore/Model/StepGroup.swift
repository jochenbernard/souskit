/// A part of a recipe's body: the steps a `## Name` heading opens, and what they annotate.
public struct StepGroup: Equatable, Hashable, Sendable {
    /// The group's name, or `nil` for the default group the steps before the first heading form.
    ///
    /// The name is captured with nothing stripped and each escape resolved. Only a named group
    /// produces an intermediate a reference can consume, so the default group is consumed by
    /// nothing.
    ///
    /// Writing opens the group with a heading, so a name that is empty, that opens with
    /// whitespace, or that holds a line break writes text a reader takes for prose rather than
    /// for a heading. Reading produces no such name.
    public var name: String?

    /// The group's steps, in document order.
    ///
    /// The steps are the store the annotation lists read, so editing them moves the lists with them.
    public var steps: [Step]

    /// The ingredients annotated across the group's steps, in document order.
    public var ingredients: [Ingredient] {
        steps.flatMap(\.ingredients)
    }

    /// The cookware annotated across the group's steps, in document order.
    public var cookware: [Cookware] {
        steps.flatMap(\.cookware)
    }

    /// The timers annotated across the group's steps, in document order.
    public var timers: [Timer] {
        steps.flatMap(\.timers)
    }

    /// The references annotated across the group's steps, in document order.
    public var references: [Reference] {
        steps.flatMap(\.references)
    }
}
