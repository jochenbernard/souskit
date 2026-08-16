import SousCore
import Testing

@Suite("Step groups")
struct StepGroupTests {
    @Test
    func opensAGroupOnAHeading() throws {
        let parsed = SousParser().parseRecipe("## Pastry\nRub in the butter.")

        let group = try #require(parsed.value.groups.first)
        #expect(parsed.value.groups.count == 1)
        #expect(group.name == "Pastry")
        #expect(group.steps.map(\.text) == ["Rub in the butter."])
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func attributesEveryStepUpToTheNextHeadingToItsGroup() {
        let source = """
        ## Pastry
        Rub in the butter.

        Chill it well.

        ## Filling
        Whisk the eggs.
        """

        let value = Recipe.read(source)
        #expect(value.groups.map(\.name) == ["Pastry", "Filling"])
        #expect(value.groups.map({ $0.steps.map(\.text) }) == [
            ["Rub in the butter.", "Chill it well."],
            ["Whisk the eggs."]
        ])
    }

    @Test
    func formsTheDefaultGroupFromTheStepsBeforeAnyHeading() {
        let source = """
        Warm the oven.

        ## Pastry
        Rub in the butter.
        """

        let value = Recipe.read(source)
        #expect(value.groups.map(\.name) == [nil, "Pastry"])
        #expect(value.groups.first?.steps.map(\.text) == ["Warm the oven."])
    }

    @Test
    func holdsABodyWritingNoHeadingInOneUnnamedGroup() {
        let value = Recipe.read("Whisk the vinegar.\n\nBeat in the oil.")

        #expect(value.groups.map(\.name) == [nil])
        #expect(value.groups.first?.steps.count == 2)
    }

    @Test(arguments: ["", "---\ntitle: Vinaigrette\n---", "   \n\n  "])
    func holdsNoGroupWhenTheBodyIsEmpty(source: String) {
        #expect(Recipe.read(source).groups.isEmpty)
    }

    @Test
    func readsAHeadingNoBlankLineEndsTheStepBeforeAsProse() {
        let source = """
        Warm the oven.
        ## Pastry
        Rub in the butter.
        """

        let value = Recipe.read(source)
        #expect(value.groups.map(\.name) == [nil])
        #expect(value.steps.map(\.text) == [source])
    }

    @Test
    func readsNoAnnotationInAHeadingReadAsProse() {
        let parsed = SousParser().parseRecipe("Warm the oven.\n## Pastry")

        #expect(parsed.value.steps.map(\.text) == ["Warm the oven.\n## Pastry"])
        #expect(parsed.value.cookware.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func opensAGroupOnAHeadingAnotherHeadingStandsBefore() {
        let value = Recipe.read("## Pastry\n## Filling\nWhisk the eggs.")

        #expect(value.groups.map(\.name) == ["Pastry", "Filling"])
        #expect(value.groups.map({ $0.steps.map(\.text) }) == [[], ["Whisk the eggs."]])
    }

    @Test
    func keepsAHeadingThatOpensNoStep() {
        let source = """
        ## Pastry

        ## Filling
        Whisk the eggs.
        """

        let value = Recipe.read(source)
        #expect(value.groups.map(\.name) == ["Pastry", "Filling"])
        #expect(value.groups.first?.steps.isEmpty == true)
    }

    @Test
    func readsAHeadingAfterAWindowsLineEnding() {
        let value = Recipe.read("## Pastry\r\nRub in the butter.")

        #expect(value.groups.map(\.name) == ["Pastry"])
        #expect(value.steps.map(\.text) == ["Rub in the butter."])
    }

    @Test
    func readsNoHeadingInsideTheHeader() {
        let value = Recipe.read("---\n## Pastry\n---\n\nRub in the butter.")

        #expect(value.groups.map(\.name) == [nil])
        #expect(value.metadata.entries.count == 1)
    }

    @Test(arguments: [
        (source: "## Pastry", name: "Pastry"),
        (source: "## Court-Bouillon", name: "Court-Bouillon"),
        (source: "##  Pastry", name: "Pastry"),
        (source: "## \tPastry ", name: "Pastry"),
        (source: "##\tPastry", name: "Pastry"),
        (source: "## 2", name: "2"),
        (source: "## sauces/rouille", name: "sauces/rouille")
    ])
    func readsTheTrimmedNameAfterTheMarker(source: String, name: String) {
        #expect(Recipe.read(source).groups.map(\.name) == [name])
    }

    @Test(arguments: [
        "##Pastry",
        "## ",
        "##",
        "##   ",
        "## \t",
        " ## Pastry",
        "### Pastry",
        "#Pastry#",
        "\t## Pastry"
    ])
    func opensNoGroupOnALineThatIsNotAHeading(source: String) {
        let value = Recipe.read(source)

        #expect(value.groups.map(\.name) == [nil])
        #expect(value.steps.map(\.text) == [source])
    }

    @Test(arguments: [
        (source: "## Pastry \\@ Home", name: "Pastry @ Home"),
        (source: "## Pastry \\\\ Home", name: "Pastry \\ Home"),
        (source: "## a\\>b", name: "a>b"),
        (source: "## a\\#b", name: "a#b"),
        (source: "## a\\zb", name: "a\\zb")
    ])
    func resolvesEachEscapeInAName(source: String, name: String) {
        #expect(Recipe.read(source).groups.map(\.name) == [name])
    }

    @Test
    func readsNoAnnotationInsideAName() {
        let parsed = SousParser().parseRecipe("## Pastry #casserole# with @salt@ and ~5 min~")

        #expect(parsed.value.groups.map(\.name) == ["Pastry #casserole# with @salt@ and ~5 min~"])
        #expect(parsed.value.cookware.isEmpty)
        #expect(parsed.value.ingredients.isEmpty)
        #expect(parsed.value.timers.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    /// A recipe of three groups whose steps carry ingredients, cookware, timers, and references
    /// between them.
    private var quicheLorraine: Recipe {
        Recipe.read("""
        ## Pastry
        Rub @{125 g} butter@ into @{250 g} flour@ in a #mixing bowl# and rest it ~30 min~.

        ## Filling
        Whisk @{4} eggs@ with @{300 ml} cream@.

        ## Assemble
        Line a #tart tin# with the >pastry> and pour in the >filling>.
        """)
    }

    @Test
    func attributesTheAnnotationsOfAStepToItsGroup() {
        let groups = quicheLorraine.groups

        #expect(groups.map({ $0.ingredients.map(\.name) }) == [
            ["butter", "flour"], ["eggs", "cream"], []
        ])
        #expect(groups.map({ $0.cookware.map(\.name) }) == [["mixing bowl"], [], ["tart tin"]])
        #expect(groups.map({ $0.timers.map(\.text) }) == [["30 min"], [], []])
        #expect(groups.map({ $0.references.map(\.target) }) == [[], [], ["pastry", "filling"]])
    }

    @Test
    func readsEveryStepOfEveryGroupInDocumentOrder() {
        let value = quicheLorraine

        #expect(value.steps.map(\.text) == value.groups.flatMap({ $0.steps.map(\.text) }))
        #expect(value.steps.count == 3)
    }

    @Test
    func readsTheRecipeWideListsAcrossEveryGroup() {
        let value = quicheLorraine

        #expect(value.ingredients.map(\.name) == ["butter", "flour", "eggs", "cream"])
        #expect(value.cookware.map(\.name) == ["mixing bowl", "tart tin"])
        #expect(value.timers.map(\.text) == ["30 min"])
        #expect(value.references.map(\.target) == ["pastry", "filling"])
    }

    @Test
    func writesEachGroupUnderItsHeading() {
        let source = """
        ## Pastry
        Rub in the butter.

        Chill it well.

        ## Filling
        Whisk the eggs.
        """

        #expect(Recipe.read(source).serialized() == source)
    }

    @Test(arguments: [
        "## Pastry\nRub in the butter.",
        "Warm the oven.\n\n## Pastry\nRub in the butter.",
        "## Pastry\n\n## Filling\nWhisk the eggs.",
        "## Pastry",
        "---\ntitle: Quiche Lorraine\n---\n\n## Pastry\nRub in the butter."
    ])
    func writesAGroupBackAsItWasRead(source: String) {
        #expect(Recipe.read(source).serialized() == source)
    }

    @Test
    func writesTheBlankLineAHeadingNeedsBeforeIt() {
        var value = Recipe.read("Warm the oven.\n\n## Pastry\nRub.")
        value.groups[1].name = "Filling"

        #expect(value.serialized() == "Warm the oven.\n\n## Filling\nRub.")
    }

    @Test
    func dropsTheEscapeALineInsideAStepDoesNotNeed() {
        let written = Recipe.read("Warm the oven.\n\\## Pastry").serialized()

        #expect(written == "Warm the oven.\n## Pastry")
        #expect(Recipe.read(written).steps.map(\.text) == ["Warm the oven.\n## Pastry"])
    }

    @Test
    func escapesABackslashInANameThatWouldOtherwiseEscapeWhatFollowsIt() {
        #expect(Recipe.read("## Pastry \\\\@ Home").serialized() == "## Pastry \\\\@ Home")
    }

    @Test(arguments: [
        "\\## Pastry",
        "\\## @a@",
        "\\## #p#",
        "\\## ~4 h~",
        "\\## >a>",
        "Mix it,\n## then rest it.",
        "Add @a\n## b@ now.",
        "## Pastry\nMix it,\n## then rest it.",
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
        let written = Recipe.read("## Pastry \\@ Home").serialized()

        #expect(written == "## Pastry @ Home")
        #expect(Recipe.read(written).groups.map(\.name) == ["Pastry @ Home"])
    }
}
