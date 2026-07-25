/// An ingredient annotated in a step with the `@...@` sigils.
public struct Ingredient: Equatable, Hashable, Sendable {
    /// The ingredient's name, captured trimmed of the whitespace around it and with each escape
    /// resolved.
    ///
    /// Writing wraps the name in its sigils, so a name that is empty or that holds a line break
    /// writes text a reader takes for prose rather than for an ingredient, and reading produces
    /// neither. A name opening with whitespace writes such text too, unless an amount fence
    /// stands between it and the opening sigil. Where the text does bound a name, reading trims
    /// the whitespace around it away.
    public var name: String

    /// The ingredient's amount, or `nil` when no amount fence is present.
    public var amount: Amount?

    /// The flags attached after the ingredient's closing sigil.
    public var flags: Flags
}
