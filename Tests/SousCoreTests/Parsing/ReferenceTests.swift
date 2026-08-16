import SousCore
import Testing

@Suite("References")
struct ReferenceTests {
    @Test
    func readsAReferenceBetweenPairedSigils() throws {
        let parsed = SousParser().parseRecipe("Spread the >bechamel> on top.")

        let reference = try #require(parsed.value.references.first)
        #expect(reference.target == "bechamel")
        #expect(reference.amount == nil)
        #expect(!reference.flags.isOptional)
        #expect(!reference.flags.isStaple)
        #expect(!reference.flags.isNonFood)
        #expect(reference.flags.unrecognized.isEmpty)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsAReferenceAsItsOwnSegment() throws {
        let segments = try #require(Recipe.read("Spread the >bechamel> on top.").steps.first?.segments)

        #expect(segments.count == 3)
        #expect(segments.first?.proseText == "Spread the ")
        #expect(segments.dropFirst().first?.referenceValue?.target == "bechamel")
        #expect(segments.last?.proseText == " on top.")
    }

    @Test
    func opensAReferenceAtTheStartOfALine() {
        #expect(Recipe.read(">bechamel> goes in first.").references.map(\.target) == ["bechamel"])
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
        let parsed = SousParser().parseRecipe("Spread the >bechamel on top.")

        #expect(parsed.value.references.isEmpty)
        #expect(parsed.diagnostics.map(\.kind) == [.unclosedSpan])
        #expect(parsed.diagnostics.allSatisfy({ $0.severity == .warning }))
    }

    @Test(arguments: ["Spread the >bechamel\nlayer> on top.", "Spread the >bechamel\n\nlayer> on top."])
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
        let reference = try #require(Recipe.read("Spread the >sauces/rouille> on top.").firstReference)

        #expect(reference.target == "sauces/rouille")
    }

    @Test
    func contributesNoIngredient() {
        let value = Recipe.read("## Filling\nBrown @{500 g} beef@.\n\n## Assemble\nLayer the >filling>.")

        #expect(value.ingredients.map(\.name) == ["beef"])
    }

    @Test
    func readsTheConsumptionFence() throws {
        let reference = try #require(Recipe.read("Layer the >{300 g} bechamel> in a dish.").firstReference)

        #expect(reference.target == "bechamel")
        #expect(reference.amount?.text == "300 g")
        #expect(reference.amount?.kind.preciseQuantity?.value == 300)
        #expect(reference.amount?.unit == "g")
    }

    @Test
    func readsAFenceWithNoSeparatingSpace() throws {
        #expect(try #require(Recipe.read("Layer the >{300 g}bechamel> in a dish.").firstReference).target == "bechamel")
    }

    @Test(arguments: ["Layer the >{300 g}  bechamel> in a dish.", "Layer the >{300 g} bechamel > in a dish."])
    func trimsTheWhitespaceAroundATarget(source: String) throws {
        #expect(try #require(Recipe.read(source).firstReference).target == "bechamel")
        #expect(Recipe.read(source).serialized() == "Layer the >{300 g} bechamel> in a dish.")
    }

    @Test
    func readsAFenceStatingNoQuantityAsImprecise() throws {
        let reference = try #require(Recipe.read("Spread the >{half} bechamel> over it.").firstReference)

        #expect(reference.target == "bechamel")
        #expect(reference.amount?.kind.impreciseText == "half")
    }

    @Test
    func readsTheFixedMarkerInAFence() throws {
        let reference = try #require(Recipe.read("Spread the >{=300 g} bechamel> over it.").firstReference)
        #expect(reference.amount?.isFixed == true)
    }

    @Test
    func readsEverySigilInsideAFenceAsText() throws {
        let reference = try #require(Recipe.read("Spread the >{>300 g} bechamel> over it.").firstReference)

        #expect(reference.target == "bechamel")
        #expect(reference.amount?.kind.impreciseText == ">300 g")
    }

    @Test
    func degradesAReferenceWhoseFenceNeverCloses() {
        let parsed = SousParser().parseRecipe("Spread the >{300 g bechamel> over it.")

        #expect(parsed.value.references.isEmpty)
        #expect(parsed.diagnostics.map(\.kind) == [.unclosedSpan])
    }

    @Test
    func readsTheShorthandFlagAfterAReference() throws {
        let reference = try #require(Recipe.read("Serve with >court-bouillon>? on the side.").firstReference)

        #expect(reference.target == "court-bouillon")
        #expect(reference.flags.isOptional)
    }

    @Test
    func readsAChainOfNamedFlagsAfterAReference() throws {
        let reference = try #require(Recipe.read("Serve with >court-bouillon>:optional:staple now.").firstReference)

        #expect(reference.flags.isOptional)
        #expect(reference.flags.isStaple)
    }

    @Test
    func preservesAnUnrecognizedFlagOnAReference() throws {
        let parsed = SousParser().parseRecipe("Serve with >court-bouillon>:homemade now.")

        #expect(try #require(parsed.value.references.first).flags.unrecognized == ["homemade"])
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func listsItsReferencesOnTheStepTheGroupAndTheRecipe() throws {
        let value = Recipe.read("""
        ## Assemble
        Layer the >bechamel> in a dish.

        Dot the >rouille> over it.
        """)

        let group = try #require(value.groups.first)
        #expect(group.steps.map({ $0.references.map(\.target) }) == [["bechamel"], ["rouille"]])
        #expect(group.references.map(\.target) == ["bechamel", "rouille"])
        #expect(value.references.map(\.target) == ["bechamel", "rouille"])
    }

    @Test(arguments: [
        "Spread the >bechamel> on top.",
        "Layer the >{300 g} rouille> in a dish.",
        "Spread the >{half} bechamel> over it.",
        "Serve with >court-bouillon>? on the side.",
        "Serve with >court-bouillon>:staple? on the side.",
        ">bechamel> goes in first.",
        "Spread the >sauces/rouille> on top."
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
        #expect(Recipe.read("Is the >bechamel>\\? Yes.").serialized() == "Is the >bechamel>\\? Yes.")
    }

    @Test
    func escapesProseThatWouldOpenAReference() {
        #expect(Recipe.read("Reduce by \\>half.").serialized() == "Reduce by \\>half.")
    }
}
