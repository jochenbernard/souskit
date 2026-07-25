/// A reference to an intermediate produced by another group, written `>name>`.
public struct Reference: Equatable, Hashable, Sendable {
    /// The name of the group referred to, trimmed of surrounding whitespace.
    public var target: String

    /// The portion consumed, from the annotation's fence, or `nil` when it has none.
    public var amount: Amount?

    /// The flags written after the closing sigil.
    public var flags: Flags
}
