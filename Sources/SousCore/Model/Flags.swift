/// The flags written after an ingredient or reference, such as `@salt@:staple`.
///
/// A flag is written as `:` followed by its name, and flags chain: `@thyme@?:staple`. The
/// shorthand `?` is equivalent to `:optional`.
public struct Flags: Equatable, Hashable, Sendable {
    /// Whether `:optional`, or its `?` shorthand, is set.
    public var isOptional: Bool

    /// Whether `:staple` is set.
    public var isStaple: Bool

    /// Whether `:non-food` is set.
    public var isNonFood: Bool

    /// The flag names this version does not recognize, in the order written.
    ///
    /// An unrecognized flag is preserved rather than dropped, so a file using a flag from a
    /// later version still reads and writes back unchanged.
    public var unrecognized: [String]

    /// Flags with nothing set.
    static let empty = Self(
        isOptional: false,
        isStaple: false,
        isNonFood: false,
        unrecognized: []
    )
}
