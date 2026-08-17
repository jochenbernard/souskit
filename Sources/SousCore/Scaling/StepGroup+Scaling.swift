extension StepGroup {
    /// The group with every scalable amount in its steps multiplied by the factor.
    func scaled(by factor: Double) throws -> StepGroup {
        var scaled = self
        scaled.steps = try steps.map({ try $0.scaled(by: factor) ?? $0 })

        return scaled
    }
}
