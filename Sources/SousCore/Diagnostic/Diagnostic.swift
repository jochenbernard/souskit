/// A problem reported while parsing or validating a recipe.
public struct Diagnostic: Equatable, Hashable, Sendable {
    /// How serious a diagnostic is.
    public enum Severity: Equatable, Hashable, Sendable {
        /// The problem covers the whole recipe, so what parsed is not what the file describes.
        case error

        /// The problem covers one construct, which is preserved, and the rest reads as written.
        case warning
    }

    /// What a diagnostic is about.
    public enum Kind: Equatable, Hashable, Sendable {
        // Ordered as a recipe reads: the header, then its group headings, then its steps.

        /// The metadata header had no closing fence.
        case unterminatedHeader

        /// A header line was not a top-level `key: value` entry.
        case malformedHeaderLine

        /// A header line gave a value under no key.
        case emptyHeaderKey

        /// A scalar header key appeared more than once; the last occurrence is read.
        case repeatedScalarKey

        /// A list header key appeared more than once; the occurrences merge.
        case repeatedListKey

        /// The header declared more than one yield in the same unit.
        case repeatedYield

        /// The header declared a yield of zero, which can divide no target.
        case zeroYield

        /// More than one group heading carries the same name.
        case repeatedGroupName

        /// An annotation span or amount fence was left unclosed.
        case unclosedSpan

        /// An amount opened as a number it could not finish.
        case malformedQuantity

        /// An annotation gave an amount but no name.
        case unnamedAnnotation

        /// A reference matches no group.
        case unresolvedReference

        /// Groups consume each other in a loop, or a group consumes itself.
        case referenceCycle

        /// How serious this kind is.
        public var severity: Severity {
            switch self {
            case .unterminatedHeader:
                .error
            case .malformedHeaderLine, .emptyHeaderKey, .repeatedScalarKey, .repeatedListKey,
                .repeatedYield, .zeroYield, .repeatedGroupName, .unclosedSpan, .malformedQuantity,
                .unnamedAnnotation, .unresolvedReference, .referenceCycle:
                .warning
            }
        }
    }

    /// The message describing the problem.
    public var message: String

    /// Where the problem is, or `nil` when it has no single place in the source.
    ///
    /// Validation reads a recipe rather than source text, so every diagnostic it produces has no
    /// range.
    public var range: SourceRange?

    /// What this diagnostic is about.
    public var kind: Kind

    /// How serious this diagnostic is.
    public var severity: Severity {
        kind.severity
    }

    /// Creates a diagnostic of the given kind.
    init(
        _ kind: Kind,
        _ message: String,
        at range: SourceRange? = nil
    ) {
        self.kind = kind
        self.message = message
        self.range = range
    }
}
