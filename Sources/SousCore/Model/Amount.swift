/// An amount written in an amount fence (`{...}`).
public struct Amount: Equatable, Hashable, Sendable {
    /// The form an amount takes.
    public enum Kind: Equatable, Hashable, Sendable {
        /// A single numeric quantity.
        case precise(Quantity)

        /// A range between a low and a high quantity.
        case range(Quantity, Quantity)

        /// A textual amount, captured as the trimmed text states it: one with no leading
        /// number, or one opening as a number it cannot finish, such as a decimal written with
        /// a comma. Reading the second reports it, so a number nobody wrote never scales.
        case imprecise(String)
    }

    /// The form this amount takes.
    public var kind: Kind

    /// The unit, captured trimmed of the whitespace separating it from the quantity. It is
    /// `nil` for an imprecise amount and may be empty when a quantity has no unit.
    public var unit: String?

    /// Whether the fence's `=` marker fixes the amount, holding it constant when the recipe is
    /// scaled.
    ///
    /// The marker opens the fence and states that the whole amount holds still, so it fixes an
    /// imprecise amount as readily as a numeric one, whatever whitespace separates the two. An
    /// imprecise amount never moves under scaling in any case, so there the marker records the
    /// author's intent and nothing more.
    public var isFixed: Bool

    /// The text the amount was read from, trimmed of the whitespace around it and of the
    /// marker: the content of an amount fence, without its braces, or the one part of a timer
    /// it states.
    ///
    /// Writing emits this and ``isFixed``, the marker going back where reading took it from.
    /// ``kind`` and ``unit`` were read from the text, so changing one of them states something
    /// the written amount does not. Scaling changes them together, taking the amount from
    /// reading its regenerated text back.
    ///
    /// Writing wraps the text in the fence's braces, so text holding a closing brace closes
    /// that fence early, and text holding a line break leaves the fence unclosed on its line.
    /// Reading produces neither.
    public var text: String
}
