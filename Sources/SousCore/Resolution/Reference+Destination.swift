extension Reference {
    /// What a reference consumes: a group of the same recipe, or another recipe file.
    public enum Destination: Equatable, Hashable, Sendable {
        /// A group of the recipe holding the reference.
        case group(StepGroup)

        /// The recipe file at a path relative to the referencing file's folder, written without its extension.
        ///
        /// Leading `./` segments are dropped; the rest of the path is kept as written, `..` included.
        case file(String)
    }
}
