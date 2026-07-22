extension Diagnostic {
    /// A recoverable problem: the construct is preserved, the file stays usable, and only a
    /// request depending on it can fail. Every problem the reader reports is one of these.
    ///
    /// A problem the reader found carries the range of the text it was read from. One
    /// validation found carries none, because validation reads a recipe rather than the text it
    /// came from, and a recipe carries nothing that locates itself in that text.
    static func warning(
        _ kind: Kind,
        _ message: String,
        at range: SourceRange?
    ) -> Diagnostic {
        Diagnostic(
            severity: .warning,
            message: message,
            range: range,
            kind: kind
        )
    }

    /// A conditional requirement the file leaves unsatisfied, which leaves it well-formed but
    /// not valid. Only validation reports one, so it carries no range.
    static func error(_ kind: Kind, _ message: String) -> Diagnostic {
        Diagnostic(
            severity: .error,
            message: message,
            range: nil,
            kind: kind
        )
    }
}
