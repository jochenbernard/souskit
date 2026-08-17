/// An ingredient annotated in a step, written `@name@` or `@{amount}name@`.
public struct Ingredient: Equatable, Hashable, Sendable {
    /// The name, trimmed of surrounding whitespace.
    public var name: String

    /// The amount from the annotation's fence, or `nil` when it has none.
    public var amount: Amount?

    /// The flags written after the closing sigil.
    public var flags: Flags
}
