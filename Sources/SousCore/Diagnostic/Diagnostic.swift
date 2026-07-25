/// A problem reported while parsing or validating a recipe.
public struct Diagnostic: Equatable, Hashable, Sendable {
    /// How serious a diagnostic is.
    public enum Severity: Equatable, Hashable, Sendable {
        /// The file is well-formed but not valid.
        case error

        /// The file stays usable, with the flagged construct preserved.
        case warning
    }

    /// What a diagnostic is about.
    public enum Kind: Equatable, Hashable, Sendable {
        /// An annotation span or amount fence was left unclosed.
        case unclosedSpan

        /// The metadata header had no closing fence.
        case unterminatedHeader

        /// The header used a key this version does not read.
        case unknownHeaderKey

        /// A header line gave a value under no key.
        case emptyHeaderKey

        /// A scalar header key appeared more than once; the last occurrence is read.
        case repeatedScalarKey

        /// A list header key appeared more than once; the occurrences merge.
        case repeatedListKey

        /// A header line was not a top-level `key: value` entry.
        case malformedHeaderLine

        /// An annotation carried a flag this version does not read.
        case unknownFlag

        /// An amount opened as a number it could not finish.
        case malformedQuantity

        /// An annotation gave an amount but no name.
        case unnamedAnnotation

        /// The header declared a yield of zero, which can divide no target.
        case zeroYield

        /// The header declared more than one yield in the same unit.
        case repeatedYield

        /// Two group headings carry the same name.
        case repeatedGroupName

        /// A reference matches no group.
        case unresolvedReference

        /// Groups consume each other in a loop.
        case referenceCycle
    }

    /// How serious this diagnostic is.
    public var severity: Severity

    /// The message describing the problem.
    public var message: String

    /// Where the problem is, or `nil` when it has no single place in the source.
    ///
    /// Validation reads a recipe rather than source text, so every diagnostic it produces has no
    /// range.
    public var range: SourceRange?

    /// What this diagnostic is about.
    public var kind: Kind
}
