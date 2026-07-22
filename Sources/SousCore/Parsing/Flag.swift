// The named flags version 0.2 reads, and the words they are written as.
//
// Reading and writing share this one table, so a word a reader recognizes is a word a
// writer produces, and a flag a later version adds is added once.

enum Flag: String, CaseIterable {
    case optional = "optional"
    case staple = "staple"
    case nonFood = "non-food"

    /// The character a named flag opens with.
    static let separator: Character = ":"

    /// The shorthand, a single character needing no flag word.
    static let shorthand: Character = "?"

    /// The flag the shorthand stands for. Reading sets this flag's property and writing tests
    /// it, so the two never disagree on which flag the character is short for.
    static let shorthanded: Flag = .optional

    /// The property the flag states on a set of flags. Reading sets it and writing reads it,
    /// so the two never disagree on which property a flag word stands for.
    var property: WritableKeyPath<Flags, Bool> {
        switch self {
        case .optional: \.isOptional
        case .staple: \.isStaple
        case .nonFood: \.isNonFood
        }
    }

    /// The span a flag word is written as, recognized or not.
    static func written(_ word: String) -> String {
        "\(separator)\(word)"
    }

    /// Whether the character opens a flag: the shorthand always does, and the separator does
    /// when a flag word follows it. Reading and writing share this one rule, so a character
    /// a reader would take for a flag is one a writer escapes.
    static func opens(_ character: Character, followedBy following: Character?) -> Bool {
        if character == shorthand { return true }

        return character == separator && (following.map(continuesWord) ?? false)
    }

    /// Whether the character may appear in a flag word, which is a run of letters and
    /// hyphens. A flag word ends at the first character outside that set, so punctuation and
    /// numbers after a flag stay in the prose.
    ///
    /// No flag this language defines carries a number, and the set is narrowed here rather
    /// than after the syntax freezes, because widening one costs a version and narrowing one
    /// costs compatibility.
    static func continuesWord(_ character: Character) -> Bool {
        character.isLetter || character == "-"
    }
}
