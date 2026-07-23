extension Step {
    /// The step with every amount it states multiplied by a factor, or `nil` when nothing in
    /// it moved.
    ///
    /// A step that changed no longer states the text it was read from, so it is rewritten to
    /// the text it now states. One that did not change keeps that text exactly, incidental
    /// spacing and every escape included.
    ///
    /// Scaling is defined over amounts alone, so a timer is left as written whatever the
    /// factor, while a reference's consumption fence moves with the rest.
    ///
    /// - Throws: ``ScalingError/unwritableQuantity`` when a product cannot be written back.
    func scaled(by factor: Double) throws -> Step? {
        let scaled = try segments.map({ try Self.scaled($0, by: factor) })

        guard scaled != segments else { return nil }

        return Step(segments: scaled, text: Self.rendered(scaled))
    }

    /// The segment with the amount it states multiplied, or the segment itself when it states
    /// none or that amount did not move.
    private static func scaled(_ segment: Segment, by factor: Double) throws -> Segment {
        switch segment {
        case .ingredient(var ingredient):
            guard let amount = try ingredient.amount?.scaled(by: factor) else { return segment }
            ingredient.amount = amount

            return .ingredient(ingredient)
        case .reference(var reference):
            guard let amount = try reference.amount?.scaled(by: factor) else { return segment }
            reference.amount = amount

            return .reference(reference)
        case .text, .cookware, .timer:
            return segment
        }
    }
}
