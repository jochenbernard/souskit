import SousCore
import Testing

// What the header of a scaled recipe states. Every yield moves with the amounts, but the one
// naming the target's unit states the target itself: a factor is derived by dividing and
// applied by multiplying, and the two do not always land back on the number the division
// started from.

@Suite("Scaled yields")
struct ScaledYieldTests {
    private func recipe(_ header: String) -> String {
        "---\n\(header)\n---\n\nMix @{200 g} flour@."
    }

    private func scaled(_ header: String, to target: String) throws -> Recipe {
        let parser = SousParser()

        return try parser.parseRecipe(recipe(header)).value.scaled(to: parser.parseAmount(target))
    }

    private func flour(in recipe: Recipe) throws -> Double {
        try #require(recipe.firstAmount?.kind.preciseQuantity?.value)
    }

    // A factor is derived by dividing and applied by multiplying, and the two do not always
    // land back on the number the division started from. The target is a value its caller
    // stated, so the yield naming it is written as that value rather than as the product.

    @Test(arguments: [
        (header: "servings: 11", target: "15 servings", written: "15"),
        (header: "servings: 11 people", target: "15 servings", written: "15 people"),
        (header: "servings: 7", target: "29 servings", written: "29"),
        (header: "servings: 23", target: "13 servings", written: "13")
    ])
    func statesTheTargetItWasGivenExactly(header: String, target: String, written: String) throws {
        let scaled = try scaled(header, to: target)

        #expect(scaled.metadata["servings"] == written)
    }

    @Test
    func statesAYieldTargetExactly() throws {
        let scaled = try scaled("yield: [11 pancakes]", to: "15 pancakes")

        #expect(scaled.metadata.yields.map(\.text) == ["15 pancakes"])
    }

    // Both spellings of the portion dimension state the target, because both name the unit
    // the target was matched by.

    @Test
    func statesEverySpellingOfTheTargetsUnitExactly() throws {
        let scaled = try scaled("servings: 11\nyield: [11 servings]", to: "15 servings")

        #expect(scaled.metadata["servings"] == "15")
        #expect(scaled.metadata.yields.map(\.text) == ["15 servings"])
    }

    @Test
    func statesAServingsTargetExactly() throws {
        let parsed = SousParser().parseRecipe(recipe("servings: 11")).value

        #expect(try parsed.scaled(toServings: 15.0).metadata["servings"] == "15")
    }

    // Only the dimension the target names is stated exactly. Every other yield, and every
    // amount, is the product the factor left.

    @Test
    func leavesEveryOtherYieldAtTheProductTheFactorLeft() throws {
        let scaled = try scaled("servings: 11\nyield: [3 kg]", to: "15 servings")

        #expect(scaled.metadata["servings"] == "15")
        #expect(scaled.metadata.yields.map(\.text) == ["4.090909090909091 kg"])
        #expect(try flour(in: scaled) == 200.0 * (15.0 / 11.0))
    }

    // A value stating no quantity names no dimension, so the target never replaces it, even
    // where it carries no unit to tell it apart by.

    @Test
    func leavesAValueStatingNoQuantityAlone() throws {
        let scaled = try scaled("yield: [plenty, 11]", to: "15")

        #expect(scaled.metadata.yields.map(\.text) == ["plenty", "15"])
    }
}
