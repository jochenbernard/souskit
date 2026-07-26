/// A reference to an intermediate produced by another group, written `>name>` or
/// `>{amount}name>`.
public struct Reference: Equatable, Hashable, Sendable {
    /// The group name written in the reference, trimmed of surrounding whitespace.
    ///
    /// Reading a recipe does not resolve the name. ``Recipe/validate()`` reports
    /// ``Diagnostic/Kind/unresolvedReference`` when no group carries it.
    public var target: String

    /// The amount consumed, from the annotation's fence, or `nil` when it has none.
    public var amount: Amount?

    /// The flags written after the closing sigil.
    public var flags: Flags
}
