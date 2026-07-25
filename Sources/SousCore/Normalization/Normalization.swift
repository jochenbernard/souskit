import Foundation

/// Reduces a name to the form group headings and references are matched in.
public enum Normalization {
    /// The matching form of a name: lowercased, accent-folded, trimmed, and stripped of leading
    /// connectives.
    ///
    /// Connectives are stripped repeatedly, so `the of sauce` and `sauce` match. A name of
    /// nothing but connectives keeps them, so `the` and `a` stay distinct rather than both
    /// reducing to nothing.
    ///
    /// This is idempotent: normalizing an already normalized name returns it unchanged.
    ///
    /// - Parameter text: The name to reduce.
    /// - Returns: The matching form.
    public static func normalized(_ text: String) -> String {
        let name = SourceText.trimmed(folded(text.lowercased()))
        var opened = name

        while let stripped = withoutLeadingConnective(opened) {
            opened = stripped
        }

        return folded(opened.isEmpty ? name : opened)
    }

    // Folds to a fixed point: Foundation removes one combining mark per pass.
    private static func folded(_ text: String) -> String {
        var current = text

        while true {
            let next = current.folding(options: .diacriticInsensitive, locale: nil)
            guard next != current else { return current }

            current = next
        }
    }

    /// The words dropped from the front of a name before matching.
    public static let leadingConnectives: Set<String> = ["a", "an", "of", "the"]

    /// The name without one leading connective, or `nil` when it opens with none.
    private static func withoutLeadingConnective(_ name: String) -> String? {
        guard let end = name.firstIndex(where: \.isWhitespace) else {
            return leadingConnectives.contains(name) ? "" : nil
        }
        guard leadingConnectives.contains(String(name[..<end])) else { return nil }

        return String(name[end...].drop(while: \.isWhitespace))
    }
}
