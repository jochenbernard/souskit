/// A single position in the source.
public struct SourceLocation: Equatable, Hashable, Sendable {
    /// The line, counting from 1.
    public var line: Int

    /// The character within the line, counting from 1.
    public var column: Int

    /// The character offset from the start of the source, counting from 0.
    public var offset: Int
}
