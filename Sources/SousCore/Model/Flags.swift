/// The named flags attached to an annotation after its closing sigil.
///
/// A flag can only state a status, never deny one, so an unattached flag is `false`. Where
/// reference data carries the same status, `false` leaves the answer to that reference data.
public struct Flags: Equatable, Hashable, Sendable {
    /// Whether an `:optional` flag, or its `?` shorthand, marks what it is attached to as one to leave out.
    public var isOptional: Bool

    /// Whether a `:staple` flag marks what it is attached to as a pantry staple.
    public var isStaple: Bool

    /// Whether a `:non-food` flag marks what it is attached to as not a food or shopping item.
    public var isNonFood: Bool

    /// The flag names that are not recognized, in document order. They are preserved rather than dropped.
    public var unrecognized: [String]

    /// No flags at all: what an annotation carrying none reads, and what one that takes none
    /// reads. It is the only place the unflagged value is spelled out, so a flag a later
    /// version adds joins it in one edit.
    static let empty = Self(
        isOptional: false,
        isStaple: false,
        isNonFood: false,
        unrecognized: []
    )
}
