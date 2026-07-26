/// Why a recipe could not be scaled.
public enum ScalingError: Error, Equatable, Hashable, Sendable {
    /// The factor is negative, or is not a finite number.
    ///
    /// Zero is permitted; negative zero is not.
    case unusableFactor

    /// A scaled quantity is no longer a finite number, so it cannot be written back.
    case unwritableQuantity

    /// No declared yield matches the target's unit, or the one that matches is a range or an
    /// imprecise amount rather than a single quantity.
    case noMatchingYield

    /// The matching yield is zero, so no factor reaches the target.
    case zeroYield

    /// Several declared yields share the target's unit but give different quantities.
    case conflictingYields
}
