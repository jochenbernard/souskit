/// A number read from an amount, together with the text it was written as.
public struct Quantity: Equatable, Hashable, Sendable {
    /// The numeric value.
    public var value: Double

    /// The number as written, such as `1`, `0.5`, or `1/2`.
    public var text: String
}
