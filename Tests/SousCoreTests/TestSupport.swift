// swiftlint:disable:this file_name

import SousCore
import Testing

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
        Recipe.read(serialized())
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
