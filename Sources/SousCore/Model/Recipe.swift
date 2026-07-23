/// A parsed Sous recipe: its metadata header and its ordered body groups.
public struct Recipe: Equatable, Hashable, Sendable {
    /// The recipe's metadata header.
    public var metadata: Metadata

    /// The recipe's body groups, in document order.
    ///
    /// The groups are the store the step and annotation lists read, so editing them moves the
    /// lists with them. A body opening with steps rather than with a heading holds them in an
    /// unnamed group, so a file writing no heading at all holds one group, and a file with no
    /// body holds none.
    public var groups: [StepGroup]

    /// The steps of every group, in document order.
    public var steps: [Step] {
        groups.flatMap(\.steps)
    }

    /// The ingredients annotated across every step, in document order.
    public var ingredients: [Ingredient] {
        steps.flatMap(\.ingredients)
    }

    /// The cookware annotated across every step, in document order.
    public var cookware: [Cookware] {
        steps.flatMap(\.cookware)
    }

    /// The timers annotated across every step, in document order.
    public var timers: [Timer] {
        steps.flatMap(\.timers)
    }

    /// The references annotated across every step, in document order.
    public var references: [Reference] {
        steps.flatMap(\.references)
    }
}
