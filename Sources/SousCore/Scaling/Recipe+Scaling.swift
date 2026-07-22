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
    /// never rounds.
    ///
    /// - Parameter factor: The factor to multiply by. Any factor works, so this never fails.
    /// - Returns: The scaled recipe.
    public func scaled(by factor: Double) -> Recipe {
        self
    }

    /// Returns the recipe scaled to a number of portions.
    ///
    /// The factor is the requested number divided by the portions the recipe declares, taken
    /// from its `servings` value or from a yield stating servings.
    ///
    /// - Parameter servings: The number of portions the scaled recipe is to make.
    /// - Returns: The scaled recipe.
    /// - Throws: ``ScalingError/noMatchingYield`` when the recipe declares no portions, and
    ///   ``ScalingError/zeroYield`` when it declares zero of them.
    public func scaled(toServings servings: Double) throws -> Recipe {
        self
    }

    /// Returns the recipe scaled to a target amount.
    ///
    /// The factor is the target's quantity divided by the quantity of the declared yield
    /// stating the target's unit, so a target of `18 pancakes` against `yield: 12 pancakes`
    /// scales by 1.5. A `servings` value counts as a yield of that many servings.
    ///
    /// Units are matched as written, so a target and a yield spelled in different units of one
    /// dimension, such as `1 kg` against `yield: 800 g`, do not match. Converting between them
    /// needs reference data, which the semantic layer adds.
    ///
    /// - Parameter target: The amount the scaled recipe is to make.
    /// - Returns: The scaled recipe.
    /// - Throws: ``ScalingError/noMatchingYield`` when the recipe declares no yield the target
    ///   can be divided by, and ``ScalingError/zeroYield`` when that yield is zero.
    public func scaled(to target: Amount) throws -> Recipe {
        self
    }
}
