/// A location in source text.
public struct SourceLocation: Equatable, Hashable, Sendable {
    /// The one-based line number.
    public var line: Int

    /// The one-based column number, in characters.
    public var column: Int

    /// The zero-based character offset from the start of the source.
    public var offset: Int
}
