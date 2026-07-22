/// Why a recipe could not be scaled.
public enum ScalingError: Error, Equatable, Hashable, Sendable {
    /// The factor is negative, or is not a finite number, so nothing can be multiplied by it.
    ///
    /// A scaled amount writes its value back as text, and a value that is negative, infinite,
    /// or not a number writes text no reader reads as an amount. Zero is allowed, because the
    /// amount it writes reads back exactly.
    case unusableFactor

    /// The recipe declares no yield the target can be divided by.
    ///
    /// Either no declared yield states the target's unit, or the target states no single
    /// quantity to divide by, as a range or an imprecise amount does.
    case noMatchingYield

    /// The declared yield the target matches is zero, which no factor can be derived from.
    case zeroYield
}
