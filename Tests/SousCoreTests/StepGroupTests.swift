import SousCore
import Testing

@Suite("Step groups")
struct StepGroupTests {
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

    @Test(arguments: ["", "---\ntitle: Buttered Toast\n---", "   \n\n  "])
    func holdsNoGroupWhenTheBodyIsEmpty(source: String) {
        #expect(Recipe.read(source).groups.isEmpty)
    }

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
        let parsed = SousParser().parseRecipe("Warm the oven.\n## Sauce")

        #expect(parsed.value.steps.map(\.text) == ["Warm the oven.\n## Sauce"])
        #expect(parsed.value.cookware.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func opensAGroupOnAHeadingAnotherHeadingStandsBefore() {
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

    @Test
    func readsNoHeadingInsideTheHeader() {
        let value = Recipe.read("---\n## Sauce\n---\n\nBrown the beef.")

        #expect(value.groups.map(\.name) == [nil])
        #expect(value.metadata.entries.count == 1)
    }

    @Test(arguments: [
        (source: "## Sauce", name: "Sauce"),
        (source: "## Rich Tomato Sauce", name: "Rich Tomato Sauce"),
        (source: "##  Sauce", name: "Sauce"),
        (source: "## \tSauce ", name: "Sauce"),
        (source: "##\tSauce", name: "Sauce"),
        (source: "## 2", name: "2"),
        (source: "## sauces/red", name: "sauces/red")
    ])
    func readsTheTrimmedNameAfterTheMarker(source: String, name: String) {
        #expect(Recipe.read(source).groups.map(\.name) == [name])
    }

    @Test(arguments: [
        "##Sauce",
        "## ",
        "##",
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

    /// A recipe of three groups, each carrying annotations of every kind.
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
        var value = Recipe.read("Warm the oven.\n\n## Sauce\nBrown.")
        value.groups[1].name = "Topping"

        #expect(value.serialized() == "Warm the oven.\n\n## Topping\nBrown.")
    }

    @Test
    func dropsTheEscapeALineInsideAStepDoesNotNeed() {
        let written = Recipe.read("Warm the oven.\n\\## Sauce").serialized()

        #expect(written == "Warm the oven.\n## Sauce")
        #expect(Recipe.read(written).steps.map(\.text) == ["Warm the oven.\n## Sauce"])
    }

    @Test
    func escapesABackslashInANameThatWouldOtherwiseEscapeWhatFollowsIt() {
        #expect(Recipe.read("## Sauce \\\\@ Home").serialized() == "## Sauce \\\\@ Home")
    }

    @Test(arguments: [
        "\\## Sauce",
        "\\## @a@",
        "\\## #p#",
        "\\## ~4 h~",
        "\\## >a>",
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
        let written = Recipe.read("## Sauce \\@ Home").serialized()

        #expect(written == "## Sauce @ Home")
        #expect(Recipe.read(written).groups.map(\.name) == ["Sauce @ Home"])
    }
}
