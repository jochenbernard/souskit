/// A span of the source, from its start up to but not including its end.
public struct SourceRange: Equatable, Hashable, Sendable {
    /// The location of the first character in the range.
    public var start: SourceLocation

    /// The location just past the range.
    public var end: SourceLocation
}
