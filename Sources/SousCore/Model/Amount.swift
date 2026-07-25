/// An amount written in an amount fence, such as `{200 g}` or `{1-2 tbsp}`.
public struct Amount: Equatable, Hashable, Sendable {
    /// The form an amount takes.
    public enum Kind: Equatable, Hashable, Sendable {
        /// A single quantity, such as `200 g`.
        case precise(Quantity)

        /// A low and a high quantity, such as `1-2 tbsp`.
        case range(Quantity, Quantity)

        /// An amount with no usable leading number, such as `a pinch` or `1,5 l`.
        /// Scaling leaves it unchanged.
        case imprecise(String)
    }

    /// The form this amount takes.
    public var kind: Kind

    /// The unit, trimmed of the whitespace separating it from the quantity.
    ///
    /// This is `nil` for an imprecise amount, and empty for a quantity written without a unit.
    public var unit: String?

    /// Whether the fence's `=` marker holds this amount constant when the recipe is scaled.
    public var isFixed: Bool

    /// The amount as written: the fence content without its braces or `=` marker, trimmed.
    ///
    /// Serializing wraps this in braces, so ``kind`` and ``unit`` alone do not determine what is
    /// written back. Scaling regenerates all three together.
    public var text: String
}
