/// A number read from an amount, together with the text it was written as.
public struct Quantity: Equatable, Hashable, Sendable {
    /// The value as a number, with any fraction resolved: `1/2` is `0.5`.
    public var value: Double

    /// The number as written, such as `1`, `0.5`, or `1/2`.
    public var text: String
}
