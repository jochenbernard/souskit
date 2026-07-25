// Splits a recipe into its optional metadata header and its body, and reads the header
// into typed accessors over an ordered raw store.
//
// Values are literal text with no type coercion. Which keys are recognized, and which of them
// read a list, comes from the shared field table. Everything else is preserved and warned
// about, never dropped.

enum HeaderParser {
    static func split(
        _ lines: [Substring],
        map: SourceMap,
        diagnostics: inout [Diagnostic]
    ) -> (header: [Substring], body: [Substring]) {
        guard let first = lines.first, SourceText.isFence(first) else {
            return (header: [], body: lines)
        }

        if let closing = lines.dropFirst().firstIndex(where: SourceText.isFence) {
            return (header: Array(lines[1..<closing]), body: Array(lines[(closing + 1)...]))
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
            guard let read = entry(from: line, map: map, seenKeys: &seenKeys) else { continue }

            entries.append(read.entry)
            diagnostics.append(contentsOf: read.diagnostics)
        }

        return entries
    }

    /// One header line read into its entry and the diagnostics it earns, or `nil` for a blank
    /// line, which is insignificant layout and dropped rather than preserved.
    ///
    /// A top-level entry has no leading whitespace and a `key: value` separator. Anything else,
    /// including an indented nesting or block-list line from a later version, is preserved
    /// verbatim and warned about rather than reshaped or dropped.
    private static func entry(
        from line: Substring,
        map: SourceMap,
        seenKeys: inout Set<String>
    ) -> (entry: Metadata.Entry, diagnostics: [Diagnostic])? {
        if SourceText.isBlank(line) { return nil }

        let isIndented = line.first?.isWhitespace ?? false
        guard !isIndented, let field = field(in: line) else {
            let diagnostic = Diagnostic.warning(
                .malformedHeaderLine,
                "Header line is not a top-level 'key: value' entry.",
                at: map.range(from: line.startIndex, length: line.count)
            )

            return (Metadata.Entry(key: "", value: .raw(String(line))), [diagnostic])
        }

        let keyRange = map.range(from: line.startIndex, length: field.key.count)
        let isList = HeaderField.lists.contains(field.key)
        var diagnostics: [Diagnostic] = []

        // An unknown key is preserved and warned about, whether scalar or repeated.
        if !HeaderField.isRecognized(field.key) {
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

        let value: Metadata.Entry.Value = isList ? .list(list(in: field.value)) : .scalar(field.value)
        diagnostics += malformedQuantities(
            of: value,
            under: field.key,
            at: map.range(from: valueStart(of: field.value, in: line), length: field.value.count)
        )

        return (Metadata.Entry(key: field.key, value: value), diagnostics)
    }

    /// Where a value stands in its line, which is at the line's end, the key and the whitespace
    /// separating the two standing before it.
    private static func valueStart(of value: String, in line: Substring) -> Substring.Index {
        line.index(line.endIndex, offsetBy: -value.count)
    }

    /// Reports each amount an amount-valued field states as a number it cannot finish. Every
    /// other field states literal text, which states no number to report.
    private static func malformedQuantities(
        of value: Metadata.Entry.Value,
        under key: String,
        at range: SourceRange?
    ) -> [Diagnostic] {
        guard HeaderField.amounts.contains(key) else { return [] }

        // A fence gives a leading `=` its meaning, and a header value has no fence, so the
        // marker is ordinary text here and states no amount to report.
        return amounts(of: value).compactMap({ AmountParser.defect(in: $0, fenced: false) })
            .map({ Diagnostic.warning(.malformedQuantity, $0.message, at: range) })
    }

    /// The amounts a value states: the one a scalar holds, or each item of a list. A preserved
    /// line states no entry, so it states no amount either.
    private static func amounts(of value: Metadata.Entry.Value) -> [String] {
        switch value {
        case let .scalar(text): [text]
        case let .list(items): items
        case .raw: []
        }
    }

    /// A key ends at the first colon followed by whitespace or the end of the line, so a
    /// colon inside a value such as a URL does not split it. The whitespace separating the
    /// two belongs to neither, so any run of it states the separation.
    private static func field(in line: Substring) -> (key: String, value: String)? {
        for colon in line.indices where line[colon] == ":" {
            let afterColon = line.index(after: colon)
            let key = String(line[..<colon])

            if afterColon == line.endIndex { return (key, "") }
            if line[afterColon].isWhitespace {
                return (key, String(line[afterColon...].drop(while: \.isWhitespace)))
            }
        }

        return nil
    }

    /// Only a list-valued field reads `[...]` as a list; elsewhere the brackets are literal.
    /// A value that is not a well-formed inline list is one literal item, so `tags: italian`
    /// is the one-item list `italian`.
    private static func list(in value: String) -> [String] {
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

        let scanned = SourceText.escapeScanned(value)
        guard let closing = scanned.firstIndex(where: { $0.character == "]" && !$0.isEscaped }) else {
            return false
        }

        return closing == scanned.count - 1
    }

    /// Splits the content between the brackets on its unescaped commas. Items are trimmed of
    /// surrounding whitespace, and an empty item, such as one left by a stray or trailing
    /// comma, is dropped.
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
