/// A recipe's metadata header: typed accessors over an ordered raw store.
public struct Metadata: Equatable, Hashable, Sendable {
    /// A single raw header entry.
    public struct Entry: Equatable, Hashable, Sendable {
        /// The value of a header entry: a scalar, a list, or a verbatim line.
        ///
        /// Which case a key takes is the field's, not the value's: a list field always reads a
        /// list and every other key a scalar. Setting the other case leaves the typed accessor
        /// reading nothing while the entry still writes what it holds, so the header no longer
        /// reads back as itself.
        public enum Value: Equatable, Hashable, Sendable {
            /// A single literal value.
            case scalar(String)

            /// An inline list of literal values, each with its escapes resolved.
            case list([String])

            /// A header line that is not a top-level `key: value` entry, preserved verbatim.
            case raw(String)
        }

        /// The entry's key. A preserved line has no key of its own, so it is empty for every
        /// `raw` value, as it is for a line that opens with the separator.
        public var key: String

        /// The entry's value.
        public var value: Value
    }

    /// Every header entry in document order, including unrecognized keys and repeats.
    ///
    /// The entries are the store the typed accessors read, so editing them moves the accessors with them.
    public var entries: [Entry]

    /// The `title` field, the recipe's name.
    public var title: String? {
        entries.lastScalar(HeaderField.title)
    }

    /// The `language` field, a short content-language code.
    public var language: String? {
        entries.lastScalar(HeaderField.language)
    }

    /// The `version` field, the language version the file targets.
    public var version: String? {
        entries.lastScalar(HeaderField.version)
    }

    /// The `servings` field, the number of portions the recipe makes.
    ///
    /// It is read as the value's leading numeric quantity, or `nil` when the value has no leading number.
    public var servings: Double? {
        entries.lastScalar(HeaderField.servings)
            .flatMap({ AmountParser.parse(unfenced: $0).kind.values.first })
    }

    /// The `yield` field, the amounts the recipe makes.
    ///
    /// Repeated `yield` entries combine, their amounts appended in document order. A `servings`
    /// value states a portion yield through ``servings`` and is not listed here.
    public var yields: [Amount] {
        entries.mergedList(HeaderField.yield).map({ AmountParser.parse(unfenced: $0) })
    }

    /// The `tags` field, a list of free-form labels.
    ///
    /// Repeated `tags` entries combine, their items appended in document order.
    public var tags: [String] {
        entries.mergedList(HeaderField.tags)
    }

    /// The `source` field, where the recipe came from.
    public var source: String? {
        entries.lastScalar(HeaderField.source)
    }

    /// The last scalar value written for the given key, or `nil` when the key holds no scalar value.
    public subscript(key: String) -> String? {
        entries.lastScalar(key)
    }
}

// The lookups every typed accessor and the subscript are built from, so no reading of the
// raw store is written twice.

extension [Metadata.Entry] {
    func lastScalar(_ key: String) -> String? {
        for entry in reversed() where entry.key == key {
            if case let .scalar(value) = entry.value { return value }
        }

        return nil
    }

    /// A repeated list key accumulates: the items of every occurrence are concatenated in
    /// document order, rather than the last occurrence overwriting the earlier ones.
    func mergedList(_ key: String) -> [String] {
        var items: [String] = []
        for entry in self where entry.key == key {
            if case let .list(values) = entry.value { items += values }
        }

        return items
    }
}
