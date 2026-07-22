extension Diagnostic {
    /// Every problem this version reports is recoverable, so it is a warning: the construct is
    /// preserved, the file stays usable, and only a request depending on it can fail.
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
}
