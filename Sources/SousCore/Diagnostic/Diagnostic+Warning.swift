extension Diagnostic {
    /// Every problem the v0.2 reader can report is recoverable, so it is a warning.
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
}
