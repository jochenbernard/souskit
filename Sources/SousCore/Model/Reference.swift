/// A reference annotated in a step with the `>...>` sigils, consuming what a group produced.
public struct Reference: Equatable, Hashable, Sendable {
    /// What the reference consumes, captured trimmed of the whitespace around it and with each
    /// escape resolved.
    ///
    /// It names a group of the same file, matched normalized, so `bechamel` consumes what a
    /// group named `Bechamel` produced.
    ///
    /// Writing wraps the target in its sigils, so a target that is empty or that holds a line
    /// break writes text a reader takes for prose rather than for a reference, and reading
    /// produces neither. A target opening with whitespace writes such text too, unless an
    /// amount fence stands between it and the opening sigil. Where the text does bound a
    /// target, reading trims the whitespace around it away.
    public var target: String

    /// The portion of the intermediate the reference consumes, or `nil` when no amount fence is
    /// present, which consumes the whole of it.
    public var amount: Amount?

    /// The flags attached after the reference's closing sigil.
    public var flags: Flags
}
