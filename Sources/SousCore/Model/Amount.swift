/// An amount written in an amount fence (`{...}`).
public struct Amount: Equatable, Hashable, Sendable {
    /// The form an amount takes.
    public enum Kind: Equatable, Hashable, Sendable {
        /// A single numeric quantity.
        case precise(Quantity)

        /// A range between a low and a high quantity.
        case range(Quantity, Quantity)

        /// A textual amount with no leading number, captured verbatim.
        case imprecise(String)
    }

    /// The form this amount takes.
    public var kind: Kind

    /// The unit, captured verbatim. It is `nil` for an imprecise amount and may be empty when a quantity has no unit.
    public var unit: String?

    /// The verbatim source text of the amount.
    public var text: String
}
