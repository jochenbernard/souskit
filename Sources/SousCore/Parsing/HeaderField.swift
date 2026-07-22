// The header keys this version gives a meaning to, and how each reads its value.
//
// The reader, the typed accessors, and scaling all ask here, so a field is named once and a
// field a later version recognizes joins them in one edit.

enum HeaderField {
    static let title = "title"
    static let language = "language"
    static let version = "version"

    /// The number of portions the recipe makes. The key doubles as the unit of the portion
    /// yield it aliases.
    static let servings = "servings"

    static let tags = "tags"
    static let source = "source"
    static let yield = "yield"

    /// A list field reads `[...]` as a list and combines its repeats. Every other field keeps
    /// the brackets as part of the literal value.
    static let lists: Set<String> = [tags, yield]

    /// A scalar field reads its value as the one literal it states, the last occurrence winning.
    static let scalars: Set<String> = [title, language, version, servings, source]

    /// A scaling field states how much the recipe makes, so its value moves with the factor.
    static let scaling: Set<String> = [servings, yield]

    /// Whether this version gives the key a meaning. Everything else is preserved and reported
    /// as unknown.
    static func isRecognized(_ key: String) -> Bool {
        lists.contains(key) || scalars.contains(key)
    }
}
