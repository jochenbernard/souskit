extension Metadata {
    /// Renders the header, fences included, one line per entry in document order.
    func serialized() -> String {
        var lines = [SourceText.fence]

        for entry in entries {
            switch entry.value {
            case let .scalar(value):
                lines.append(Self.line(entry.key, value))
            case let .list(items):
                lines.append(Self.line(entry.key, items.isEmpty ? "" : Self.rendered(items)))
            case let .raw(line):
                lines.append(line)
            }
        }

        lines.append(SourceText.fence)

        return lines.joined(separator: "\n")
    }

    /// A `key: value` line, with no trailing space when the value is empty.
    private static func line(_ key: String, _ value: String) -> String {
        value.isEmpty ? "\(key):" : "\(key): \(value)"
    }

    /// The items as an inline list.
    private static func rendered(_ items: [String]) -> String {
        "[\(items.map(escapedItem).joined(separator: ", "))]"
    }

    /// An item with the characters that would split or close the list escaped.
    private static func escapedItem(_ item: String) -> String {
        SourceText.escaped(item, escaping: SourceText.isEscapableInList)
    }
}
