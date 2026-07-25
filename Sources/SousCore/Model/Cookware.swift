/// A piece of cookware annotated in a step with the `#...#` sigils.
public struct Cookware: Equatable, Hashable, Sendable {
    /// The cookware's name, captured trimmed of the whitespace around it and with each escape
    /// resolved.
    ///
    /// Writing wraps the name in its sigils, so a name that is empty, that opens with
    /// whitespace, or that holds a line break writes text a reader takes for prose rather than
    /// for cookware, and reading produces none of them. A name ending in whitespace reads back
    /// without it.
    public var name: String
}
