extension Metadata {
    /// Reports each unit the header states a yield in more than once, counting the `servings`
    /// value and every `yield` entry together.
    ///
    /// It reaches exactly as far as the unit written, because telling that `800 g` and `1 kg`
    /// measure the same thing needs reference data. A value stating no quantity states no
    /// dimension, so ``declaredYields`` leaves it out and it restates nothing. A repeated
    /// `servings` key is the reader's report rather than this one: only its last value is read.
    func repeatedYields() -> [Diagnostic] {
        let declared = declaredYields
        var stated: [String: Int] = [:]
        var reported: Set<String> = []

        for yield in declared { stated[yield.unit, default: 0] += 1 }

        return declared.compactMap({ yield in
            guard stated[yield.unit] ?? 0 > 1, reported.insert(yield.unit).inserted else { return nil }

            return .warning(.repeatedYield, Self.repeatedMessage(in: yield.unit), at: nil)
        })
    }

    private static func repeatedMessage(in unit: String) -> String {
        unit.isEmpty
            ? "Header states more than one yield with no unit."
            : "Header states more than one yield in '\(unit)'."
    }
}
