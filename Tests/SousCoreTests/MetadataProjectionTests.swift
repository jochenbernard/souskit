import SousCore
import Testing

// The typed accessors are views over the raw entry store, so editing the entries moves
// them and the subscript together. Nothing is stored twice and nothing can drift.

@Suite("Metadata projection")
struct MetadataProjectionTests {
    @Test
    func derivesAScalarAccessorFromTheEntries() {
        var metadata = Metadata.read("title: First\ntitle: Second")
        metadata.entries.removeLast()

        #expect(metadata.title == "First")
        #expect(metadata["title"] == "First")
    }

    @Test
    func derivesTheTagsFromTheEntries() {
        var metadata = Metadata.read("tags: [italian]\ntags: [quick]")
        metadata.entries.removeLast()

        #expect(metadata.tags == ["italian"])
    }

    @Test
    func derivesTheServingsFromTheEntries() {
        var metadata = Metadata.read("servings: 2\nservings: 4")
        metadata.entries.removeLast()

        #expect(metadata.servings == 2)
    }

    @Test
    func rendersTheEditedEntriesOnSerialization() {
        var recipe = Recipe.read("---\ntitle: First\ntitle: Second\n---\n\nToast.")
        recipe.metadata.entries.removeLast()

        #expect(recipe.metadata.title == "First")
        #expect(recipe.serialized() == "---\ntitle: First\n---\n\nToast.")
    }

    @Test
    func returnsNilFromTheSubscriptForAnAbsentKey() {
        #expect(Metadata.read("title: Toast")["chef"] == nil)
    }

    @Test
    func returnsNilFromTheSubscriptForAListKey() {
        // The subscript reports the last scalar value, and a list key holds no scalar.
        let metadata = Metadata.read("tags: [italian]")
        #expect(metadata["tags"] == nil)
        #expect(metadata.tags == ["italian"])
    }

    @Test
    func returnsNilFromTheSubscriptForARawEntry() {
        // A preserved line that is not a `key: value` entry holds no value to look up.
        let metadata = Metadata.read("stray line")

        #expect(metadata.entries.count == 1)
        #expect(metadata[""] == nil)
    }

    @Test(arguments: [
        (key: "title", first: "First", last: "Second"),
        (key: "language", first: "en", last: "nl"),
        (key: "version", first: "1.0", last: "1.1"),
        (key: "source", first: "Jane", last: "Jon")
    ])
    func keepsTheLastValueOfEveryRepeatedScalarKey(key: String, first: String, last: String) {
        #expect(Metadata.read("\(key): \(first)\n\(key): \(last)")[key] == last)
    }

    @Test
    func keepsTheLastServingsValueOfARepeatedKey() {
        #expect(Metadata.read("servings: 2\nservings: 4").servings == 4)
    }

    @Test
    func readsAZeroServingsValue() {
        #expect(Metadata.read("servings: 0").servings == 0)
    }

    @Test
    func leavesServingsUnsetForALeadingHyphen() {
        // A leading "-" is not a number, exactly as in an amount fence.
        let metadata = Metadata.read("servings: -2")
        #expect(metadata.servings == nil)
        #expect(metadata["servings"] == "-2")
    }

    @Test
    func doesNotDivideAServingsValueByAZeroDenominator() {
        // The fraction states nothing to divide by, so the value states no number at all.
        #expect(Metadata.read("servings: 1/0").servings == nil)
    }
}
