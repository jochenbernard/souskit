extension Recipe {
    /// Renders the recipe back to Sous source text.
    ///
    /// Content is preserved, while incidental layout such as repeated blank lines is
    /// normalized, so re-reading the result yields the same recipe.
    ///
    /// - Returns: The recipe rendered as Sous source text.
    public func serialized() -> String {
        var blocks: [String] = []

        if !metadata.entries.isEmpty {
            blocks.append(metadata.rendered)
        }

        let body = groups.map(\.rendered).filter({ !$0.isEmpty })
        if !body.isEmpty {
            blocks.append(body.joined(separator: "\n\n"))
        }

        let text = blocks.joined(separator: "\n\n")

        // With no header block in front of it, a body that starts the file is read as whatever
        // that position means, so a blank line keeps it in the body where it belongs.
        guard metadata.entries.isEmpty, Self.opensAsAnotherConstruct(text) else { return text }

        return "\n" + text
    }

    /// Whether text starting the file would be read as something other than body prose: a fence
    /// line opens a header, and a byte-order mark is taken for the file's own and dropped.
    private static func opensAsAnotherConstruct(_ text: String) -> Bool {
        text.hasPrefix(SourceText.byteOrderMark)
            || SourceText.isFence(text.prefix(while: { !$0.isNewline }))
    }
}
