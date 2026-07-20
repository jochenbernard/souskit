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

    /// The typed accessors are views over the raw store, so they are derived from the
    /// entries rather than accumulated alongside them.
    static func parse(_ lines: [Substring], map: SourceMap, diagnostics: inout [Diagnostic]) -> Metadata {
        let entries = self.entries(in: lines, map: map, diagnostics: &diagnostics)

        return Metadata(
            title: entries.lastScalar("title"),
            language: entries.lastScalar("language"),
            version: entries.lastScalar("version"),
            servings: entries.lastScalar("servings").flatMap({ Int(SourceText.trimmed($0)) }),
            tags: entries.mergedList("tags"),
            source: entries.lastScalar("source"),
            entries: entries
        )
    }

    private static func entries(
        in lines: [Substring],
        map: SourceMap,
        diagnostics: inout [Diagnostic]
    ) -> [Metadata.Entry] {
        var entries: [Metadata.Entry] = []
        var seenKeys: Set<String> = []

        for line in lines {
            guard let entry = self.entry(in: line) else { continue }
            let keyRange = map.range(from: line.startIndex, length: entry.key.count)
            let isList = listKeys.contains(entry.key)

            entries.append(Metadata.Entry(
                key: entry.key,
                value: isList ? .list(list(in: entry.value)) : .scalar(entry.value)
            ))

            // An unknown key is preserved and warned about, whether scalar or repeated.
            if !isList, !scalarKeys.contains(entry.key) {
                diagnostics.append(.warning(
                    .unknownHeaderKey,
                    "Unrecognized header key '\(entry.key)'.",
                    at: keyRange
                ))
            }

            // A repeated key keeps every occurrence; the last-wins accessors interpret the
            // latest. A list key repeat is distinguished so consumers can switch on it.
            if !seenKeys.insert(entry.key).inserted {
                diagnostics.append(.warning(
                    isList ? .repeatedListKey : .repeatedScalarKey,
                    "Repeated header key '\(entry.key)'.",
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
    /// Items are trimmed of surrounding whitespace, and an empty item, such as one left by
    /// a stray or trailing comma, is dropped.
    private static func list(in value: String) -> [String] {
        guard value.hasPrefix("["), value.hasSuffix("]") else {
            return value.isEmpty ? [] : [value]
        }

        let inner = value.dropFirst().dropLast()
        guard !SourceText.trimmed(inner).isEmpty else { return [] }

        return inner
            .split(separator: ",", omittingEmptySubsequences: false)
            .map(SourceText.trimmed)
            .filter({ !$0.isEmpty })
    }
}
