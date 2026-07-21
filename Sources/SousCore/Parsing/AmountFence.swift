// The amount fence version 0.2 reads, and the braces that delimit it.
//
// Reading and writing share this one table, so the brace a writer wraps an amount in is
// the brace a reader opens a fence on, and the escape that keeps a brace out of that
// position is stated against the same character.

enum AmountFence {
    /// The brace that opens the fence. It is escapable, because a reader that took it for
    /// a fence would not read it as the text it stands for.
    static let opening: Character = "{"

    /// The brace that closes the fence. Every character between the two belongs to the
    /// amount, so this one needs no escape and never gets one.
    static let closing: Character = "}"

    /// The fence this writes around the given content.
    static func around(_ content: String) -> String {
        "\(opening)\(content)\(closing)"
    }
}
