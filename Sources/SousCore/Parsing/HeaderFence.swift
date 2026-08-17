/// The `---` line opening and closing the metadata header.
enum HeaderFence {
    /// The text a fence line is written as.
    static let marker = "---"

    /// Whether the line is a fence, ignoring trailing whitespace.
    ///
    /// Leading whitespace disqualifies a line, so an indented `---` is ordinary content.
    static func matches(_ line: Substring) -> Bool {
        SourceText.withoutTrailingWhitespace(line) == marker
    }
}
