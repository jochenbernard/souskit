extension Recipe {
    /// The recipe as Sous source text.
    ///
    /// Content is preserved and incidental layout such as repeated blank lines is normalized, so
    /// re-reading the result yields the same recipe.
    ///
    /// - Returns: The recipe as Sous source text.
    public func serialized() -> String {
        let hasHeader = !metadata.entries.isEmpty
        var blocks: [String] = []

        if hasHeader {
            blocks.append(metadata.serialized())
        }

        let body = groups.map({ $0.serialized() }).filter({ !$0.isEmpty })
        if !body.isEmpty {
            blocks.append(body.joined(separator: "\n\n"))
        }

        let text = blocks.joined(separator: "\n\n")
        guard !hasHeader else { return text }

        // A recipe with no header whose body would open a header fence or a byte order mark needs
        // something in front, or re-reading would take that opening line as a header.
        if Self.opensAHeader(text) { return "\(metadata.serialized())\n\n\(text)" }
        if text.hasPrefix(SourceText.byteOrderMark) { return "\n\(text)" }

        return text
    }

    /// Whether the first non-blank line of the text is a header fence.
    private static func opensAHeader(_ text: String) -> Bool {
        SourceText.lines(of: text).first(where: { !SourceText.isBlank($0) }).map(HeaderFence.matches) ?? false
    }
}
