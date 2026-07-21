/// A numeric quantity: an integer, a decimal, a fraction, or a mixed number.
public struct Quantity: Equatable, Hashable, Sendable {
    /// The computed numeric value. For example, `1 1/2` has the value `1.5`.
    public var value: Double

    /// The verbatim source text of the quantity.
    public var text: String
}
