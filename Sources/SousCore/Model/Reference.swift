/// A reference to an intermediate produced by another group, written `>name>`.
public struct Reference: Equatable, Hashable, Sendable {
    /// The group name written in the reference, trimmed of surrounding whitespace. It may match
    /// no group.
    public var target: String

    /// The portion consumed, from the annotation's fence, or `nil` when it has none.
    public var amount: Amount?

    /// The flags written after the closing sigil.
    public var flags: Flags
}
