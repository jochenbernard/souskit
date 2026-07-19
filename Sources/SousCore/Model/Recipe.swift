/// A parsed Sous recipe: its metadata header and its ordered body steps.
public struct Recipe: Equatable, Hashable, Sendable {
    /// The recipe's metadata header.
    public var metadata: Metadata

    /// The recipe's body steps, in document order.
    public var steps: [Step]
}
