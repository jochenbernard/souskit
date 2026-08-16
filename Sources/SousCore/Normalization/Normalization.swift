import Foundation

/// Reduces a name to the form group headings and references are matched in.
public enum Normalization {
    /// The matching form of a name: lowercased, accent-folded, and trimmed.
    ///
    /// This is idempotent: normalizing an already normalized name returns it unchanged.
    ///
    /// - Parameter text: The name to reduce.
    /// - Returns: The matching form.
    public static func normalized(_ text: String) -> String {
        folded(SourceText.trimmed(folded(text.lowercased())))
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
}
