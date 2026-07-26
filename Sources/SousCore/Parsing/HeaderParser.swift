/// Splits the metadata header from the body and reads its entries.
enum HeaderParser {
    /// Splits the source into header lines and body lines.
    ///
    /// The header opens on the first non-blank line when that line is a `---` fence, so a recipe
    /// may begin with blank lines. A header that never closes takes the rest of the file and is
    /// warned about, leaving no body.
    static func split(
        _ lines: [Substring],
        map: SourceMap,
        diagnostics: inout [Diagnostic]
    ) -> (header: [Substring], body: [Substring]) {
        guard let opening = lines.firstIndex(where: { !SourceText.isBlank($0) }),
              SourceText.isFence(lines[opening])
        else { return (header: [], body: lines) }

        if let closing = lines[(opening + 1)...].firstIndex(where: SourceText.isFence) {
            return (header: Array(lines[(opening + 1)..<closing]), body: Array(lines[(closing + 1)...]))
        }

        diagnostics.append(Diagnostic(
            .unterminatedHeader,
            "Header is missing a closing fence.",
            at: map.range(from: lines[opening].startIndex, length: lines[opening].count)
        ))

        return (header: Array(lines[(opening + 1)...]), body: [])
    }

    /// The metadata the header lines describe.
    static func parse(
        _ lines: [Substring],
        map: SourceMap,
        diagnostics: inout [Diagnostic]
    ) -> Metadata {
        Metadata(entries: entries(
            in: lines,
            map: map,
            diagnostics: &diagnostics
        ))
    }

    /// One entry per non-blank header line, in document order.
    private static func entries(
        in lines: [Substring],
        map: SourceMap,
        diagnostics: inout [Diagnostic]
    ) -> [Metadata.Entry] {
        var entries: [Metadata.Entry] = []
        var seenKeys: Set<String> = []

        for line in lines {
            guard let read = entry(
                from: line,
                map: map,
                seenKeys: &seenKeys
            ) else { continue }

            entries.append(read.entry)
            diagnostics.append(contentsOf: read.diagnostics)
        }

        return entries
    }

    /// The entry a header line describes, or `nil` when the line is blank.
    ///
    /// An indented line, or one with no `key: value`, is preserved verbatim under an empty key so
    /// nothing is lost, and is warned about. An unrecognized or repeated key is warned about and
    /// kept.
    private static func entry(
        from line: Substring,
        map: SourceMap,
        seenKeys: inout Set<String>
    ) -> (entry: Metadata.Entry, diagnostics: [Diagnostic])? {
        if SourceText.isBlank(line) { return nil }

        let isIndented = line.first?.isWhitespace ?? false
        guard !isIndented, let field = field(in: line) else {
            let diagnostic = Diagnostic(
                .malformedHeaderLine,
                "Header line is not a top-level 'key: value' entry.",
                at: map.range(from: line.startIndex, length: line.count)
            )

            return (Metadata.Entry(key: "", value: .raw(String(line))), [diagnostic])
        }

        let keyRange = map.range(from: line.startIndex, length: max(field.key.count, 1))
        let isList = HeaderField.lists.contains(field.key)
        var diagnostics: [Diagnostic] = []

        if field.key.isEmpty {
            diagnostics.append(Diagnostic(
                .emptyHeaderKey,
                "Header line has a value but no key.",
                at: keyRange
            ))
        }

        if !seenKeys.insert(field.key).inserted {
            diagnostics.append(Diagnostic(
                isList ? .repeatedListKey : .repeatedScalarKey,
                "Repeated header key '\(field.key)'.",
                at: keyRange
            ))
        }

        let value: Metadata.Entry.Value = isList ? .list(list(in: field.value)) : .scalar(field.value)
        diagnostics += malformedQuantities(
            of: value,
            under: field.key,
            at: map.range(from: valueStart(of: field.value, in: line), length: field.value.count)
        )

        return (Metadata.Entry(key: field.key, value: value), diagnostics)
    }

    /// The index the trimmed value begins at within its line.
    private static func valueStart(of value: String, in line: Substring) -> Substring.Index {
        line.index(line.endIndex, offsetBy: -value.count)
    }

    /// Warnings for any defective quantity under a key read as an amount.
    private static func malformedQuantities(
        of value: Metadata.Entry.Value,
        under key: String,
        at range: SourceRange?
    ) -> [Diagnostic] {
        guard HeaderField.amounts.contains(key) else { return [] }

        return amounts(of: value).compactMap({ AmountParser.defect(in: $0, fenced: false) })
            .map({ defect in
                Diagnostic(
                    .malformedQuantity,
                    defect.message,
                    at: range
                )
            })
    }

    /// The texts to read as amounts for a value.
    private static func amounts(of value: Metadata.Entry.Value) -> [String] {
        switch value {
        case let .scalar(text): [text]
        case let .list(items): items
        case .raw: []
        }
    }

    /// The key and value a line describes, split on the first colon followed by whitespace or
    /// ending the line.
    ///
    /// A colon inside a value, as in a URL, does not split the line, because the colon that
    /// splits must be followed by whitespace.
    private static func field(in line: Substring) -> (key: String, value: String)? {
        for colon in line.indices where line[colon] == ":" {
            let afterColon = line.index(after: colon)
            let key = SourceText.trimmed(String(line[..<colon]))

            if afterColon == line.endIndex { return (key, "") }
            if line[afterColon].isWhitespace {
                return (key, SourceText.trimmed(String(line[afterColon...])))
            }
        }

        return nil
    }

    /// The items of a list value: an inline `[a, b]` list, or the whole value as one item.
    private static func list(in value: String) -> [String] {
        let trimmed = SourceText.trimmed(value)

        guard isInlineList(trimmed) else {
            return trimmed.isEmpty ? [] : [trimmed]
        }

        return items(in: trimmed.dropFirst().dropLast())
    }

    /// Whether the value is a well-formed inline list: bracketed, with the closing bracket last
    /// and unescaped.
    private static func isInlineList(_ value: String) -> Bool {
        guard value.hasPrefix("[") else { return false }

        let scanned = SourceText.escapeScanned(value)
        guard let closing = scanned.firstIndex(where: { $0.character == "]" && !$0.isEscaped }) else {
            return false
        }

        return closing == scanned.count - 1
    }

    /// The items between an inline list's brackets, split on unescaped commas and trimmed.
    /// Empty items are dropped.
    private static func items(in content: Substring) -> [String] {
        var items: [String] = []
        var item = ""

        func endItem() {
            let value = SourceText.unescaped(SourceText.trimmed(item), escaping: SourceText.isEscapableInList)
            if !value.isEmpty { items.append(value) }
            item = ""
        }

        for (character, isEscaped) in SourceText.escapeScanned(content) {
            if character == ",", !isEscaped {
                endItem()
            } else {
                item.append(character)
            }
        }

        endItem()

        return items
    }
}
