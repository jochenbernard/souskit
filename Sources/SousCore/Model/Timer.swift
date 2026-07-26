/// A timer annotated in a step, written `~40 min~`.
public struct Timer: Equatable, Hashable, Sendable {
    /// The form a timer takes, derived from its components.
    public enum Kind: Equatable, Hashable, Sendable {
        /// One component holding a single quantity, such as `40 min`.
        case precise

        /// One component holding a range, such as `30-40 min`.
        case range

        /// More than one component, such as `1 h 30 min`.
        case compound

        /// No component, or one with no usable number, such as `until golden`.
        case qualitative
    }

    /// The amounts the timer is written as, in the order written.
    public var components: [Amount]

    /// The timer as written, without its sigils and trimmed.
    public var text: String

    /// The form this timer takes.
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
