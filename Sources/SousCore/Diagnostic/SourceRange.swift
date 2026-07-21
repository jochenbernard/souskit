/// A range of source text, from a start location to an end location.
public struct SourceRange: Equatable, Hashable, Sendable {
    /// The location of the first character of the range.
    public var start: SourceLocation

    /// The location just past the last character of the range.
    public var end: SourceLocation
}
