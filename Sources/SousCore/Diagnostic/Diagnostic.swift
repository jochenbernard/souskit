/// A problem reported during parsing or validation.
public struct Diagnostic: Equatable, Hashable, Sendable {
    /// How serious a diagnostic is.
    public enum Severity: Equatable, Hashable, Sendable {
        /// The problem leaves the file well-formed but not valid. No rule this version has
        /// reports one, so every diagnostic it produces is a warning.
        case error

        /// The problem leaves the file usable, with the flagged construct preserved.
        case warning
    }

    /// The category of a diagnostic.
    public enum Kind: Equatable, Hashable, Sendable {
        /// An inline span or amount fence was left unclosed.
        case unclosedSpan

        /// The metadata header had no closing fence.
        case unterminatedHeader

        /// The metadata header used an unrecognized key.
        case unknownHeaderKey

        /// The metadata header repeated a scalar key.
        case repeatedScalarKey

        /// The metadata header repeated a list key.
        case repeatedListKey

        /// The metadata header had a line that is not a top-level `key: value` entry.
        case malformedHeaderLine

        /// An annotation carried a flag name that is not recognized.
        case unknownFlag

        /// The metadata header stated a yield in one unit more than once, counting a
        /// `servings` value as a yield in `servings`.
        ///
        /// The values need not disagree: a unit states how much the recipe makes, so stating
        /// one more than once is the report whatever the two values are.
        case repeatedYield
    }

    /// The diagnostic's severity.
    public var severity: Severity

    /// A human-readable description of the problem.
    public var message: String

    /// The source range the diagnostic refers to, when available.
    public var range: SourceRange?

    /// The category of this diagnostic, so consumers can switch on it rather than match the message.
    public var kind: Kind
}
