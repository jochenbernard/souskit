import SousCore
import Testing

@Suite("References")
struct ReferenceTests {
    @Test
    func readsAReferenceBetweenPairedSigils() throws {
        let parsed = SousParser().parseRecipe("Spread the >sauce> on top.")

        let reference = try #require(parsed.value.references.first)
        #expect(reference.target == "sauce")
        #expect(reference.amount == nil)
        #expect(!reference.flags.isOptional)
        #expect(!reference.flags.isStaple)
        #expect(!reference.flags.isNonFood)
        #expect(reference.flags.unrecognized.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsAReferenceAsItsOwnSegment() throws {
        let segments = try #require(Recipe.read("Spread the >sauce> on top.").steps.first?.segments)

        #expect(segments.count == 3)
        #expect(segments.first?.proseText == "Spread the ")
        #expect(segments.dropFirst().first?.referenceValue?.target == "sauce")
        #expect(segments.last?.proseText == " on top.")
    }

    @Test
    func opensAReferenceAtTheStartOfALine() {
        #expect(Recipe.read(">sauce> goes in first.").references.map(\.target) == ["sauce"])
    }

    @Test
    func doesNotOpenAReferenceWhenTheSigilIsFollowedByWhitespace() {
        let parsed = SousParser().parseRecipe("Reduce by > half> now.")

        #expect(parsed.value.references.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func doesNotProduceAReferenceWithAnEmptyTarget() {
        let parsed = SousParser().parseRecipe("Use >> here.")

        #expect(parsed.value.references.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func recoversFromAnUnclosedReferenceSpan() {
        let parsed = SousParser().parseRecipe("Spread the >sauce on top.")

        #expect(parsed.value.references.isEmpty)
        #expect(parsed.diagnostics.map(\.kind) == [.unclosedSpan])
        #expect(parsed.diagnostics.allSatisfy({ $0.severity == .warning }))
    }

    @Test(arguments: ["Spread the >sauce\nlayer> on top.", "Spread the >sauce\n\nlayer> on top."])
    func doesNotCloseAReferenceAcrossALineBreak(source: String) {
        let parsed = SousParser().parseRecipe(source)

        #expect(parsed.value.references.isEmpty)
        #expect(parsed.diagnostics.map(\.kind) == [.unclosedSpan])
    }

    @Test
    func resolvesAnEscapedSigilInsideATarget() throws {
        let parsed = SousParser().parseRecipe("Spread the >a\\>b> on top.")

        #expect(try #require(parsed.value.references.first).target == "a>b")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsATargetHoldingAPathSeparator() throws {
        #expect(try #require(Recipe.read("Spread the >sauces/red> on top.").firstReference).target == "sauces/red")
    }

    @Test
    func contributesNoIngredient() {
        let value = Recipe.read("## Sauce\nBrown @{500 g} minced beef@.\n\n## Assemble\nLayer the >sauce>.")

        #expect(value.ingredients.map(\.name) == ["minced beef"])
    }

    @Test
    func readsTheConsumptionFence() throws {
        let reference = try #require(Recipe.read("Layer the >{300 g} sauce> in a dish.").firstReference)

        #expect(reference.target == "sauce")
        #expect(reference.amount?.text == "300 g")
        #expect(reference.amount?.kind.preciseQuantity?.value == 300)
        #expect(reference.amount?.unit == "g")
    }

    @Test
    func readsAFenceWithNoSeparatingSpace() throws {
        #expect(try #require(Recipe.read("Layer the >{300 g}sauce> in a dish.").firstReference).target == "sauce")
    }

    @Test(arguments: ["Layer the >{300 g}  sauce> in a dish.", "Layer the >{300 g} sauce > in a dish."])
    func trimsTheWhitespaceAroundATarget(source: String) throws {
        #expect(try #require(Recipe.read(source).firstReference).target == "sauce")
        #expect(Recipe.read(source).serialized() == "Layer the >{300 g} sauce> in a dish.")
    }

    @Test
    func readsAFenceStatingNoQuantityAsImprecise() throws {
        let reference = try #require(Recipe.read("Spread the >{half} sauce> over it.").firstReference)

        #expect(reference.target == "sauce")
        #expect(reference.amount?.kind.impreciseText == "half")
    }

    @Test
    func readsTheFixedMarkerInAFence() throws {
        let reference = try #require(Recipe.read("Spread the >{=300 g} sauce> over it.").firstReference)
        #expect(reference.amount?.isFixed == true)
    }

    @Test
    func readsEverySigilInsideAFenceAsText() throws {
        let reference = try #require(Recipe.read("Spread the >{>300 g} sauce> over it.").firstReference)

        #expect(reference.target == "sauce")
        #expect(reference.amount?.kind.impreciseText == ">300 g")
    }

    @Test
    func degradesAReferenceWhoseFenceNeverCloses() {
        let parsed = SousParser().parseRecipe("Spread the >{300 g sauce> over it.")

        #expect(parsed.value.references.isEmpty)
        #expect(parsed.diagnostics.map(\.kind) == [.unclosedSpan])
    }

    @Test
    func readsTheShorthandFlagAfterAReference() throws {
        let reference = try #require(Recipe.read("Serve with >chili-oil>? on the side.").firstReference)

        #expect(reference.target == "chili-oil")
        #expect(reference.flags.isOptional)
    }

    @Test
    func readsAChainOfNamedFlagsAfterAReference() throws {
        let reference = try #require(Recipe.read("Serve with >chili-oil>:optional:staple now.").firstReference)

        #expect(reference.flags.isOptional)
        #expect(reference.flags.isStaple)
    }

    @Test
    func preservesAnUnrecognizedFlagOnAReference() throws {
        let parsed = SousParser().parseRecipe("Serve with >chili-oil>:homemade now.")

        #expect(try #require(parsed.value.references.first).flags.unrecognized == ["homemade"])
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func listsItsReferencesOnTheStepTheGroupAndTheRecipe() throws {
        let value = Recipe.read("""
        ## Assemble
        Layer the >sauce> in a dish.

        Dot the >topping> over it.
        """)

        let group = try #require(value.groups.first)
        #expect(group.steps.map({ $0.references.map(\.target) }) == [["sauce"], ["topping"]])
        #expect(group.references.map(\.target) == ["sauce", "topping"])
        #expect(value.references.map(\.target) == ["sauce", "topping"])
    }

    @Test(arguments: [
        "Spread the >sauce> on top.",
        "Layer the >{300 g} bolognese> in a dish.",
        "Spread the >{half} sauce> over it.",
        "Serve with >chili-oil>? on the side.",
        "Serve with >chili-oil>:staple? on the side.",
        ">sauce> goes in first.",
        "Spread the >sauces/red> on top."
    ])
    func writesAReferenceBackAsItWasRead(source: String) {
        #expect(Recipe.read(source).serialized() == source)
    }

    @Test
    func escapesTheClosingSigilInATarget() {
        #expect(Recipe.read("Spread the >a\\>b> on top.").serialized() == "Spread the >a\\>b> on top.")
    }

    @Test
    func escapesProseThatWouldOpenAFlagAfterAReference() {
        #expect(Recipe.read("Is the >sauce>\\? Yes.").serialized() == "Is the >sauce>\\? Yes.")
    }

    @Test
    func escapesProseThatWouldOpenAReference() {
        #expect(Recipe.read("Reduce by \\>half.").serialized() == "Reduce by \\>half.")
    }
}
