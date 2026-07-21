import SousCore
import Testing

// The typed accessors are views over the raw entry store, so editing the entries moves
// them and the subscript together. Nothing is stored twice and nothing can drift.

@Suite("Metadata projection")
struct MetadataProjectionTests {
    @Test
    func derivesAScalarAccessorFromTheEntries() {
        var metadata = SousParser().parseRecipe("---\ntitle: First\ntitle: Second\n---").value.metadata
        metadata.entries.removeLast()

        #expect(metadata.title == "First")
        #expect(metadata["title"] == "First")
    }

    @Test
    func derivesTheTagsFromTheEntries() {
        var metadata = SousParser().parseRecipe("---\ntags: [italian]\ntags: [quick]\n---").value.metadata
        metadata.entries.removeLast()

        #expect(metadata.tags == ["italian"])
    }

    @Test
    func derivesTheServingsFromTheEntries() {
        var metadata = SousParser().parseRecipe("---\nservings: 2\nservings: 4\n---").value.metadata
        metadata.entries.removeLast()

        #expect(metadata.servings == 2)
    }

    @Test
    func rendersTheEditedEntriesOnSerialization() {
        var recipe = SousParser().parseRecipe("---\ntitle: First\ntitle: Second\n---\n\nToast.").value
        recipe.metadata.entries.removeLast()

        #expect(recipe.metadata.title == "First")
        #expect(recipe.serialized() == "---\ntitle: First\n---\n\nToast.")
    }

    @Test
    func returnsNilFromTheSubscriptForAnAbsentKey() {
        #expect(SousParser().parseRecipe("---\ntitle: Toast\n---").value.metadata["chef"] == nil)
    }

    @Test
    func returnsNilFromTheSubscriptForAListKey() {
        // The subscript reports the last scalar value, and a list key holds no scalar.
        let metadata = SousParser().parseRecipe("---\ntags: [italian]\n---").value.metadata
        #expect(metadata["tags"] == nil)
        #expect(metadata.tags == ["italian"])
    }

    @Test
    func returnsNilFromTheSubscriptForARawEntry() {
        // A preserved line that is not a `key: value` entry holds no value to look up.
        let metadata = SousParser().parseRecipe("---\nstray line\n---").value.metadata

        #expect(metadata.entries.count == 1)
        #expect(metadata[""] == nil)
    }

    @Test(arguments: [
        (key: "language", first: "en", last: "nl"),
        (key: "version", first: "1.0", last: "1.1"),
        (key: "source", first: "Jane", last: "Jon")
    ])
    func keepsTheLastValueOfEveryRepeatedScalarKey(key: String, first: String, last: String) {
        let source = "---\n\(key): \(first)\n\(key): \(last)\n---"

        #expect(SousParser().parseRecipe(source).value.metadata[key] == last)
    }

    @Test
    func keepsTheLastServingsValueOfARepeatedKey() {
        let source = "---\nservings: 2\nservings: 4\n---"

        #expect(SousParser().parseRecipe(source).value.metadata.servings == 4)
    }

    @Test
    func readsAZeroServingsValue() {
        #expect(SousParser().parseRecipe("---\nservings: 0\n---").value.metadata.servings == 0)
    }

    @Test
    func leavesServingsUnsetForALeadingHyphen() {
        // A leading "-" is not a number, exactly as in an amount fence.
        let metadata = SousParser().parseRecipe("---\nservings: -2\n---").value.metadata
        #expect(metadata.servings == nil)
        #expect(metadata["servings"] == "-2")
    }

    @Test
    func doesNotDivideAServingsValueByAZeroDenominator() {
        #expect(SousParser().parseRecipe("---\nservings: 1/0\n---").value.metadata.servings == 1)
    }
}
