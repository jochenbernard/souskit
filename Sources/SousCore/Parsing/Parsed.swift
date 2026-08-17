/// A parsed value together with the diagnostics produced while reading it.
///
/// Parsing always succeeds, so a value is always present. Diagnostics report what was wrong with
/// the source, not whether the value is usable.
public struct Parsed<Value> {
    /// The parsed value.
    public var value: Value

    /// The problems found while parsing, in the order they were found.
    public var diagnostics: [Diagnostic]
}

extension Parsed: Equatable where Value: Equatable {}

extension Parsed: Hashable where Value: Hashable {}

extension Parsed: Sendable where Value: Sendable {}
