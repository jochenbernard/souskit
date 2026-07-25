extension Recipe {
    /// Multiplies every scalable amount by the factor.
    ///
    /// Fixed and imprecise amounts are left alone, as are timers. Of the header, only `servings`
    /// and `yield` scale.
    ///
    /// - Parameter factor: The multiplier. Zero is permitted; negative zero is not.
    /// - Returns: The scaled recipe.
    /// - Throws: ``ScalingError/unusableFactor`` when the factor is negative or not finite, and
    ///   ``ScalingError/unwritableQuantity`` when a scaled quantity is no longer finite.
    public func scaled(by factor: Double) throws -> Recipe {
        guard factor.isFinite, factor.sign == .plus else { throw ScalingError.unusableFactor }

        return Recipe(
            metadata: try metadata.scaled(by: factor),
            groups: try groups.map({ try $0.scaled(by: factor) })
        )
    }

    /// Scales the recipe to a number of servings, dividing by the declared `servings`.
    ///
    /// - Parameter servings: The servings to scale to.
    /// - Returns: The scaled recipe, its `servings` restated as the target.
    /// - Throws: A ``ScalingError`` when no usable `servings` is declared, or when scaling fails.
    public func scaled(toServings servings: Double) throws -> Recipe {
        try scaled(toward: servings, in: HeaderField.servings)
    }

    /// Scales the recipe to a target amount, dividing by the declared yield of the same unit.
    ///
    /// Units are matched as written, trimmed, with no conversion between spellings.
    ///
    /// - Parameter target: The amount to scale to. It must hold a single quantity.
    /// - Returns: The scaled recipe, the matching yield restated as the target.
    /// - Throws: ``ScalingError/noMatchingYield`` when the target holds no single quantity or no
    ///   declared yield matches its unit, ``ScalingError/conflictingYields`` when several
    ///   matching yields disagree, and ``ScalingError/zeroYield`` when the match is zero.
    public func scaled(to target: Amount) throws -> Recipe {
        guard let value = target.kind.soleValue else { throw ScalingError.noMatchingYield }

        return try scaled(toward: value, in: DeclaredYield.matching(target.unit))
    }

    /// Scales by the factor reaching the target, then restates the yield as the target exactly.
    private func scaled(toward target: Double, in unit: String) throws -> Recipe {
        var scaled = try scaled(by: factor(toward: target, in: unit))
        scaled.metadata = scaled.metadata.stating(target, in: unit)

        return scaled
    }

    /// The factor taking the declared yield of the given unit to the target.
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
