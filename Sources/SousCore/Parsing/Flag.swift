/// The flags an ingredient or reference may carry, written `:name` after the closing sigil.
enum Flag: String, CaseIterable {
    case optional = "optional"
    case staple = "staple"
    case nonFood = "non-food"

    /// The character introducing a flag.
    static let separator: Character = ":"

    /// The character standing for this flag on its own, or `nil` when it may only be written as
    /// `:name`.
    var shorthand: Character? {
        switch self {
        case .optional: "?"
        case .staple, .nonFood: nil
        }
    }

    /// Every character standing for a flag on its own.
    static let shorthands: Set<Character> = Set(allCases.compactMap(\.shorthand))

    /// Creates the flag a character stands for on its own, or `nil` when none does.
    init?(shorthand character: Character) {
        guard let flag = Self.allCases.first(where: { $0.shorthand == character }) else { return nil }

        self = flag
    }

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
        if shorthands.contains(character) { return true }

        return character == separator && (following.map(continuesWord) ?? false)
    }

    /// Whether a character continues a flag word.
    static func continuesWord(_ character: Character) -> Bool {
        character.isLetter || character == "-"
    }
}
