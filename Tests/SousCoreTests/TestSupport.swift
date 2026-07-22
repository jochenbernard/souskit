// swiftlint:disable:this file_name

import SousCore

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
    /// The amount of the first ingredient annotated anywhere in the recipe, which is the one
    /// a test naming a single amount is asking about.
    var firstAmount: Amount? {
        ingredients.first?.amount
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
}
