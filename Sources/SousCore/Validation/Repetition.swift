/// Finds values sharing a key, so a repeat is reported once rather than at every occurrence.
enum Repetition {
    /// The first value under each key that appears more than once, in the order they occur.
    static func firstOfEachRepeated<Value>(in values: [Value], by key: (Value) -> String) -> [Value] {
        let keyed = values.map({ (value: $0, key: key($0)) })
        let counts = keyed.reduce(into: [String: Int]()) { counts, entry in
            counts[entry.key, default: 0] += 1
        }
        var reported: Set<String> = []

        return keyed
            .filter({ counts[$0.key, default: 0] > 1 && reported.insert($0.key).inserted })
            .map(\.value)
    }
}
