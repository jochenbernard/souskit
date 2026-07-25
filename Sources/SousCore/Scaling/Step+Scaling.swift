extension Step {
    /// The step with every scalable amount multiplied by the factor, or `nil` when nothing moved.
    ///
    /// A step that changes is rebuilt from its segments, so its ``Step/text`` is regenerated
    /// rather than carried over.
    func scaled(by factor: Double) throws -> Step? {
        let scaled = try segments.map({ try Self.scaled($0, by: factor) })

        guard scaled != segments else { return nil }

        return Step(segments: scaled, text: Self.serialized(scaled))
    }

    /// The segment with its amount scaled; timers and cookware carry no scalable amount.
    private static func scaled(_ segment: Segment, by factor: Double) throws -> Segment {
        switch segment {
        case .ingredient(var ingredient):
            ingredient.amount = try scaled(ingredient.amount, by: factor)

            return .ingredient(ingredient)
        case .reference(var reference):
            reference.amount = try scaled(reference.amount, by: factor)

            return .reference(reference)
        case .text, .cookware, .timer:
            return segment
        }
    }

    /// The amount scaled, or the original when it is fixed, imprecise, or absent.
    private static func scaled(_ amount: Amount?, by factor: Double) throws -> Amount? {
        try amount?.scaled(by: factor) ?? amount
    }
}
