/// The header keys this version recognizes, and how each is read.
enum HeaderField {
    static let title = "title"
    static let language = "language"
    static let version = "version"

    static let servings = "servings"

    static let tags = "tags"
    static let source = "source"
    static let yield = "yield"

    /// Keys whose value is read as a list, and whose repeats merge.
    static let lists: Set<String> = [tags, yield]

    /// Keys whose value is read as literal text, and whose repeats keep the last.
    static let scalars: Set<String> = [title, language, version, servings, source]

    /// Keys a scaling target can be divided by.
    static let scaling: Set<String> = [servings, yield]

    /// Keys whose value is read as an amount, so a malformed quantity is reported.
    static let amounts = scaling
}
