// What a rule reports when a file states one thing more than once.
//
// Every such rule reports the first statement of each repetition and says nothing about the
// rest, so the rules share this one routine rather than each stating it again.

enum Repetition {
    /// The first statement of each value a list states more than once, in document order.
    ///
    /// - Parameters:
    ///   - values: The values stated, in document order.
    ///   - key: What makes two values the same, such as the unit a yield is written in or the
    ///     form a name is matched in.
    /// - Returns: The first statement of each repeated value.
    static func firstOfEachRepeated<Value>(in values: [Value], by key: (Value) -> String) -> [Value] {
        // Keying a value can cost a normalization, so each is keyed once and carried.
        let keyed = values.map({ (value: $0, key: key($0)) })
        let counts = keyed.reduce(into: [String: Int](), { counts, entry in
            counts[entry.key, default: 0] += 1
        })
        var reported: Set<String> = []

        return keyed
            .filter({ counts[$0.key, default: 0] > 1 && reported.insert($0.key).inserted })
            .map(\.value)
    }
}
