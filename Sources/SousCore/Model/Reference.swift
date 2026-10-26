/// A reference to an intermediate produced by another group or another recipe file, written
/// `>name>` or `>{amount}name>`.
public struct Reference: Equatable, Hashable, Sendable {
    /// The group name or file path written in the reference, trimmed of surrounding whitespace.
    ///
    /// Reading a recipe does not resolve the name; ``Recipe/destination(of:)`` and
    /// ``Recipe/resolve(_:from:using:)`` do.
    public var target: String

    /// The amount consumed, from the annotation's fence, or `nil` when it has none.
    public var amount: Amount?

    /// The flags written after the closing sigil.
    public var flags: Flags
}
