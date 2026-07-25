extension Recipe {
    /// Renders the recipe back to Sous source text.
    ///
    /// Content is preserved, while incidental layout such as repeated blank lines is
    /// normalized, so re-reading the result yields the same recipe.
    ///
    /// - Returns: The recipe rendered as Sous source text.
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

        // With no header block in front of it, a body that starts the file is read as whatever
        // that position means. An empty header states where the body starts, which a blank line
        // no longer does, since a reader steps over the blank lines before an opening fence. A
        // byte-order mark is taken for the file's own only at the very start, so a blank line
        // is what keeps one in the body.
        if Self.opensAHeader(text) { return "\(metadata.serialized())\n\n\(text)" }
        if text.hasPrefix(SourceText.byteOrderMark) { return "\n\(text)" }

        return text
    }

    /// Whether the text's first line stating anything would open a metadata header, the blank
    /// lines before one being layout a reader steps over.
    private static func opensAHeader(_ text: String) -> Bool {
        SourceText.lines(of: text).first(where: { !SourceText.isBlank($0) }).map(SourceText.isFence) ?? false
    }
}
