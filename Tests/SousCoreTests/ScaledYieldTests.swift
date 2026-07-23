import SousCore
import Testing

// What the header of a scaled recipe states. Every yield moves with the amounts, but the one
// naming the target's unit states the target itself: a factor is derived by dividing and
// applied by multiplying, and the two do not always land back on the number the division
// started from.

@Suite("Scaled yields")
struct ScaledYieldTests {
    private func scaled(_ header: String, to target: String) throws -> Recipe {
        let parser = SousParser()

        return try parser.parseRecipe(Recipe.flourRecipe(header)).value.scaled(to: parser.parseAmount(target))
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

    // Only the entry the alias is read from states the target. A repeated scalar key is read
    // from its last occurrence, so an earlier one it shadows is left to the factor, exactly as
    // scaling by that factor alone would leave it.

    @Test
    func statesOnlyTheEntryTheAliasIsReadFrom() throws {
        let scaled = try scaled("servings: 4\nservings: 6", to: "12 servings")

        #expect(scaled.metadata.entries.map(\.value) == [.scalar("8"), .scalar("12")])
        #expect(scaled.metadata.servings == 12.0)
    }

    @Test(arguments: ["servings: 0\nservings: 1", "servings: 3\nservings: 8"])
    func scalingToWhatAShadowedKeyAlreadyStatesChangesNothing(header: String) throws {
        let parsed = Recipe.read(Recipe.flourRecipe(header))
        let target = "\(parsed.metadata.servings ?? 0) servings"

        #expect(try scaled(header, to: target) == parsed)
    }

    // The alias is read from the last scalar entry, so a later one stating no quantity leaves
    // the dimension to a yield, and the earlier entry is still only multiplied.

    @Test
    func statesNoTargetInAnEntryTheAliasDoesNotStandFor() throws {
        let scaled = try scaled("servings: 4\nservings: six\nyield: [11 servings]", to: "15 servings")

        #expect(scaled.metadata.entries.map(\.value) == [
            .scalar("5.454545454545454"), .scalar("six"), .list(["15 servings"])
        ])
    }

    @Test
    func statesTheTargetInAServingsValueThatCarriesAUnit() throws {
        let scaled = try scaled("servings: 4 people\nservings: 8", to: "16 servings")

        #expect(scaled.metadata.entries.map(\.value) == [.scalar("8 people"), .scalar("16")])
    }

    @Test
    func statesAServingsTargetExactly() throws {
        let parsed = Recipe.read(Recipe.flourRecipe("servings: 11"))

        #expect(try parsed.scaled(toServings: 15.0).metadata["servings"] == "15")
    }

    // Only the dimension the target names is stated exactly. Every other yield, and every
    // amount, is the product the factor left.

    @Test
    func leavesEveryOtherYieldAtTheProductTheFactorLeft() throws {
        let scaled = try scaled("servings: 11\nyield: [3 kg]", to: "15 servings")

        #expect(scaled.metadata["servings"] == "15")
        #expect(scaled.metadata.yields.map(\.text) == ["4.090909090909091 kg"])
        #expect(try scaled.flourWeight() == 200.0 * (15.0 / 11.0))
    }

    // A value stating no quantity names no dimension, so the target never replaces it, even
    // where it carries no unit to tell it apart by.

    @Test
    func leavesAValueStatingNoQuantityAlone() throws {
        let scaled = try scaled("yield: [plenty, 11]", to: "15")

        #expect(scaled.metadata.yields.map(\.text) == ["plenty", "15"])
    }
}
