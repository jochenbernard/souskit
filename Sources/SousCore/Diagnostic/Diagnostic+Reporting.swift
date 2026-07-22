extension Diagnostic {
    /// Every problem the reader can report is recoverable, so it is a warning.
    static func warning(
        _ kind: Kind,
        _ message: String,
        at range: SourceRange
    ) -> Diagnostic {
        Diagnostic(
            severity: .warning,
            message: message,
            range: range,
            kind: kind
        )
    }

    /// A conditional requirement a recipe fails leaves it well-formed but not valid, so it is
    /// an error.
    ///
    /// It points at no range: validation reads a recipe rather than the text it came from, and
    /// a recipe carries nothing that locates itself in that text.
    static func error(_ kind: Kind, _ message: String) -> Diagnostic {
        Diagnostic(
            severity: .error,
            message: message,
            range: nil,
            kind: kind
        )
    }
}
