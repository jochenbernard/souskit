extension Diagnostic {
    /// Every problem the v0.1 reader can report is recoverable, so it is a warning.
    static func warning(
        _ kind: Kind,
        _ message: String
    ) -> Diagnostic {
        Diagnostic(
            severity: .warning,
            message: message,
            range: nil,
            kind: kind
        )
    }
}
