import SousCore
import Testing

// Version 0.4 divides a body into groups. A line of "##", one space, and a name opens one,
// every step up to the next heading belongs to it, and the steps written before any heading
// form the unnamed default group.
//
// The heading is a line-level construct rather than an inline annotation, so it is read before
// the body is divided into paragraphs and its name holds no annotation of its own. The name is
// captured the way a fenced name is: one space separates it from the "##" and belongs to
// neither, a second begins the name, and each escape reads as the single character.

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

    @Test
    func endsTheParagraphBeforeAHeadingWithNoBlankLine() {
        let source = """
        Warm the oven.
        ## Sauce
        Brown the beef.
        """

        let value = Recipe.read(source)
        #expect(value.groups.map(\.name) == [nil, "Sauce"])
        #expect(value.steps.map(\.text) == ["Warm the oven.", "Brown the beef."])
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
        // One space separates the name from the "##" and belongs to neither, exactly as the
        // one space after an amount fence does; a second begins the name.
        (source: "##  Sauce", name: " Sauce"),
        (source: "## Sauce ", name: "Sauce "),
        (source: "## 2", name: "2"),
        // A name is a single-segment label, so a path separator in one is ordinary text.
        (source: "## sauces/red", name: "sauces/red")
    ])
    func readsTheNameAfterOneSeparatingSpace(source: String, name: String) {
        #expect(Recipe.read(source).groups.map(\.name) == [name])
    }

    // A heading is a line of "##", one space, and a name. A line shaped any other way is
    // ordinary prose, which the reader already keeps as text.

    @Test(arguments: [
        "##Sauce",
        "## ",
        "##",
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
    func writesABlankLineBetweenAStepAndTheHeadingAfterIt() {
        // A heading ends the paragraph before it, so it is read back the same either way, and
        // the blank line every block is separated by is the layout the writer produces.
        #expect(Recipe.read("Warm the oven.\n## Sauce\nBrown.").serialized()
            == "Warm the oven.\n\n## Sauce\nBrown.")
    }

    @Test
    func escapesABackslashInANameThatWouldOtherwiseEscapeWhatFollowsIt() {
        #expect(Recipe.read("## Sauce \\\\@ Home").serialized() == "## Sauce \\\\@ Home")
    }

    // A heading is decided by the shape of a whole line, so content written at the start of one
    // is escaped wherever it would otherwise be read as a heading rather than as itself. The
    // escape reads back as the character, so the content survives either way.
    //
    // The line a run of content sits on is not the run: what a segment before it wrote is on
    // that line too, and what a segment after it writes continues it. So a run ending at the
    // bare marker opens a heading the next segment names, and a run opening with the second
    // hash completes a marker the segment before it began.

    @Test(arguments: [
        "Mix it,\n\\## then rest it.",
        "Add @a\n\\## b@ now.",
        "Use a #a\n\\## b# now.",
        "Wait ~4\n\\## h~ now.",
        "Spread the >a\n\\## b> now.",
        "\\## Sauce",
        "Mix it,\n\\##  rest it.",
        "## Sauce\nMix it,\n\\## then rest it.",
        // The name comes from the segment written after the run.
        "\\## @a@",
        "\\## #p#",
        "\\## ~4 h~",
        "\\## >a>",
        "Mix.\n\\## @salt@ in.",
        "Add @x\n\\## @ now.",
        "Add @{2 g} x\n\\## @ now.",
        "Add @x\n\\## @? now.",
        // The first hash of the marker comes from the segment written before the run.
        "Use a #x\n#\\# # now.",
        "Use a #x\n#\\#  now."
    ])
    func escapesContentThatWouldOtherwiseBeReadAsAHeading(source: String) {
        let recipe = SousParser().parseRecipe(source).value
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
