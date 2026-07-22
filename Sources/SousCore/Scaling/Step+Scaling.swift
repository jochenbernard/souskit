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
    func scaled(by factor: Double) -> Step? {
        var changed = false
        let scaled = segments.map({ segment -> Segment in
            guard case let .ingredient(ingredient) = segment,
                  let amount = ingredient.amount?.scaled(by: factor)
            else { return segment }

            changed = true

            return .ingredient(Ingredient(
                name: ingredient.name,
                amount: amount,
                flags: ingredient.flags
            ))
        })

        guard changed else { return nil }

        var step = Step(segments: scaled, text: "")
        step.text = step.rendered

        return step
    }
}
