/// A span of the source, from its start up to but not including its end.
///
/// Every range a diagnostic carries covers at least one character, so parsing never produces
/// one whose ``start`` and ``end`` are equal.
public struct SourceRange: Equatable, Hashable, Sendable {
    /// The location of the first character in the range.
    public var start: SourceLocation

    /// The location just past the range.
    public var end: SourceLocation
}
