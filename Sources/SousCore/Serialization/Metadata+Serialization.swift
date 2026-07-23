// Renders a metadata header back to source text: the entries between two fences, with a list
// value written in its inline form and every character the list gives a meaning of its own
// escaped inside it.

extension Metadata {
    /// The header as source text: its entries between an opening and a closing fence, one to
    /// a line.
    var rendered: String {
        var lines = [SourceText.fence]

        for entry in entries {
            switch entry.value {
            case let .scalar(value):
                lines.append(Self.line(entry.key, value))
            case let .list(items):
                // A list of nothing has no inline form, so it writes as the key alone, which
                // leaves a block list a later version introduces sitting under that key.
                lines.append(Self.line(entry.key, items.isEmpty ? "" : Self.rendered(items)))
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
