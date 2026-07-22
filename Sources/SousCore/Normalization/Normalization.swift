import Foundation

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
        // Folding is what strips a diacritic, whether the name carries it as one character or
        // as a letter and a combining mark, so the two forms of a letter match each other.
        var name = SourceText.trimmed(text.lowercased().folding(options: .diacriticInsensitive, locale: nil))

        while let stripped = withoutLeadingConnective(name) {
            name = stripped
        }

        return name
    }

    /// The words dropped from the start of a name, so `of parmesan` matches `parmesan`.
    ///
    /// A name is stripped of them for as long as it opens with one, so `of the sauce` matches
    /// `sauce`.
    public static let leadingConnectives: Set<String> = ["a", "an", "of", "the"]

    /// The name without the connective it opens with, or `nil` when it opens with none.
    ///
    /// A connective is a whole word, so the name opens with one only while whitespace or the
    /// end of the name follows it, which is what leaves `office` whole.
    private static func withoutLeadingConnective(_ name: String) -> String? {
        guard let end = name.firstIndex(where: \.isWhitespace) else {
            return leadingConnectives.contains(name) ? "" : nil
        }
        guard leadingConnectives.contains(String(name[..<end])) else { return nil }

        return String(name[end...].drop(while: \.isWhitespace))
    }
}
