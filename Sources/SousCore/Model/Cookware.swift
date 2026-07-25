/// A piece of cookware annotated in a step, written `#name#`.
public struct Cookware: Equatable, Hashable, Sendable {
    /// The name, trimmed of surrounding whitespace.
    public var name: String
}
