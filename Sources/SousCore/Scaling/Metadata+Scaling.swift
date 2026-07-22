extension Metadata {
    /// The header with every amount it states multiplied by a factor, so a scaled recipe still
    /// states what it makes.
    ///
    /// Only the two fields that state how much the recipe makes move. Everything else, an
    /// unknown key and a preserved line included, is carried through as written.
    func scaled(by factor: Double) -> Metadata {
        Metadata(entries: entries.map({ entry in
            switch (entry.key, entry.value) {
            case let (HeaderField.servings, .scalar(value)):
                Entry(key: entry.key, value: .scalar(Self.scaled(value, by: factor)))
            case let (HeaderField.yield, .list(items)):
                Entry(key: entry.key, value: .list(items.map({ Self.scaled($0, by: factor) })))
            default:
                entry
            }
        }))
    }

    /// A value stating an amount, multiplied by a factor. A value stating none, and one the
    /// factor leaves where it is, comes back exactly as written, whitespace and all.
    private static func scaled(_ value: String, by factor: Double) -> String {
        AmountParser.parse(SourceText.trimmed(value)).scaled(by: factor)?.text ?? value
    }
}
