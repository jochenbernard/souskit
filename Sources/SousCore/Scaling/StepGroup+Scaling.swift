extension StepGroup {
    /// The group with every amount its steps state multiplied by a factor.
    ///
    /// A group states nothing of its own to multiply, so scaling it is scaling each of its
    /// steps, and a step that did not change keeps the text it was read from.
    ///
    /// - Throws: ``ScalingError/unwritableQuantity`` when a product cannot be written back.
    func scaled(by factor: Double) throws -> StepGroup {
        var scaled = self
        scaled.steps = try steps.map({ try $0.scaled(by: factor) ?? $0 })

        return scaled
    }
}
