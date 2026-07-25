extension Diagnostic {
    /// A warning, which leaves the file usable.
    static func warning(
        _ kind: Kind,
        _ message: String,
        at range: SourceRange? = nil
    ) -> Diagnostic {
        Diagnostic(
            severity: .warning,
            message: message,
            range: range,
            kind: kind
        )
    }

    /// An error, which carries no range because validation reads a recipe rather than source
    /// text.
    static func error(_ kind: Kind, _ message: String) -> Diagnostic {
        Diagnostic(
            severity: .error,
            message: message,
            range: nil,
            kind: kind
        )
    }
}
