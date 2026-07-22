extension Recipe {
    /// Returns the recipe scaled by a factor.
    ///
    /// A precise amount is multiplied and a range is multiplied at both ends. A fixed amount is
    /// held constant, and an imprecise or absent one states nothing to multiply, so all three
    /// are left as written and a scaled recipe is not a strict multiple of the original. The
    /// declared `servings` and `yield` values are multiplied with the amounts, so the scaled
    /// recipe still states what it makes. Timers are never scaled.
    ///
    /// Scaling never rounds, and a step is rewritten only where an amount moved.
    ///
    /// - Parameter factor: The factor to multiply by. It must be a finite number of zero or
    ///   more, negative zero excluded, because that writes the sign a negative factor does.
    /// - Returns: The scaled recipe.
    /// - Throws: ``ScalingError/unusableFactor`` when the factor is negative or not finite, and
    ///   ``ScalingError/unwritableQuantity`` when a product cannot be written back.
    public func scaled(by factor: Double) throws -> Recipe {
        guard factor.isFinite, factor.sign == .plus else { throw ScalingError.unusableFactor }

        return Recipe(
            metadata: try metadata.scaled(by: factor),
            steps: try steps.map({ try $0.scaled(by: factor) ?? $0 })
        )
    }

    /// Returns the recipe scaled to a number of portions.
    ///
    /// The factor is the requested number divided by the portions the recipe declares, taken
    /// from its `servings` value or from a portion yield. The scaled recipe states that number
    /// of portions exactly.
    ///
    /// - Parameter servings: The number of portions the scaled recipe is to make. It must be a
    ///   finite number of zero or more, negative zero excluded.
    /// - Returns: The scaled recipe.
    /// - Throws: ``ScalingError/noMatchingYield`` when the recipe declares no portions that
    ///   can divide the target,
    ///   ``ScalingError/conflictingYields`` when it states them more than once and they
    ///   disagree, ``ScalingError/zeroYield`` when it declares zero of them,
    ///   ``ScalingError/unusableFactor`` when the factor they derive is negative or not finite,
    ///   and ``ScalingError/unwritableQuantity`` when a product cannot be written back.
    public func scaled(toServings servings: Double) throws -> Recipe {
        try scaled(toward: servings, in: HeaderField.servings)
    }

    /// Returns the recipe scaled to a target amount.
    ///
    /// The factor is the target's quantity divided by the quantity of the declared yield
    /// stating the target's unit, so a target of `18 pancakes` against `yield: 12 pancakes`
    /// scales by 1.5. A `servings` value counts as a portion yield.
    ///
    /// Units are compared with the whitespace around them ignored and nothing else, so a
    /// target and a yield spelled in different units of one dimension, such as `1 kg` against
    /// `yield: 800 g`, do not match. Converting between them needs reference data, which a
    /// later version adds.
    ///
    /// The scaled recipe states the target exactly. A factor is derived by dividing and
    /// applied by multiplying, and the two do not always land back on the number the division
    /// started from, so the yields naming the target's unit are written as the target rather
    /// than as that product. Every other yield is the product, because nothing else was asked
    /// for.
    ///
    /// A header stating a yield in the target's unit more than once divides by it only while
    /// every statement of it agrees. ``validate()`` reports the repetition either way.
    ///
    /// - Parameter target: The amount the scaled recipe is to make. Its quantity must be a
    ///   finite number of zero or more, negative zero excluded.
    /// - Returns: The scaled recipe.
    /// - Throws: ``ScalingError/noMatchingYield`` when the recipe declares no yield that can
    ///   divide the target, ``ScalingError/conflictingYields`` when it states the target's
    ///   unit more than once and they disagree, ``ScalingError/zeroYield`` when that yield
    ///   is zero, ``ScalingError/unusableFactor`` when the factor they derive is negative or
    ///   not finite, and ``ScalingError/unwritableQuantity`` when a product cannot be written
    ///   back.
    public func scaled(to target: Amount) throws -> Recipe {
        // A range and an imprecise amount state no single quantity, so neither can be divided
        // by a yield.
        guard let value = target.kind.soleValue else { throw ScalingError.noMatchingYield }

        return try scaled(toward: value, in: DeclaredYield.matching(target.unit))
    }

    /// The recipe scaled by the factor a target derives, with the yields naming the target's
    /// unit stating it exactly rather than the product that factor left.
    private func scaled(toward target: Double, in unit: String) throws -> Recipe {
        var scaled = try scaled(by: factor(toward: target, in: unit))
        scaled.metadata = scaled.metadata.stating(target, in: unit)

        return scaled
    }

    /// The factor that takes what the recipe declares in a unit to a target of it.
    ///
    /// A yield states the divisor, so one that states no single quantity is no more use than a
    /// dimension the recipe never declared, and both report the same thing. A dimension stated
    /// more than once states one divisor only while every statement of it agrees.
    private func factor(toward target: Double, in unit: String) throws -> Double {
        let declared = metadata.declaredYields.filter({ $0.unit == unit })

        guard let yield = declared.first else { throw ScalingError.noMatchingYield }
        guard declared.allSatisfy({ $0.kind.values == yield.kind.values })
        else { throw ScalingError.conflictingYields }

        guard let divisor = yield.kind.soleValue else { throw ScalingError.noMatchingYield }
        guard divisor != 0 else { throw ScalingError.zeroYield }

        return target / divisor
    }
}
