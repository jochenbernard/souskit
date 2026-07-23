/// A piece of cookware annotated in a step with the `#...#` sigils.
public struct Cookware: Equatable, Hashable, Sendable {
    /// The cookware's name, captured with nothing stripped and each escape resolved.
    ///
    /// Writing wraps the name in its sigils, so a name that is empty, that opens with
    /// whitespace, or that holds a blank line writes text a reader takes for prose rather than
    /// for cookware, and reading produces none of them.
    public var name: String
}
