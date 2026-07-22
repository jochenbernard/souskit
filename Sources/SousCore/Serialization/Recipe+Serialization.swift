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
            blocks.append(Self.rendered(metadata))
        }

        if !steps.isEmpty {
            blocks.append(steps.map(\.rendered).joined(separator: "\n\n"))
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

    private static func rendered(_ metadata: Metadata) -> String {
        var lines = [SourceText.fence]

        for entry in metadata.entries {
            switch entry.value {
            case let .scalar(value):
                lines.append(line(entry.key, value))
            case let .list(items):
                // A list of nothing has no inline form, so it writes as the key alone, which
                // leaves a block list a later version introduces sitting under that key.
                lines.append(line(entry.key, items.isEmpty ? "" : rendered(items)))
            case let .raw(line):
                lines.append(line)
            }
        }

        lines.append(SourceText.fence)

        return lines.joined(separator: "\n")
    }

    /// An entry as one line. An empty value ends the line at the separator, where a trailing
    /// space would be incidental layout.
    private static func line(_ key: String, _ value: String) -> String {
        value.isEmpty ? "\(key):" : "\(key): \(value)"
    }

    /// Renders a list value in the inline form, which every item survives because the
    /// characters the list gives a meaning of its own are escaped inside it.
    private static func rendered(_ items: [String]) -> String {
        "[\(items.map(escapedItem).joined(separator: ", "))]"
    }

    /// Escapes each character an inline list reads as its own structure, so an item holding a
    /// separator, a bracket, or a backslash reads back verbatim.
    private static func escapedItem(_ item: String) -> String {
        var result = ""

        for character in item {
            if SourceText.isEscapableInList(character) { result.append(SourceText.escape) }
            result.append(character)
        }

        return result
    }
}
