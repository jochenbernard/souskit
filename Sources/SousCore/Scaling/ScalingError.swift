/// Why a recipe could not be scaled.
public enum ScalingError: Error, Equatable, Hashable, Sendable {
    /// The factor is negative, or is not a finite number, so nothing can be multiplied by it.
    ///
    /// A scaled amount writes its value back as text, and a negative, infinite, or
    /// not-a-number factor leaves a value writing text no reader reads as an amount. Zero is
    /// allowed and negative zero is not, because only the second writes a sign.
    case unusableFactor

    /// A quantity's value multiplied by the factor is not a finite number, so it cannot be
    /// written back.
    ///
    /// A quantity states as much as a number holds and no more, so multiplying one can leave
    /// that range. The text such a value writes reads back as an imprecise amount, with the
    /// quantity it was meant to state gone.
    case unwritableQuantity

    /// The recipe declares no yield the target can be divided by.
    ///
    /// No declared yield states the target's unit, or the target or the yield it matches
    /// states no single quantity to divide by, as a range or an imprecise amount does.
    case noMatchingYield

    /// The declared yield the target matches is zero, which no factor can be derived from.
    case zeroYield

    /// The recipe declares more than one yield in the target's unit, and they state different
    /// amounts, so none of them is the divisor.
    ///
    /// Stating one unit more than once is reported by ``Recipe/validate()`` whether or not the
    /// values agree. Only a request that has to divide by one of them fails, and only while
    /// they disagree.
    case conflictingYields
}
