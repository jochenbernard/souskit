import Foundation

/// The form names are matched in.
///
/// One routine matches every name the language resolves by identity, so a group a reference
/// resolves to is a group a consumer looking the same name up finds. It governs group names and
/// reference targets. A flag name and a header key are matched as written instead, and the unit
/// a yield states with the whitespace around it ignored and nothing else.
public enum Normalization {
    /// Returns the form a name is matched in.
    ///
    /// Capitalization and accents are folded away, the whitespace around the name is trimmed,
    /// and each leading connective word is dropped along with the whitespace after it. Nothing
    /// else is changed, so the whitespace within the rest of a name still tells two names apart.
    ///
    /// - Parameter text: The name to normalize.
    /// - Returns: The form it is matched in.
    public static func normalized(_ text: String) -> String {
        // Folding is what strips a diacritic, whether the name carries it as one character or
        // as a letter and a combining mark, so the two forms of a letter match each other. It
        // comes first, so a connective is recognized whatever accent it carries, and again
        // last, because dropping the whitespace and the connectives before it changes what
        // leads a mark, and a mark folds by what leads it.
        var name = SourceText.trimmed(folded(text.lowercased()))

        while let stripped = withoutLeadingConnective(name) {
            name = stripped
        }

        return folded(name)
    }

    /// The text with its diacritics folded away, to a fixed point.
    ///
    /// One fold drops one combining mark from a run no base letter absorbs, so a name carrying
    /// several is folded until folding changes nothing.
    private static func folded(_ text: String) -> String {
        var current = text

        while true {
            let next = current.folding(options: .diacriticInsensitive, locale: nil)
            guard next != current else { return current }

            current = next
        }
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
