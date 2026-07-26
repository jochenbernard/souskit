import SousCore
import Testing

// swiftlint:disable file_types_order

extension Amount.Kind {
    /// The quantity of a precise amount, or `nil` for any other kind.
    var preciseQuantity: Quantity? {
        if case let .precise(quantity) = self {
            quantity
        } else {
            nil
        }
    }

    /// The bounds of a range, or `nil` for any other kind.
    var rangeQuantities: (low: Quantity, high: Quantity)? {
        if case let .range(low, high) = self {
            (low, high)
        } else {
            nil
        }
    }

    /// The text of an imprecise amount, or `nil` for any other kind.
    var impreciseText: String? {
        if case let .imprecise(text) = self {
            text
        } else {
            nil
        }
    }
}

extension SousParser {
    /// The amount of the first annotated ingredient of a source, after scaling by the factor.
    func scaledAmount(in source: String, by factor: Double) throws -> Amount? {
        try parseRecipe(source).value.scaled(by: factor).firstAmount
    }

    /// The same as ``scaledAmount(in:by:)``, requiring that an amount is present.
    func amount(in source: String, scaledBy factor: Double) throws -> Amount {
        let scaled = try scaledAmount(in: source, by: factor)

        return try #require(scaled)
    }

    /// The recipe a source describes, scaled to a target written as fence content.
    func scaled(_ source: String, to target: String) throws -> Recipe {
        try parseRecipe(source).value.scaled(to: parseAmount(target))
    }
}

extension Recipe {
    /// The recipe a source describes, discarding diagnostics.
    static func read(_ source: String) -> Recipe {
        SousParser().parseRecipe(source).value
    }

    /// The amount of the first annotated ingredient.
    var firstAmount: Amount? {
        ingredients.first?.amount
    }

    /// The first step of the recipe.
    var firstStep: Step? {
        steps.first
    }

    /// The first annotated ingredient.
    var firstIngredient: Ingredient? {
        ingredients.first
    }

    /// The first annotated cookware.
    var firstCookware: Cookware? {
        cookware.first
    }

    /// The first annotated timer.
    var firstTimer: Timer? {
        timers.first
    }

    /// The first annotated reference.
    var firstReference: Reference? {
        references.first
    }

    /// The recipe serialized and read back, for round-trip assertions.
    func reRead() -> Recipe {
        Self.read(serialized())
    }

    /// A source with the given header and one ingredient of `200 g` flour.
    static func flourRecipe(_ header: String) -> String {
        "---\n\(header)\n---\n\nMix @{200 g} flour@."
    }

    /// The numeric value of the flour amount, requiring that it is a precise quantity.
    func flourWeight() throws -> Double {
        try #require(firstAmount?.kind.preciseQuantity?.value)
    }

    /// A source exercising a header, an ingredient with an amount, and cookware.
    static let wellFormedSource = """
    ---
    title: Garlic Pasta
    servings: 2
    ---

    Cook @{200 g} spaghetti@ in a #large pot#.
    """
}

extension Metadata {
    /// The metadata of a header written between fences.
    static func read(_ header: String) -> Metadata {
        Recipe.read("---\n\(header)\n---").metadata
    }
}

extension Parsed {
    /// The first diagnostic of the given kind, requiring that one is present.
    func firstDiagnostic(ofKind kind: Diagnostic.Kind) throws -> Diagnostic {
        try #require(diagnostics.first(where: { $0.kind == kind }))
    }
}

extension Segment {
    /// The text of a prose segment, or `nil` for any annotation.
    var proseText: String? {
        if case let .text(text) = self {
            text
        } else {
            nil
        }
    }

    /// The ingredient of an ingredient segment, or `nil` for any other segment.
    var ingredientValue: Ingredient? {
        if case let .ingredient(ingredient) = self {
            ingredient
        } else {
            nil
        }
    }

    /// The cookware of a cookware segment, or `nil` for any other segment.
    var cookwareValue: Cookware? {
        if case let .cookware(cookware) = self {
            cookware
        } else {
            nil
        }
    }

    /// The reference of a reference segment, or `nil` for any other segment.
    var referenceValue: Reference? {
        if case let .reference(reference) = self {
            reference
        } else {
            nil
        }
    }
}

extension String {
    /// A quantity of `1` followed by the given number of zeros.
    static func quantity(digits: Int) -> String {
        "1" + String(repeating: "0", count: digits)
    }
}

enum TestSupport {
    /// Sources whose layout serializing normalizes, so re-reading them is stable but their text
    /// is not preserved byte for byte.
    static let normalizedLayouts = [
        "Toast the bread.\n",
        "Toast the bread.\n\n",
        "\nToast the bread.",
        "First step.\n\n\nSecond step.",
        "---\n---",
        "---\ntitle: Toast\n---\nBody line.",
        "Cook @{200 g}pasta@.",
        "Cook @{200 g}  pasta@.",
        "Cook @pasta @.",
        "Add @{ 200 g } flour@.",
        "Add @{200\tg} flour@.",
        "Wait ~40 min ~ now.",
        "Layer the >{300 g}  sauce> in a dish.",
        "##  Sauce\nBrown the beef.",
        "##\tSauce\nBrown the beef.",
        "Toast the bread.\n   \nSpread with butter.",
        "--- \ntitle: Toast\n--- ",
        "Add @{200 g}@ now.",
        "Toast the bread\u{2028}and butter it.",
        "---\ntitle:  Toast\n---",
        "---\ntitle:\tToast\n---",
        "---\ntags: [italian, quick] \n---",
        "---\ntags:  [italian, quick]\n---"
    ]

    /// Reports the first of a batch of failures, naming how many there were.
    ///
    /// The message is an autoclosure evaluated only when the expectation fails, so indexing the
    /// first failure is safe.
    static func expectNoFailures(
        _ failures: [String],
        sourceLocation: Testing.SourceLocation = #_sourceLocation
    ) {
        #expect(
            failures.isEmpty,
            "\(failures.count) failures, the first being that \(failures[0])",
            sourceLocation: sourceLocation
        )
    }
}

// swiftlint:enable file_types_order
