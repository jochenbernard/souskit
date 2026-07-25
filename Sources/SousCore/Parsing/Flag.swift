/// The flags an ingredient or reference may carry, written `:name` after the closing sigil.
enum Flag: String, CaseIterable {
    case optional = "optional"
    case staple = "staple"
    case nonFood = "non-food"

    /// The character introducing a flag.
    static let separator: Character = ":"

    /// The single-character form standing for ``shorthanded``.
    static let shorthand: Character = "?"

    /// The flag that ``shorthand`` sets.
    static let shorthanded: Flag = .optional

    /// The property on ``Flags`` this flag sets.
    var property: WritableKeyPath<Flags, Bool> {
        switch self {
        case .optional: \.isOptional
        case .staple: \.isStaple
        case .nonFood: \.isNonFood
        }
    }

    /// A flag word as it is written in source.
    static func written(_ word: String) -> String {
        "\(separator)\(word)"
    }

    /// Whether a flag begins here, given the character after it.
    ///
    /// A separator not followed by a word character is ordinary text, so prose such as
    /// `@salt@: to taste` carries no flag.
    static func opens(_ character: Character, followedBy following: Character?) -> Bool {
        if character == shorthand { return true }

        return character == separator && (following.map(continuesWord) ?? false)
    }

    /// Whether a character continues a flag word.
    static func continuesWord(_ character: Character) -> Bool {
        character.isLetter || character == "-"
    }
}
