/// A timer annotated in a step with the `~...~` sigils.
public struct Timer: Equatable, Hashable, Sendable {
    /// The form a timer's duration takes.
    public enum Kind: Equatable, Hashable, Sendable {
        /// A single quantity and unit, as in `40 min`.
        case precise

        /// A low and a high quantity, as in `8-10 min`.
        case range

        /// Two or more quantity-and-unit parts, as in `1 h 30 min`.
        case compound

        /// Words carrying no numeric value, as in `overnight`.
        case qualitative
    }

    /// The timer's numeric parts, in document order.
    ///
    /// A qualitative duration has none, a precise or range duration has one, and a compound duration has two or more.
    public var components: [Amount]

    /// The timer's content, captured with nothing stripped and each escape resolved.
    ///
    /// It is the text a qualitative duration displays, and the only property writing a timer
    /// emits. ``components`` were read from it, so changing them states something the written
    /// timer does not.
    ///
    /// Writing wraps the text in its sigils, so text that is empty, that opens with
    /// whitespace, or that holds a blank line writes text a reader takes for prose rather than
    /// for a timer, and reading produces none of them.
    public var text: String

    /// The form this duration takes, classified from the components.
    public var kind: Kind {
        switch components.count {
        case 0:
            .qualitative
        case 1:
            switch components[0].kind {
            case .precise: .precise
            case .range: .range
            case .imprecise: .qualitative
            }
        default:
            .compound
        }
    }
}
