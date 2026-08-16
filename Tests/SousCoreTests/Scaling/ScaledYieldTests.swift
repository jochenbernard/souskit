import SousCore
import Testing

@Suite("Scaled yields")
struct ScaledYieldTests {
    @Test(arguments: [
        (header: "servings: 11", target: "15 servings", written: "15"),
        (header: "servings: 11 people", target: "15 servings", written: "15 people"),
        (header: "servings: 7", target: "29 servings", written: "29"),
        (header: "servings: 23", target: "13 servings", written: "13")
    ])
    func statesTheTargetItWasGivenExactly(
        header: String,
        target: String,
        written: String
    ) throws {
        let scaled = try SousParser().scaled(Fixtures.crepeBatter(header), to: target)

        #expect(scaled.metadata["servings"] == written)
    }

    @Test
    func statesAYieldTargetExactly() throws {
        let scaled = try SousParser().scaled(Fixtures.crepeBatter("yield: [11 crepes]"), to: "15 crepes")

        #expect(scaled.metadata.yields.map(\.text) == ["15 crepes"])
    }

    @Test
    func statesEverySpellingOfTheTargetsUnitExactly() throws {
        let scaled = try SousParser().scaled(
            Fixtures.crepeBatter("servings: 11\nyield: [11 servings]"),
            to: "15 servings"
        )

        #expect(scaled.metadata["servings"] == "15")
        #expect(scaled.metadata.yields.map(\.text) == ["15 servings"])
    }

    @Test
    func statesOnlyTheEntryTheAliasIsReadFrom() throws {
        let scaled = try SousParser().scaled(Fixtures.crepeBatter("servings: 4\nservings: 6"), to: "12 servings")

        #expect(scaled.metadata.entries.map(\.value) == [.scalar("8"), .scalar("12")])
        #expect(scaled.metadata.servings == 12.0)
    }

    @Test(arguments: ["servings: 0\nservings: 1", "servings: 3\nservings: 8"])
    func scalingToWhatAShadowedKeyAlreadyStatesChangesNothing(header: String) throws {
        let parsed = Recipe.read(Fixtures.crepeBatter(header))
        let target = "\(parsed.metadata.servings ?? 0) servings"

        #expect(try SousParser().scaled(Fixtures.crepeBatter(header), to: target) == parsed)
    }

    @Test
    func statesNoTargetInAnEntryTheAliasDoesNotStandFor() throws {
        let scaled = try SousParser().scaled(
            Fixtures.crepeBatter("servings: 4\nservings: six\nyield: [11 servings]"),
            to: "15 servings"
        )

        #expect(scaled.metadata.entries.map(\.value) == [
            .scalar("5.454545454545454"), .scalar("six"), .list(["15 servings"])
        ])
    }

    @Test
    func statesTheTargetInAServingsValueThatCarriesAUnit() throws {
        let scaled = try SousParser().scaled(Fixtures.crepeBatter("servings: 4 people\nservings: 8"), to: "16 servings")

        #expect(scaled.metadata.entries.map(\.value) == [.scalar("8 people"), .scalar("16")])
    }

    @Test
    func statesAServingsTargetExactly() throws {
        let parsed = Recipe.read(Fixtures.crepeBatter("servings: 11"))

        #expect(try parsed.scaled(toServings: 15.0).metadata["servings"] == "15")
    }

    @Test
    func leavesEveryOtherYieldAtTheProductTheFactorLeft() throws {
        let scaled = try SousParser().scaled(Fixtures.crepeBatter("servings: 11\nyield: [3 kg]"), to: "15 servings")

        #expect(scaled.metadata["servings"] == "15")
        #expect(scaled.metadata.yields.map(\.text) == ["4.090909090909091 kg"])
        #expect(try scaled.firstQuantityValue() == 200.0 * (15.0 / 11.0))
    }

    @Test
    func leavesAValueStatingNoQuantityAlone() throws {
        let scaled = try SousParser().scaled(Fixtures.crepeBatter("yield: [plenty, 11]"), to: "15")

        #expect(scaled.metadata.yields.map(\.text) == ["plenty", "15"])
    }
}
