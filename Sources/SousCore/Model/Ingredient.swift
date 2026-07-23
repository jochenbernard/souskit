/// An ingredient annotated in a step with the `@...@` sigils.
public struct Ingredient: Equatable, Hashable, Sendable {
    /// The ingredient's name, captured with nothing stripped and each escape resolved.
    ///
    /// Writing wraps the name in its sigils, so a name that is empty or that holds a blank line
    /// writes text a reader takes for prose rather than for an ingredient, and reading produces
    /// neither. A name opening with whitespace writes such text too, unless an amount fence
    /// stands between it and the opening sigil, which is where reading does produce one.
    public var name: String

    /// The ingredient's amount, or `nil` when no amount fence is present.
    public var amount: Amount?

    /// The flags attached after the ingredient's closing sigil.
    public var flags: Flags
}
