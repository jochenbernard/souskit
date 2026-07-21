/// The named flags attached to an annotation after its closing sigil.
///
/// A flag states a status and never denies one, so an unattached flag is `false` and leaves the status, where
/// reference data also carries one, to that reference data.
public struct Flags: Equatable, Hashable, Sendable {
    /// Whether an `:optional` flag, or its `?` shorthand, marks what it is attached to as one to leave out.
    public var isOptional: Bool

    /// Whether a `:staple` flag marks what it is attached to as a pantry staple.
    public var isStaple: Bool

    /// Whether a `:non-food` flag marks what it is attached to as not a food or shopping item.
    public var isNonFood: Bool

    /// The flag names that are not recognized, in document order. They are preserved rather than dropped.
    public var unrecognized: [String]
}
