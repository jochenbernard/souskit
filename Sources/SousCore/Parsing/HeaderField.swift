// The header keys this version gives a meaning to, and how each reads its value.
//
// The reader, the typed accessors, and scaling all ask here, so a field is named once and a
// field a later version recognizes joins them in one edit.

enum HeaderField {
    static let title = "title"
    static let language = "language"
    static let version = "version"

    /// The number of portions the recipe makes. The key is also the unit of the portion yield
    /// it is an alias for, which is what makes it one.
    static let servings = "servings"

    static let tags = "tags"
    static let source = "source"
    static let yield = "yield"

    /// A list field reads `[...]` as a list and combines its repeats. Every other field keeps
    /// the brackets as part of the literal value.
    static let lists: Set<String> = [tags, yield]

    /// A scalar field reads its value as the one literal it states, the last occurrence winning.
    static let scalars: Set<String> = [title, language, version, servings, source]
}
