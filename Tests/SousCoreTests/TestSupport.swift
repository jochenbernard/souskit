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
    /// The amount of the first annotated ingredient of a source, after scaling by the factor,
    /// requiring that an amount is present.
    func amount(in source: String, scaledBy factor: Double) throws -> Amount {
        let scaled = try parseRecipe(source).value.scaled(by: factor)

        return try #require(scaled.firstAmount)
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

    /// The value of the first amount, requiring that it is a precise quantity.
    func firstQuantityValue() throws -> Double {
        try #require(firstAmount?.kind.preciseQuantity?.value)
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
