/// Where something sits in the source, given as a line, a column, and a character offset.
///
/// ``column`` and ``offset`` count Swift `Character` values, so an emoji counts once however
/// many Unicode scalars or UTF-8 bytes it holds. Bridging to a tool that measures in UTF-8 or
/// UTF-16 needs a conversion.
public struct SourceLocation: Equatable, Hashable, Sendable {
    /// Which line, counting from 1.
    public var line: Int

    /// Which character within the line, counting from 1.
    public var column: Int

    /// Which character from the start of the source, counting from 0.
    public var offset: Int
}
