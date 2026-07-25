import SousCore
import Testing

// Version 0.4 divides a body into groups. A line of "##", one space, and a name opens one,
// every step up to the next heading belongs to it, and the steps written before any heading
// form the unnamed default group.
//
// A heading opens a group only where no step line stands directly before it, so a blank line
// ends the step before it, another heading, or the start of the body is what lets one open. A
// heading line a step continues is that step's prose, so no heading splits a step.
//
// The heading is a line-level construct rather than an inline annotation, so its name holds no
// annotation of its own. The name is captured the way a fenced name is: one space separates it
// from the "##" and belongs to neither, a second begins the name, and each escape reads as the
// single character.

@Suite("Step groups")
struct StepGroupTests {
    // Reading a heading

    @Test
    func opensAGroupOnAHeading() throws {
        let parsed = SousParser().parseRecipe("## Sauce\nBrown the beef.")

        let group = try #require(parsed.value.groups.first)
        #expect(parsed.value.groups.count == 1)
        #expect(group.name == "Sauce")
        #expect(group.steps.map(\.text) == ["Brown the beef."])
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func attributesEveryStepUpToTheNextHeadingToItsGroup() {
        let source = """
        ## Sauce
        Brown the beef.

        Simmer it down.

        ## Topping
        Grate the cheese.
        """

        let value = Recipe.read(source)
        #expect(value.groups.map(\.name) == ["Sauce", "Topping"])
        #expect(value.groups.map({ $0.steps.map(\.text) }) == [
            ["Brown the beef.", "Simmer it down."],
            ["Grate the cheese."]
        ])
    }

    @Test
    func formsTheDefaultGroupFromTheStepsBeforeAnyHeading() {
        let source = """
        Warm the oven.

        ## Sauce
        Brown the beef.
        """

        let value = Recipe.read(source)
        #expect(value.groups.map(\.name) == [nil, "Sauce"])
        #expect(value.groups.first?.steps.map(\.text) == ["Warm the oven."])
    }

    @Test
    func holdsABodyWritingNoHeadingInOneUnnamedGroup() {
        let value = Recipe.read("Toast the bread.\n\nSpread with butter.")

        #expect(value.groups.map(\.name) == [nil])
        #expect(value.groups.first?.steps.count == 2)
    }

    // The default group is the steps before the first heading, so a body opening with one
    // forms no default group, and a file with no body forms no group at all.

    @Test(arguments: ["", "---\ntitle: Buttered Toast\n---", "   \n\n  "])
    func holdsNoGroupWhenTheBodyIsEmpty(source: String) {
        #expect(Recipe.read(source).groups.isEmpty)
    }

    // A blank line is what ends the step before a heading. With none, the line is the prose of
    // the step it continues, so a heading never splits one.

    @Test
    func readsAHeadingNoBlankLineEndsTheStepBeforeAsProse() {
        let source = """
        Warm the oven.
        ## Sauce
        Brown the beef.
        """

        let value = Recipe.read(source)
        #expect(value.groups.map(\.name) == [nil])
        #expect(value.steps.map(\.text) == [source])
    }

    @Test
    func readsNoAnnotationInAHeadingReadAsProse() {
        // The two hashes close the span the first opens at once, so the line naming no cookware
        // is what the reader already does with a span that names nothing.
        let parsed = SousParser().parseRecipe("Warm the oven.\n## Sauce")

        #expect(parsed.value.steps.map(\.text) == ["Warm the oven.\n## Sauce"])
        #expect(parsed.value.cookware.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func opensAGroupOnAHeadingAnotherHeadingStandsBefore() {
        // A heading is no step, so a group holding none leaves the heading after it opening one.
        let value = Recipe.read("## Sauce\n## Topping\nGrate the cheese.")

        #expect(value.groups.map(\.name) == ["Sauce", "Topping"])
        #expect(value.groups.map({ $0.steps.map(\.text) }) == [[], ["Grate the cheese."]])
    }

    @Test
    func keepsAHeadingThatOpensNoStep() {
        let source = """
        ## Sauce

        ## Topping
        Grate the cheese.
        """

        let value = Recipe.read(source)
        #expect(value.groups.map(\.name) == ["Sauce", "Topping"])
        #expect(value.groups.first?.steps.isEmpty == true)
    }

    @Test
    func readsAHeadingAfterAWindowsLineEnding() {
        let value = Recipe.read("## Sauce\r\nBrown the beef.")

        #expect(value.groups.map(\.name) == ["Sauce"])
        #expect(value.steps.map(\.text) == ["Brown the beef."])
    }

    // A heading line inside the header is a header line, because the body starts after the
    // closing fence.

    @Test
    func readsNoHeadingInsideTheHeader() {
        let value = Recipe.read("---\n## Sauce\n---\n\nBrown the beef.")

        #expect(value.groups.map(\.name) == [nil])
        #expect(value.metadata.entries.count == 1)
    }

    // The name

    @Test(arguments: [
        (source: "## Sauce", name: "Sauce"),
        (source: "## Rich Tomato Sauce", name: "Rich Tomato Sauce"),
        // The name is trimmed, exactly as a fenced name is, so the whitespace separating it
        // from the "##" belongs to neither, whatever it is built from.
        (source: "##  Sauce", name: "Sauce"),
        (source: "## \tSauce ", name: "Sauce"),
        (source: "##\tSauce", name: "Sauce"),
        (source: "## 2", name: "2"),
        // A name is a single-segment label, so a path separator in one is ordinary text.
        (source: "## sauces/red", name: "sauces/red")
    ])
    func readsTheTrimmedNameAfterTheMarker(source: String, name: String) {
        #expect(Recipe.read(source).groups.map(\.name) == [name])
    }

    // A heading is a line of "##", one space, and a name. A line shaped any other way is
    // ordinary prose, which the reader already keeps as text.

    @Test(arguments: [
        "##Sauce",
        "## ",
        "##",
        // A name trimmed away leaves the line naming nothing, as an empty one does.
        "##   ",
        "## \t",
        " ## Sauce",
        "### Sauce",
        "#Sauce#",
        "\t## Sauce"
    ])
    func opensNoGroupOnALineThatIsNotAHeading(source: String) {
        let value = Recipe.read(source)

        #expect(value.groups.map(\.name) == [nil])
        #expect(value.steps.map(\.text) == [source])
    }

    @Test(arguments: [
        (source: "## Sauce \\@ Home", name: "Sauce @ Home"),
        (source: "## Sauce \\\\ Home", name: "Sauce \\ Home"),
        (source: "## a\\>b", name: "a>b"),
        (source: "## a\\#b", name: "a#b"),
        // A backslash before a character the language gives no meaning to is ordinary text.
        (source: "## a\\zb", name: "a\\zb")
    ])
    func resolvesEachEscapeInAName(source: String, name: String) {
        #expect(Recipe.read(source).groups.map(\.name) == [name])
    }

    @Test
    func readsNoAnnotationInsideAName() {
        let parsed = SousParser().parseRecipe("## Sauce #pan# with @salt@ and ~5 min~")

        #expect(parsed.value.groups.map(\.name) == ["Sauce #pan# with @salt@ and ~5 min~"])
        #expect(parsed.value.cookware.isEmpty)
        #expect(parsed.value.ingredients.isEmpty)
        #expect(parsed.value.timers.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    // Attribution

    private var pastaBake: Recipe {
        Recipe.read("""
        ## Sauce
        Brown @{500 g} minced beef@ in a #pan# and simmer ~30 min~.

        ## Topping
        Mix @{200 g} ricotta@ with @{50 g} parmesan@.

        ## Assemble
        Layer the >sauce> in a #baking dish# and dot the >topping> over it.
        """)
    }

    @Test
    func attributesTheAnnotationsOfAStepToItsGroup() {
        let groups = pastaBake.groups

        #expect(groups.map({ $0.ingredients.map(\.name) }) == [
            ["minced beef"], ["ricotta", "parmesan"], []
        ])
        #expect(groups.map({ $0.cookware.map(\.name) }) == [["pan"], [], ["baking dish"]])
        #expect(groups.map({ $0.timers.map(\.text) }) == [["30 min"], [], []])
        #expect(groups.map({ $0.references.map(\.target) }) == [[], [], ["sauce", "topping"]])
    }

    @Test
    func readsEveryStepOfEveryGroupInDocumentOrder() {
        let value = pastaBake

        #expect(value.steps.map(\.text) == value.groups.flatMap({ $0.steps.map(\.text) }))
        #expect(value.steps.count == 3)
    }

    @Test
    func readsTheRecipeWideListsAcrossEveryGroup() {
        let value = pastaBake

        #expect(value.ingredients.map(\.name) == ["minced beef", "ricotta", "parmesan"])
        #expect(value.cookware.map(\.name) == ["pan", "baking dish"])
        #expect(value.timers.map(\.text) == ["30 min"])
        #expect(value.references.map(\.target) == ["sauce", "topping"])
    }

    // Writing

    @Test
    func writesEachGroupUnderItsHeading() {
        let source = """
        ## Sauce
        Brown the beef.

        Simmer it down.

        ## Topping
        Grate the cheese.
        """

        #expect(Recipe.read(source).serialized() == source)
    }

    @Test(arguments: [
        "## Sauce\nBrown the beef.",
        "Warm the oven.\n\n## Sauce\nBrown the beef.",
        "## Sauce\n\n## Topping\nGrate the cheese.",
        "## Sauce",
        "---\ntitle: Pasta Bake\n---\n\n## Sauce\nBrown the beef."
    ])
    func writesAGroupBackAsItWasRead(source: String) {
        #expect(Recipe.read(source).serialized() == source)
    }

    @Test
    func writesTheBlankLineAHeadingNeedsBeforeIt() {
        // The blank line every block is separated by is what leaves the heading opening a group
        // rather than continuing the step before it.
        var value = Recipe.read("Warm the oven.\n\n## Sauce\nBrown.")
        value.groups[1].name = "Topping"

        #expect(value.serialized() == "Warm the oven.\n\n## Topping\nBrown.")
    }

    @Test
    func dropsTheEscapeALineInsideAStepDoesNotNeed() {
        // A heading opens no group where a step line stands before it, so a line inside a step
        // is prose whatever its shape and needs no escape to stay that way.
        let written = Recipe.read("Warm the oven.\n\\## Sauce").serialized()

        #expect(written == "Warm the oven.\n## Sauce")
        #expect(Recipe.read(written).steps.map(\.text) == ["Warm the oven.\n## Sauce"])
    }

    @Test
    func escapesABackslashInANameThatWouldOtherwiseEscapeWhatFollowsIt() {
        #expect(Recipe.read("## Sauce \\\\@ Home").serialized() == "## Sauce \\\\@ Home")
    }

    // A heading is decided by the shape of a whole line, and only the line a step opens with
    // can be one, so content written there is escaped wherever it would otherwise be read as a
    // heading rather than as itself. The escape reads back as the character, so the content
    // survives either way, and a line inside a step needs none.
    //
    // The line a run of content sits on is not the run: what a segment before it wrote is on
    // that line too, and what a segment after it writes continues it. So a run ending at the
    // bare marker opens a heading the next segment names, and a run opening with the second
    // hash completes a marker the segment before it began.

    @Test(arguments: [
        // The step opens with the content, where a heading would open a group.
        "\\## Sauce",
        // The name comes from the segment written after the run.
        "\\## @a@",
        "\\## #p#",
        "\\## ~4 h~",
        "\\## >a>",
        // A line inside a step, which opens no group and so needs no escape. The exhaustive
        // sweeps cover the rest of the shapes such a line takes.
        "Mix it,\n## then rest it.",
        "Add @a\n## b@ now.",
        "## Sauce\nMix it,\n## then rest it.",
        "Mix.\n## @salt@ in.",
        "Use a #x\n## # now."
    ])
    func preservesContentThatCouldBeReadAsAHeading(source: String) {
        let recipe = Recipe.read(source)
        let reRead = SousParser().parseRecipe(recipe.serialized())

        #expect(reRead.value.groups.map(\.name) == recipe.groups.map(\.name))
        #expect(reRead.value.steps.map(\.segments) == recipe.steps.map(\.segments))
        #expect(reRead.diagnostics.isEmpty)
    }

    @Test
    func dropsAnEscapeANameDoesNotNeed() {
        // A heading name holds no annotation, so a sigil in one needs no escape to read back
        // as itself, and a writer may drop an escape the text does not need.
        let written = Recipe.read("## Sauce \\@ Home").serialized()

        #expect(written == "## Sauce @ Home")
        #expect(Recipe.read(written).groups.map(\.name) == ["Sauce @ Home"])
    }
}
