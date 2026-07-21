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

    /// Whether an `=` before the quantity marks the amount as fixed, holding it constant when the recipe is scaled.
    public var isFixed: Bool

    /// The verbatim text the amount was read from: the content of an amount fence, without its
    /// braces, or the one part of a timer it states.
    ///
    /// It is the only property writing an amount emits. ``kind``, ``unit``, and ``isFixed`` were
    /// read from it, so changing one of them states something the written amount does not.
    public var text: String
}
