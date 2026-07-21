/// An ingredient annotated in a step with the `@...@` sigils.
public struct Ingredient: Equatable, Hashable, Sendable {
    /// The ingredient's name, captured with nothing stripped and each escape resolved.
    public var name: String

    /// The ingredient's amount, or `nil` when no amount fence is present.
    public var amount: Amount?
}
