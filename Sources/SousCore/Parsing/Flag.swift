// The named flags version 0.2 reads, and the words they are written as.
//
// Reading and writing share this one table, so a word a reader recognizes is a word a
// writer produces, and a flag a later version adds is added once.

enum Flag: String {
    case optional = "optional"
    case staple = "staple"
    case nonFood = "non-food"

    /// The character a named flag opens with.
    static let separator: Character = ":"

    /// The shorthand for `:optional`, a single character needing no flag word.
    static let shorthand: Character = "?"

    /// The span a flag is written as.
    var written: String {
        "\(Self.separator)\(rawValue)"
    }

    /// Sets this flag on the given set.
    func set(on flags: inout Flags) {
        switch self {
        case .optional: flags.isOptional = true
        case .staple: flags.isStaple = true
        case .nonFood: flags.isNonFood = true
        }
    }

    /// Whether the character may appear in a flag word, which is a run of letters, digits,
    /// and hyphens. A flag word ends at the first character outside that set, so punctuation
    /// after a flag stays in the prose.
    static func continuesWord(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "-"
    }
}
