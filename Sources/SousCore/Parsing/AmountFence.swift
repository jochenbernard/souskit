/// The braces an amount is written in, and the marker that fixes it.
enum AmountFence {
    /// The character opening a fence.
    static let opening: Character = "{"

    /// The character closing a fence.
    static let closing: Character = "}"

    /// The marker holding an amount constant under scaling.
    static let fixedMarker: Character = "="

    /// Wraps content in a fence.
    static func around(_ content: String) -> String {
        "\(opening)\(content)\(closing)"
    }

    /// The fence content for an amount, with the marker restored when it is fixed.
    static func content(of amount: Amount) -> String {
        amount.isFixed ? "\(fixedMarker)\(amount.text)" : amount.text
    }
}
