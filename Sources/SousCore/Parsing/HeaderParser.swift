// Splits a recipe into its optional metadata header and its body, and reads the header
// into typed accessors over an ordered raw store.
//
// Values are literal text with no type coercion. Unrecognized keys are preserved and
// warned about, never dropped.

enum HeaderParser {
    /// The keys v0.1 recognizes. Everything else is preserved and reported as unknown.
    private static let listKeys: Set<String> = ["tags"]
    private static let scalarKeys: Set<String> = ["title", "language", "version", "servings", "source"]

    static func split(
        _ lines: [Substring],
        map: SourceMap,
        diagnostics: inout [Diagnostic]
    ) -> (header: [Substring], body: [Substring]) {
        guard let first = lines.first, SourceText.isFence(first) else {
            return (header: [], body: lines)
        }

        for index in lines.indices.dropFirst() where SourceText.isFence(lines[index]) {
            return (header: Array(lines[1..<index]), body: Array(lines[(index + 1)...]))
        }

        // No closing fence: recover by reading to the end of the file so an obvious title is not lost.
        diagnostics.append(.warning(
            .unterminatedHeader,
            "Header is missing a closing fence.",
            at: map.range(from: first.startIndex, length: first.count)
        ))

        return (header: Array(lines.dropFirst()), body: [])
    }

    /// The typed accessors are views over the raw store, so reading the header is reading
    /// its entries; nothing else is accumulated alongside them.
    static func parse(_ lines: [Substring], map: SourceMap, diagnostics: inout [Diagnostic]) -> Metadata {
        Metadata(entries: entries(in: lines, map: map, diagnostics: &diagnostics))
    }

    private static func entries(
        in lines: [Substring],
        map: SourceMap,
        diagnostics: inout [Diagnostic]
    ) -> [Metadata.Entry] {
        var entries: [Metadata.Entry] = []
        var seenKeys: Set<String> = []

        for line in lines {
            // A blank line is insignificant layout, so it is dropped rather than preserved.
            if SourceText.isBlank(line) { continue }

            // A top-level entry has no leading whitespace and a `key: value` separator.
            // Anything else, including an indented nesting or block-list line from a later
            // version, is preserved verbatim and warned about rather than reshaped or dropped.
            let isIndented = line.first?.isWhitespace ?? false
            guard !isIndented, let field = self.entry(in: line) else {
                entries.append(Metadata.Entry(key: "", value: .raw(String(line))))
                diagnostics.append(.warning(
                    .malformedHeaderLine,
                    "Header line is not a 'key: value' entry.",
                    at: map.range(from: line.startIndex, length: line.count)
                ))
                continue
            }

            let keyRange = map.range(from: line.startIndex, length: field.key.count)
            let isList = listKeys.contains(field.key)

            entries.append(Metadata.Entry(
                key: field.key,
                value: isList ? .list(list(in: field.value)) : .scalar(field.value)
            ))

            // An unknown key is preserved and warned about, whether scalar or repeated.
            if !isList, !scalarKeys.contains(field.key) {
                diagnostics.append(.warning(
                    .unknownHeaderKey,
                    "Unrecognized header key '\(field.key)'.",
                    at: keyRange
                ))
            }

            // A repeated key keeps every occurrence; the last-wins accessors interpret the
            // latest. A list key repeat is distinguished so consumers can switch on it.
            if !seenKeys.insert(field.key).inserted {
                diagnostics.append(.warning(
                    isList ? .repeatedListKey : .repeatedScalarKey,
                    "Repeated header key '\(field.key)'.",
                    at: keyRange
                ))
            }
        }

        return entries
    }

    /// A key ends at the first colon followed by a space or the end of the line, so a
    /// colon inside a value such as a URL does not split it.
    private static func entry(in line: Substring) -> (key: String, value: String)? {
        let characters = Array(line)
        var cursor = 0

        while cursor < characters.count {
            if characters[cursor] == ":" {
                if cursor + 1 == characters.count {
                    return (String(characters[0..<cursor]), "")
                }
                if characters[cursor + 1] == " " {
                    return (String(characters[0..<cursor]), String(characters[(cursor + 2)...]))
                }
            }
            cursor += 1
        }

        return nil
    }

    /// Only a list-valued field reads `[...]` as a list; elsewhere the brackets are literal.
    /// A value that is not a well-formed inline list is one literal item, so `tags: italian`
    /// is the one-item list `italian`.
    static func list(in value: String) -> [String] {
        let trimmed = SourceText.trimmed(value)

        guard isInlineList(trimmed) else {
            return trimmed.isEmpty ? [] : [trimmed]
        }

        return items(in: trimmed.dropFirst().dropLast())
    }

    /// A well-formed inline list opens with `[` and closes on the first `]` that an escape
    /// does not produce, which must be the value's last character. Anything past that `]`
    /// leaves the value unclosed, so it reads as one literal item instead.
    private static func isInlineList(_ value: String) -> Bool {
        guard value.hasPrefix("[") else { return false }

        var escaping = false

        for index in value.indices.dropFirst() {
            if escaping {
                escaping = false
            } else if value[index] == "\\" {
                escaping = true
            } else if value[index] == "]" {
                return value.index(after: index) == value.endIndex
            }
        }

        return false
    }

    /// Splits the content between the brackets on its unescaped commas. Items are trimmed of
    /// surrounding whitespace, and an empty item, such as one left by a stray or trailing
    /// comma, is dropped.
    private static func items(in content: Substring) -> [String] {
        var items: [String] = []
        var item = ""
        var escaping = false

        func endItem() {
            let value = unescaped(SourceText.trimmed(item))
            if !value.isEmpty { items.append(value) }
            item = ""
        }

        for character in content {
            if escaping {
                escaping = false
            } else if character == "\\" {
                escaping = true
            } else if character == "," {
                endItem()
                continue
            }
            item.append(character)
        }

        endItem()

        return items
    }

    /// Resolves each escape in an inline-list item to the character it produces. A backslash
    /// before anything else is ordinary text, exactly as in the body.
    private static func unescaped(_ item: String) -> String {
        var result = ""
        var escaping = false

        for character in item {
            if escaping {
                if !SourceText.isEscapableInList(character) { result.append("\\") }
                escaping = false
            } else if character == "\\" {
                escaping = true
                continue
            }
            result.append(character)
        }

        if escaping { result.append("\\") }

        return result
    }
}
