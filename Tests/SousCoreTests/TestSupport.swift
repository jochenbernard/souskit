import SousCore
import Testing

// swiftlint:disable file_types_order

// Convenience extractors so tests can read an annotation's associated values without
// repeating a `case let` pattern match at every call site.

extension Amount.Kind {
    var preciseQuantity: Quantity? {
        if case let .precise(quantity) = self {
            quantity
        } else {
            nil
        }
    }

    var rangeQuantities: (low: Quantity, high: Quantity)? {
        if case let .range(low, high) = self {
            (low, high)
        } else {
            nil
        }
    }

    var impreciseText: String? {
        if case let .imprecise(text) = self {
            text
        } else {
            nil
        }
    }
}

extension SousParser {
    /// The amount the one annotated ingredient of a source states after scaling, which is what
    /// a test naming a single fence is asking about.
    func scaledAmount(in source: String, by factor: Double) throws -> Amount? {
        try parseRecipe(source).value.scaled(by: factor).firstAmount
    }

    /// The amount the one annotated ingredient of a source states after scaling, required to
    /// exist, which is what a test asserting a value about that amount is asking about.
    func amount(in source: String, scaledBy factor: Double) throws -> Amount {
        let scaled = try scaledAmount(in: source, by: factor)

        return try #require(scaled)
    }

    /// The recipe a source scales to a target, with the target read from its text as an amount.
    /// The target-scaling suites share it.
    func scaled(_ source: String, to target: String) throws -> Recipe {
        try parseRecipe(source).value.scaled(to: parseAmount(target))
    }
}

extension Recipe {
    /// The recipe a source reads as, which is what a test stating a source and no expectation
    /// about diagnostics is asking for.
    static func read(_ source: String) -> Recipe {
        SousParser().parseRecipe(source).value
    }

    /// The amount of the first ingredient annotated anywhere in the recipe, which is the one
    /// a test naming a single amount is asking about.
    var firstAmount: Amount? {
        ingredients.first?.amount
    }

    /// The recipe's first step, which is what a test stating a single step is asking about.
    var firstStep: Step? {
        steps.first
    }

    /// The first ingredient annotated anywhere in the recipe, which a test naming a single one
    /// is asking about. Its cookware, timer, and reference siblings read the same way.
    var firstIngredient: Ingredient? {
        ingredients.first
    }

    var firstCookware: Cookware? {
        cookware.first
    }

    var firstTimer: Timer? {
        timers.first
    }

    var firstReference: Reference? {
        references.first
    }

    /// The recipe its own serialized text reads back as, which a round-trip test compares
    /// against the recipe it started from.
    func reRead() -> Recipe {
        Self.read(serialized())
    }

    /// A one-amount recipe under a header, so a scaled flour weight reads back as the factor the
    /// header derives. The scaling suites share this fixture.
    static func flourRecipe(_ header: String) -> String {
        "---\n\(header)\n---\n\nMix @{200 g} flour@."
    }

    /// The weight of the flour fixture's one amount, required to be a single precise quantity.
    func flourWeight() throws -> Double {
        try #require(firstAmount?.kind.preciseQuantity?.value)
    }

    /// A recipe that both reads and validates without diagnostics, shared by the diagnostics
    /// and validation suites as a well-formed fixture.
    static let wellFormedSource = """
    ---
    title: Garlic Pasta
    servings: 2
    ---

    Cook @{200 g} spaghetti@ in a #large pot#.
    """
}

extension Metadata {
    /// The metadata a header reads as, which is what a test stating header lines and no
    /// expectation about the body is asking for.
    static func read(_ header: String) -> Metadata {
        Recipe.read("---\n\(header)\n---").metadata
    }
}

extension Parsed {
    /// The first diagnostic of the given kind, required to exist, which is what a test naming a
    /// single diagnostic is asking about.
    func firstDiagnostic(ofKind kind: Diagnostic.Kind) throws -> Diagnostic {
        try #require(diagnostics.first(where: { $0.kind == kind }))
    }
}

extension Segment {
    var proseText: String? {
        if case let .text(text) = self {
            text
        } else {
            nil
        }
    }

    var ingredientValue: Ingredient? {
        if case let .ingredient(ingredient) = self {
            ingredient
        } else {
            nil
        }
    }

    var cookwareValue: Cookware? {
        if case let .cookware(cookware) = self {
            cookware
        } else {
            nil
        }
    }

    var referenceValue: Reference? {
        if case let .reference(reference) = self {
            reference
        } else {
            nil
        }
    }
}

extension String {
    /// A quantity of this many digits is past the range a number holds, so it reads as no
    /// finite value and states no product a factor moves it to.
    static func quantity(digits: Int) -> String {
        "1" + String(repeating: "0", count: digits)
    }
}

enum TestSupport {
    /// Reported as one line, because a broken escape rule fails on hundreds of inputs at once.
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
