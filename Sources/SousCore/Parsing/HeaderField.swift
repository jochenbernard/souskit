/// The header keys this version recognizes, and how each is read.
enum HeaderField {
    // Ordered by how each value is read: as text, then as an amount, then as a list.
    static let title = "title"
    static let language = "language"
    static let version = "version"
    static let source = "source"
    static let servings = "servings"
    static let yield = "yield"
    static let tags = "tags"

    /// Keys a scaling target can be divided by.
    static let scaling: Set<String> = [servings, yield]

    /// Keys whose value is read as an amount, so a malformed quantity is reported.
    static let amounts = scaling

    /// Keys whose value is read as a list, and whose repeats merge.
    static let lists: Set<String> = [yield, tags]
}
