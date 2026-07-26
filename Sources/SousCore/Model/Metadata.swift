/// The metadata header of a recipe.
///
/// ``entries`` is the store. The named accessors are views onto it, so editing an entry moves
/// what they report.
public struct Metadata: Equatable, Hashable, Sendable {
    /// One line of the header.
    public struct Entry: Equatable, Hashable, Sendable {
        /// What an entry holds.
        public enum Value: Equatable, Hashable, Sendable {
            /// A single value, trimmed.
            case scalar(String)

            /// The items of a list-valued key.
            case list([String])

            /// A line that could not be read as `key: value`, preserved exactly as written,
            /// leading whitespace included. Its entry's ``Entry/key`` is empty.
            case raw(String)
        }

        /// The key, trimmed, or empty for a ``Value/raw(_:)`` entry.
        public var key: String

        /// What this entry holds.
        public var value: Value
    }

    /// Every header line, in document order, unrecognized and malformed lines included.
    public var entries: [Entry]

    /// The `title` value, or `nil` when the header omits it.
    public var title: String? {
        entries.lastScalar(HeaderField.title)
    }

    /// The `language` value, or `nil` when the header omits it.
    public var language: String? {
        entries.lastScalar(HeaderField.language)
    }

    /// The `version` value, or `nil` when the header omits it.
    public var version: String? {
        entries.lastScalar(HeaderField.version)
    }

    /// The leading number of the `servings` value, or `nil` when the header omits it or the
    /// value opens with no usable number.
    public var servings: Double? {
        entries.lastScalar(HeaderField.servings)
            .flatMap({ AmountParser.parse(unfenced: $0).kind.values.first })
    }

    /// The `yield` items, read as amounts, merged across every `yield` entry in document order.
    public var yields: [Amount] {
        entries.mergedList(HeaderField.yield).map({ AmountParser.parse(unfenced: $0) })
    }

    /// The `tags` items, merged across every `tags` entry in document order.
    public var tags: [String] {
        entries.mergedList(HeaderField.tags)
    }

    /// The `source` value, or `nil` when the header omits it.
    public var source: String? {
        entries.lastScalar(HeaderField.source)
    }

    /// The value of any scalar key, recognized or not.
    ///
    /// A repeated key reports its last occurrence, matching the named accessors.
    ///
    /// - Parameter key: The header key to look up.
    /// - Returns: The value, or `nil` when no scalar entry carries that key.
    public subscript(key: String) -> String? {
        entries.lastScalar(key)
    }
}

extension [Metadata.Entry] {
    /// The value of the last scalar entry carrying the given key.
    func lastScalar(_ key: String) -> String? {
        for entry in reversed() where entry.key == key {
            if case let .scalar(value) = entry.value { return value }
        }

        return nil
    }

    /// The items of every list entry carrying the given key, in document order.
    func mergedList(_ key: String) -> [String] {
        flatMap({ entry -> [String] in
            guard entry.key == key, case let .list(values) = entry.value else { return [] }

            return values
        })
    }
}
