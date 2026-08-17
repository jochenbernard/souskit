/// A parsed Sous recipe: its metadata header and its body groups.
public struct Recipe: Equatable, Hashable, Sendable {
    /// The metadata header.
    public var metadata: Metadata

    /// The body groups, in document order.
    ///
    /// A body opening with steps rather than a heading holds them in a group whose
    /// ``StepGroup/name`` is `nil`. A recipe with no body holds no group.
    public var groups: [StepGroup]

    /// The steps of every group, in document order.
    public var steps: [Step] {
        groups.flatMap(\.steps)
    }

    /// The ingredients annotated across every step, in document order.
    public var ingredients: [Ingredient] {
        steps.ingredients
    }

    /// The cookware annotated across every step, in document order.
    public var cookware: [Cookware] {
        steps.cookware
    }

    /// The timers annotated across every step, in document order.
    public var timers: [Timer] {
        steps.timers
    }

    /// The references annotated across every step, in document order.
    public var references: [Reference] {
        steps.references
    }
}
