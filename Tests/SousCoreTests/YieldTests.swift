import SousCore
import Testing

// The `yield` header field, available since v0.3. It is a list key, so one yield and several
// are the same shape, and each item reads as an amount exactly as an amount fence does.

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
        // The key is recognized from v0.3, so it is no longer reported as unknown.
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
    func readsEveryQuantityFormOfAYield(value: String, quantity: Double, unit: String) throws {
        let metadata = SousParser().parseRecipe("---\nyield: \(value)\n---").value.metadata

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

    // A repeated list key combines its occurrences and warns, exactly as `tags` does.

    @Test
    func combinesRepeatedYieldKeysAndWarns() {
        let parsed = SousParser().parseRecipe("---\nyield: 800 g\nyield: 12 muffins\n---")

        #expect(parsed.value.metadata.yields.map(\.text) == ["800 g", "12 muffins"])
        #expect(parsed.diagnostics.map(\.kind) == [.repeatedListKey])
    }

    @Test
    func readsAYieldWithNoLeadingNumberAsImprecise() throws {
        let metadata = SousParser().parseRecipe("---\nyield: plenty\n---").value.metadata

        let yield = try #require(metadata.yields.first)
        #expect(yield.kind.impreciseText == "plenty")
        #expect(yield.unit == nil)
    }

    @Test
    func readsAYieldRangeAsARange() throws {
        let metadata = SousParser().parseRecipe("---\nyield: 10-12 muffins\n---").value.metadata

        let yield = try #require(metadata.yields.first)
        #expect(yield.kind.rangeQuantities?.low.value == 10.0)
        #expect(yield.kind.rangeQuantities?.high.value == 12.0)
        #expect(yield.unit == "muffins")
    }

    @Test
    func statesNoYieldsWhenTheKeyIsAbsentOrEmpty() {
        #expect(SousParser().parseRecipe("---\ntitle: Pancakes\n---").value.metadata.yields.isEmpty)
        #expect(SousParser().parseRecipe("---\nyield:\n---").value.metadata.yields.isEmpty)
    }

    // The fixed marker belongs to the amount fence, which no header value has, so a leading
    // `=` is ordinary text here exactly as it is in a timer.

    @Test
    func readsAYieldOpeningWithTheFixedMarkerAsImprecise() throws {
        let metadata = SousParser().parseRecipe("---\nyield: =800 g\n---").value.metadata

        let yield = try #require(metadata.yields.first)
        #expect(yield.kind.impreciseText == "=800 g")
        #expect(yield.unit == nil)
        #expect(!yield.isFixed)
    }

    @Test
    func readsNoServingsFromAValueOpeningWithTheFixedMarker() {
        #expect(SousParser().parseRecipe("---\nservings: =4\n---").value.metadata.servings == nil)
    }

    // A header value is read with the whitespace around it removed, so one that moves is
    // rewritten from what it states rather than from how it was spaced.

    @Test
    func scalingAHeaderValueDropsTheWhitespaceAroundIt() throws {
        let recipe = try SousParser().parseRecipe("---\nservings:  6 \n---").value.scaled(by: 2.0)

        #expect(recipe.metadata["servings"] == "12")
    }

    @Test
    func readsTheLeadingQuantityOfAServingsRange() {
        #expect(SousParser().parseRecipe("---\nservings: 4-6\n---").value.metadata.servings == 4.0)
    }

    // `servings` is an alias for a portion yield, but it stays its own accessor, because
    // reading it as one is what scaling does rather than what the store holds.

    @Test
    func servingsIsNotListedAmongTheYields() {
        let metadata = SousParser().parseRecipe("---\nservings: 4\n---").value.metadata

        #expect(metadata.servings == 4)
        #expect(metadata.yields.isEmpty)
    }

    // The list rules of v0.1 apply unchanged, so only a well-formed inline list reads as
    // several items and the escapes inside one are resolved.

    @Test(arguments: [
        (value: "[800 g", items: ["[800 g"]),
        (value: "[6 servings], [3.2 kg]", items: ["[6 servings], [3.2 kg]"]),
        (value: "[12 muffins, , 800 g,]", items: ["12 muffins", "800 g"]),
        (value: "[1 handful\\, or two]", items: ["1 handful, or two"])
    ])
    func readsAYieldValueUnderTheInlineListRules(value: String, items: [String]) {
        let metadata = SousParser().parseRecipe("---\nyield: \(value)\n---").value.metadata

        #expect(metadata.yields.map(\.text) == items)
    }

    @Test
    func writesYieldsInTheInlineForm() {
        let recipe = SousParser().parseRecipe("---\nyield: 800 g\n---").value

        #expect(recipe.serialized() == "---\nyield: [800 g]\n---")
    }

    // A list of nothing has no inline form to write, so the key ends at the separator, which
    // is what leaves the block form a later version introduces exactly as it was written.

    @Test(arguments: ["---\nyield:\n---", "---\nyield:\n  - 800 g\n---"])
    func writesAYieldOfNoItemsAsTheKeyAlone(source: String) {
        #expect(SousParser().parseRecipe(source).value.serialized() == source)
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

    // The raw store still holds what was written, and the subscript reads scalars only, so a
    // list key answers nothing through it.

    @Test
    func theRawSubscriptReadsNoListValue() {
        let metadata = SousParser().parseRecipe("---\nyield: 800 g\n---").value.metadata

        #expect(metadata["yield"] == nil)
        #expect(metadata.entries.map(\.value) == [.list(["800 g"])])
    }
}
