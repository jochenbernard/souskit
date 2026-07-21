/// A piece of cookware annotated in a step with the `#...#` sigils.
public struct Cookware: Equatable, Hashable, Sendable {
    /// The cookware's name, captured with nothing stripped and each escape resolved.
    public var name: String
}
