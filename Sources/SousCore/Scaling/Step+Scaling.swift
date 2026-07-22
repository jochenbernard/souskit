extension Step {
    /// The step with every amount it states multiplied by a factor, or `nil` when nothing in
    /// it moved.
    ///
    /// A step that changed no longer states the text it was read from, so it is rewritten to
    /// the text it now states. One that did not change keeps that text exactly, incidental
    /// spacing and every escape included.
    ///
    /// Scaling is defined over amounts alone, so a timer is left as written whatever the
    /// factor.
    ///
    /// - Throws: ``ScalingError/unwritableQuantity`` when a product cannot be written back.
    func scaled(by factor: Double) throws -> Step? {
        let scaled = try segments.map({ segment -> Segment in
            guard case var .ingredient(ingredient) = segment,
                  let amount = try ingredient.amount?.scaled(by: factor)
            else { return segment }

            ingredient.amount = amount

            return .ingredient(ingredient)
        })

        guard scaled != segments else { return nil }

        return Step(segments: scaled, text: Self.rendered(scaled))
    }
}
