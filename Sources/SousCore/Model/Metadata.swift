/// A recipe's metadata header: typed accessors over an ordered raw store.
public struct Metadata: Equatable, Hashable, Sendable {
    /// A single raw header entry.
    public struct Entry: Equatable, Hashable, Sendable {
        /// The value of a header entry: a scalar, a list, or a verbatim line.
        public enum Value: Equatable, Hashable, Sendable {
            /// A single literal value.
            case scalar(String)

            /// An inline list of literal values.
            case list([String])

            /// A header line that is not a recognized `key: value` entry, preserved verbatim.
            case raw(String)
        }

        /// The entry's key.
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
        entries.lastScalar("title")
    }

    /// The `language` field, a short content-language code.
    public var language: String? {
        entries.lastScalar("language")
    }

    /// The `version` field, the language version the file targets.
    public var version: String? {
        entries.lastScalar("version")
    }

    /// The `servings` field, the number of portions the recipe makes.
    ///
    /// It is read as the value's leading numeric quantity, or `nil` when the value has no leading number.
    public var servings: Double? {
        entries.lastScalar("servings").flatMap({ AmountParser.leadingValue(in: SourceText.trimmed($0)) })
    }

    /// The `tags` field, a list of free-form labels.
    public var tags: [String] {
        entries.mergedList("tags")
    }

    /// The `source` field, where the recipe came from.
    public var source: String? {
        entries.lastScalar("source")
    }

    /// The last scalar value written for the given key, or `nil` when the key is absent.
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
