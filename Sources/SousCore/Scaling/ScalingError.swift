/// Why a recipe could not be scaled to a target.
///
/// Scaling by a factor states its own factor and so never fails; only scaling to a target
/// derives one, from a declared yield it may not find.
public enum ScalingError: Error, Equatable, Hashable, Sendable {
    /// The recipe declares no yield the target can be divided by.
    ///
    /// Either no declared yield states the target's unit, or the target states no single
    /// quantity to divide by, as a range or an imprecise amount does.
    case noMatchingYield

    /// The declared yield the target matches is zero, which no factor can be derived from.
    case zeroYield
}
