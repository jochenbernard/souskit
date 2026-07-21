/// A parsed Sous recipe: its metadata header and its ordered body steps.
public struct Recipe: Equatable, Hashable, Sendable {
    /// The recipe's metadata header.
    public var metadata: Metadata

    /// The recipe's body steps, in document order.
    public var steps: [Step]

    /// The ingredients annotated across every step, in document order.
    public var ingredients: [Ingredient] {
        steps.flatMap(\.ingredients)
    }

    /// The cookware annotated across every step, in document order.
    public var cookware: [Cookware] {
        steps.flatMap(\.cookware)
    }
}
