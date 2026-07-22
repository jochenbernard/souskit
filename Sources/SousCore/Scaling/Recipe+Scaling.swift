extension Recipe {
    /// Returns the recipe scaled by a factor.
    ///
    /// A precise amount is multiplied and a range is multiplied at both ends. A fixed,
    /// imprecise, or absent amount states nothing to multiply and is left as written, so a
    /// scaled recipe is not a strict multiple of the original. The declared `servings` and
    /// `yield` values are multiplied with the amounts, so the scaled recipe still states what
    /// it makes. Timers are never scaled.
    ///
    /// A scaled amount holds the exact multiplied value and text regenerated from it; scaling
    /// never rounds. A step holding one is rewritten to the text it now states, while a step
    /// scaling did not touch keeps the text it was read from.
    ///
    /// - Parameter factor: The factor to multiply by. It must be a finite number of zero or more.
    /// - Returns: The scaled recipe.
    /// - Throws: ``ScalingError/unusableFactor`` when the factor is negative or not finite.
    public func scaled(by factor: Double) throws -> Recipe {
        guard factor.isFinite, factor >= 0 else { throw ScalingError.unusableFactor }

        return Recipe(
            metadata: metadata.scaled(by: factor),
            steps: steps.map({ $0.scaled(by: factor) ?? $0 })
        )
    }

    /// Returns the recipe scaled to a number of portions.
    ///
    /// The factor is the requested number divided by the portions the recipe declares, taken
    /// from its `servings` value or from a yield stating servings.
    ///
    /// - Parameter servings: The number of portions the scaled recipe is to make.
    /// - Returns: The scaled recipe.
    /// - Throws: ``ScalingError/noMatchingYield`` when the recipe declares no portions,
    ///   ``ScalingError/zeroYield`` when it declares zero of them, and
    ///   ``ScalingError/unusableFactor`` when the factor they derive is negative or not finite.
    public func scaled(toServings servings: Double) throws -> Recipe {
        try scaled(by: factor(toward: servings, in: HeaderField.servings))
    }

    /// Returns the recipe scaled to a target amount.
    ///
    /// The factor is the target's quantity divided by the quantity of the declared yield
    /// stating the target's unit, so a target of `18 pancakes` against `yield: 12 pancakes`
    /// scales by 1.5. A `servings` value counts as a yield of that many servings.
    ///
    /// Units are compared with the whitespace around them ignored and nothing else, so a
    /// target and a yield spelled in different units of one dimension, such as `1 kg` against
    /// `yield: 800 g`, do not match. Converting between them needs reference data, which the
    /// semantic layer adds.
    ///
    /// - Parameter target: The amount the scaled recipe is to make.
    /// - Returns: The scaled recipe.
    /// - Throws: ``ScalingError/noMatchingYield`` when the recipe declares no yield the target
    ///   can be divided by, ``ScalingError/zeroYield`` when that yield is zero, and
    ///   ``ScalingError/unusableFactor`` when the factor they derive is negative or not finite.
    public func scaled(to target: Amount) throws -> Recipe {
        // A range and an imprecise amount state no single quantity, so neither divides a yield.
        guard let value = target.kind.soleValue else { throw ScalingError.noMatchingYield }

        return try scaled(by: factor(toward: value, in: SourceText.trimmed(target.unit ?? "")))
    }

    /// The factor that takes what the recipe declares in a unit to a target of it.
    ///
    /// A yield states the divisor, so one that states no single quantity is no more use than
    /// a dimension the recipe never declared, and both report the same thing.
    private func factor(toward target: Double, in unit: String) throws -> Double {
        guard let yield = metadata.declaredYields.first(where: { $0.unit == unit }),
              let divisor = yield.kind.soleValue
        else { throw ScalingError.noMatchingYield }

        guard divisor != 0 else { throw ScalingError.zeroYield }

        return target / divisor
    }
}
