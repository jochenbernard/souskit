/// A span of the source, from its start up to but not including its end.
public struct SourceRange: Equatable, Hashable, Sendable {
    /// The first position of the range.
    public var start: SourceLocation

    /// The position just past the range.
    public var end: SourceLocation
}
