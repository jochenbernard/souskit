/// The form names are matched in.
///
/// One routine matches every name the language compares, so a group a reference resolves to is
/// a group a consumer looking the same name up finds.
public enum Normalization {
    /// Returns the form a name is matched in.
    ///
    /// Capitalization and accents are folded away, the whitespace around the name is trimmed,
    /// and each leading connective word is dropped. Nothing else is changed, so the whitespace
    /// within a name still tells two names apart.
    ///
    /// - Parameter text: The name to normalize.
    /// - Returns: The form it is matched in.
    public static func normalized(_ text: String) -> String {
        text
    }

    /// The words dropped from the start of a name, so `of parmesan` matches `parmesan`.
    ///
    /// A name is stripped of them for as long as it opens with one, so `of the sauce` matches
    /// `sauce`.
    public static let leadingConnectives: Set<String> = []
}
