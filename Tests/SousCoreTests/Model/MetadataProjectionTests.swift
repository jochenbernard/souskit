import SousCore
import Testing

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
        var metadata = Metadata.read("tags: [french]\ntags: [quick]")
        metadata.entries.removeLast()

        #expect(metadata.tags == ["french"])
    }

    @Test
    func derivesTheServingsFromTheEntries() {
        var metadata = Metadata.read("servings: 2\nservings: 4")
        metadata.entries.removeLast()

        #expect(metadata.servings == 2)
    }

    @Test
    func returnsNilFromTheSubscriptForAnAbsentKey() {
        #expect(Metadata.read("title: Vinaigrette")["chef"] == nil)
    }

    @Test
    func returnsNilFromTheSubscriptForAListKey() {
        let metadata = Metadata.read("tags: [french]")
        #expect(metadata["tags"] == nil)
        #expect(metadata.tags == ["french"])
    }

    @Test
    func returnsNilFromTheSubscriptForARawEntry() {
        let metadata = Metadata.read("stray line")

        #expect(metadata.entries.count == 1)
        #expect(metadata[""] == nil)
    }

    @Test(arguments: [
        (key: "title", first: "First", last: "Second"),
        (key: "language", first: "en", last: "nl"),
        (key: "version", first: "1.0", last: "1.1"),
        (key: "source", first: "Camille", last: "Bruno")
    ])
    func keepsTheLastValueOfEveryRepeatedScalarKey(
        key: String,
        first: String,
        last: String
    ) {
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
        let metadata = Metadata.read("servings: -2")
        #expect(metadata.servings == nil)
        #expect(metadata["servings"] == "-2")
    }

    @Test
    func doesNotDivideAServingsValueByAZeroDenominator() {
        #expect(Metadata.read("servings: 1/0").servings == nil)
    }

    @Test
    func rendersTheEditedEntriesOnSerialization() {
        var recipe = Recipe.read("---\ntitle: First\ntitle: Second\n---\n\nWhisk the vinegar.")
        recipe.metadata.entries.removeLast()

        #expect(recipe.metadata.title == "First")
        #expect(recipe.serialized() == "---\ntitle: First\n---\n\nWhisk the vinegar.")
    }
}
