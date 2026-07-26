import SousCore
import Testing

@Suite("Yields")
struct YieldTests {
    @Test
    func readsASingleYieldAsAnAmount() throws {
        let parsed = SousParser().parseRecipe("---\nyield: 800 g\n---")

        #expect(parsed.value.metadata.yields.count == 1)
        let yield = try #require(parsed.value.metadata.yields.first)
        #expect(yield.kind.preciseQuantity?.value == 800.0)
        #expect(yield.unit == "g")
        #expect(yield.text == "800 g")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test(arguments: [
        (value: "1.5 L", quantity: 1.5, unit: "L"),
        (value: "12 muffins", quantity: 12.0, unit: "muffins"),
        (value: "6 servings", quantity: 6.0, unit: "servings"),
        (value: "1/2 batch", quantity: 0.5, unit: "batch"),
        (value: "1 1/2 kg", quantity: 1.5, unit: "kg"),
        (value: "12", quantity: 12.0, unit: "")
    ])
    func readsEveryQuantityFormOfAYield(
        value: String,
        quantity: Double,
        unit: String
    ) throws {
        let metadata = Metadata.read("yield: \(value)")

        let yield = try #require(metadata.yields.first)
        #expect(yield.kind.preciseQuantity?.value == quantity)
        #expect(yield.unit == unit)
    }

    @Test
    func readsMultipleYieldsFromOneInlineList() {
        let parsed = SousParser().parseRecipe("---\nyield: [6 servings, 3.2 kg]\n---")

        let yields = parsed.value.metadata.yields
        #expect(yields.map(\.text) == ["6 servings", "3.2 kg"])
        #expect(yields.compactMap(\.kind.preciseQuantity?.value) == [6.0, 3.2])
        #expect(yields.compactMap(\.unit) == ["servings", "kg"])
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func combinesRepeatedYieldKeysAndWarns() {
        let parsed = SousParser().parseRecipe("---\nyield: 800 g\nyield: 12 muffins\n---")

        #expect(parsed.value.metadata.yields.map(\.text) == ["800 g", "12 muffins"])
        #expect(parsed.diagnostics.map(\.kind) == [.repeatedListKey])
    }

    @Test
    func readsAYieldWithNoLeadingNumberAsImprecise() throws {
        let metadata = Metadata.read("yield: plenty")

        let yield = try #require(metadata.yields.first)
        #expect(yield.kind.impreciseText == "plenty")
        #expect(yield.unit == nil)
    }

    @Test
    func readsAYieldRangeAsARange() throws {
        let metadata = Metadata.read("yield: 10-12 muffins")

        let yield = try #require(metadata.yields.first)
        #expect(yield.kind.rangeQuantities?.low.value == 10.0)
        #expect(yield.kind.rangeQuantities?.high.value == 12.0)
        #expect(yield.unit == "muffins")
    }

    @Test
    func statesNoYieldsWhenTheKeyIsAbsentOrEmpty() {
        #expect(Metadata.read("title: Pancakes").yields.isEmpty)
        #expect(Metadata.read("yield:").yields.isEmpty)
    }

    @Test
    func readsAYieldOpeningWithTheFixedMarkerAsImprecise() throws {
        let metadata = Metadata.read("yield: =800 g")

        let yield = try #require(metadata.yields.first)
        #expect(yield.kind.impreciseText == "=800 g")
        #expect(yield.unit == nil)
        #expect(!yield.isFixed)
    }

    @Test
    func readsNoServingsFromAValueOpeningWithTheFixedMarker() {
        #expect(Metadata.read("servings: =4").servings == nil)
    }

    @Test
    func scalingAHeaderValueDropsTheWhitespaceAroundIt() throws {
        let recipe = try SousParser().parseRecipe("---\nservings:  6 \n---").value.scaled(by: 2.0)

        #expect(recipe.metadata["servings"] == "12")
    }

    @Test
    func readsTheLeadingQuantityOfAServingsRange() {
        #expect(Metadata.read("servings: 4-6").servings == 4.0)
    }

    @Test
    func servingsIsNotListedAmongTheYields() {
        let metadata = Metadata.read("servings: 4")

        #expect(metadata.servings == 4)
        #expect(metadata.yields.isEmpty)
    }

    @Test(arguments: [
        (value: "[800 g", items: ["[800 g"]),
        (value: "[6 servings], [3.2 kg]", items: ["[6 servings], [3.2 kg]"]),
        (value: "[12 muffins, , 800 g,]", items: ["12 muffins", "800 g"]),
        (value: "[1 handful\\, or two]", items: ["1 handful, or two"])
    ])
    func readsAYieldValueUnderTheInlineListRules(value: String, items: [String]) {
        let metadata = Metadata.read("yield: \(value)")

        #expect(metadata.yields.map(\.text) == items)
    }

    @Test
    func writesYieldsInTheInlineForm() {
        let recipe = SousParser().parseRecipe("---\nyield: 800 g\n---").value

        #expect(recipe.serialized() == "---\nyield: [800 g]\n---")
    }

    @Test(arguments: ["---\nyield:\n---", "---\nyield:\n  - 800 g\n---"])
    func writesAYieldOfNoItemsAsTheKeyAlone(source: String) {
        #expect(Recipe.read(source).serialized() == source)
    }

    @Test
    func writingAYieldIsIdempotent() {
        let parser = SousParser()
        let written = parser.parseRecipe("---\nyield: [6 servings, 3.2 kg]\n---").value.serialized()

        #expect(written == "---\nyield: [6 servings, 3.2 kg]\n---")
        #expect(parser.parseRecipe(written).value.serialized() == written)
    }

    @Test
    func escapesAYieldItemThatHoldsAListCharacter() {
        let parser = SousParser()
        let recipe = parser.parseRecipe("---\nyield: [1 handful\\, or two]\n---").value

        let written = recipe.serialized()
        #expect(written == "---\nyield: [1 handful\\, or two]\n---")
        #expect(parser.parseRecipe(written).value.metadata == recipe.metadata)
    }

    @Test
    func theRawSubscriptReadsNoListValue() {
        let metadata = Metadata.read("yield: 800 g")

        #expect(metadata["yield"] == nil)
        #expect(metadata.entries.map(\.value) == [.list(["800 g"])])
    }
}
