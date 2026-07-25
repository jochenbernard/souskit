extension Metadata {
    /// Reports each unit the header states a yield in more than once, counting the `servings`
    /// value and every `yield` entry together.
    ///
    /// It reaches exactly as far as the unit written, because telling that `800 g` and `1 kg`
    /// measure the same thing needs reference data. A value stating no quantity states no
    /// dimension, so ``declaredYields`` leaves it out and it restates nothing. A repeated
    /// `servings` key is the reader's report rather than this one: only its last value is read.
    func repeatedYields() -> [Diagnostic] {
        Repetition.firstOfEachRepeated(in: declaredYields, by: \.unit)
            .map({ .warning(.repeatedYield, Self.repeatedMessage(in: $0.unit)) })
    }

    /// Reports each yield the header declares as zero, which can divide no target.
    ///
    /// Scaling to a target divides by the yield of the target's unit, so a zero one leaves every
    /// such request failing. The declaration is where an author can act on it, and the request
    /// reports on its own terms as well. Scaling by a factor divides by nothing, so the file
    /// stays usable and this is a warning.
    func zeroYields() -> [Diagnostic] {
        declaredYields.filter({ $0.kind.soleValue == 0 }).map({ yield in
            .warning(.zeroYield, Self.zeroMessage(in: yield.unit))
        })
    }

    private static func zeroMessage(in unit: String) -> String {
        unit.isEmpty
            ? "Header declares a yield of zero, which can divide no target."
            : "Header declares a yield of zero in '\(unit)', which can divide no target."
    }

    private static func repeatedMessage(in unit: String) -> String {
        unit.isEmpty
            ? "Header states more than one yield with no unit."
            : "Header states more than one yield in '\(unit)'."
    }
}
