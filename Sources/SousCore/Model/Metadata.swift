/// A recipe's metadata header: typed accessors over an ordered raw store.
public struct Metadata: Equatable, Hashable, Sendable {
    /// A single raw header entry.
    public struct Entry: Equatable, Hashable, Sendable {
        /// The value of a header entry: a scalar or a list.
        public enum Value: Equatable, Hashable, Sendable {
            /// A single literal value.
            case scalar(String)

            /// An inline list of literal values.
            case list([String])
        }

        /// The entry's key.
        public var key: String

        /// The entry's value.
        public var value: Value
    }

    /// The `title` field, the recipe's name.
    public var title: String?

    /// The `language` field, a short content-language code.
    public var language: String?

    /// The `version` field, the language version the file targets.
    public var version: String?

    /// The `servings` field, the number of portions the recipe makes.
    public var servings: Int?

    /// The `tags` field, a list of free-form labels.
    public var tags: [String]

    /// The `source` field, where the recipe came from.
    public var source: String?

    /// Every header entry in document order, including unrecognized keys and repeats.
    public var entries: [Entry]

    /// The last scalar value written for the given key, or `nil` when the key is absent.
    public subscript(key: String) -> String? {
        entries.lastScalar(key)
    }
}

// The single last-wins lookup over the raw store, shared by the subscript and by the
// header reader that derives the typed accessors, so the two cannot drift apart.

extension [Metadata.Entry] {
    func lastScalar(_ key: String) -> String? {
        for entry in reversed() where entry.key == key {
            if case let .scalar(value) = entry.value { return value }
        }

        return nil
    }

    func lastList(_ key: String) -> [String] {
        for entry in reversed() where entry.key == key {
            if case let .list(items) = entry.value { return items }
        }

        return []
    }
}
