/// The result of a parse: the recovered value and any diagnostics.
public struct Parsed<Value> {
    /// The parsed value. It is always present, because parsing recovers tolerantly.
    public var value: Value

    /// The diagnostics produced while parsing.
    public var diagnostics: [Diagnostic]
}

extension Parsed: Equatable where Value: Equatable {}

extension Parsed: Hashable where Value: Hashable {}

extension Parsed: Sendable where Value: Sendable {}
