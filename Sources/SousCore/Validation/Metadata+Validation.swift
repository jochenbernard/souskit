extension Metadata {
    /// One warning per unit declaring more than one yield, reported at the first occurrence.
    func repeatedYields() -> [Diagnostic] {
        Repetition.firstOfEachRepeated(in: declaredYields, by: \.unit)
            .map({ Diagnostic(.repeatedYield, Self.repeatedMessage(in: $0.unit)) })
    }

    /// One warning per declared yield of zero.
    func zeroYields() -> [Diagnostic] {
        declaredYields.filter({ $0.kind.soleValue == 0 }).map({ yield in
            Diagnostic(.zeroYield, Self.zeroMessage(in: yield.unit))
        })
    }

    private static func zeroMessage(in unit: String) -> String {
        unit.isEmpty
            ? "Header declares a yield of zero, which can divide no target."
            : "Header declares a yield of zero in '\(unit)', which can divide no target."
    }

    private static func repeatedMessage(in unit: String) -> String {
        unit.isEmpty
            ? "Header declares more than one yield with no unit."
            : "Header declares more than one yield in '\(unit)'."
    }
}
