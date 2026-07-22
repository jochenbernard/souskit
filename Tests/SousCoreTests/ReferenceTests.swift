import SousCore
import Testing

// Version 0.4 brings the reference sigil. A ">...>" span names what a step consumes, which in
// this version is the intermediate a named group of the same file produced.
//
// The span is read like every other: the sigil opens one only before a non-whitespace
// character, it closes within its own paragraph, and a span naming nothing is ordinary text.
// It composes with an amount fence, which takes a portion of the intermediate, and with the
// flag chain an ingredient carries.

@Suite("References")
struct ReferenceTests {
    private func recipe(_ source: String) -> Recipe {
        SousParser().parseRecipe(source).value
    }

    private func reference(in source: String) throws -> Reference {
        try #require(recipe(source).references.first)
    }

    // Reading

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
        let segments = try #require(recipe("Spread the >sauce> on top.").steps.first?.segments)

        #expect(segments.count == 3)
        #expect(segments.first?.proseText == "Spread the ")
        #expect(segments.dropFirst().first?.referenceValue?.target == "sauce")
        #expect(segments.last?.proseText == " on top.")
    }

    @Test
    func opensAReferenceAtTheStartOfALine() {
        // A line beginning "> " is the reserved markdown form, which the opener rule already
        // leaves as text, so a line may still open a reference.
        #expect(recipe(">sauce> goes in first.").references.map(\.target) == ["sauce"])
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

    @Test
    func closesAReferenceOnALaterLineOfTheSameParagraph() {
        #expect(recipe("Spread the >sauce\nlayer> on top.").references.map(\.target) == ["sauce\nlayer"])
    }

    @Test
    func doesNotCloseAReferenceAcrossAParagraphBreak() {
        let parsed = SousParser().parseRecipe("Spread the >sauce\n\nlayer> on top.")

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
        #expect(try reference(in: "Spread the >sauces/red> on top.").target == "sauces/red")
    }

    @Test
    func contributesNoIngredient() {
        // The intermediate's ingredients are those of its group's steps, already counted there.
        let value = recipe("## Sauce\nBrown @{500 g} minced beef@.\n\n## Assemble\nLayer the >sauce>.")

        #expect(value.ingredients.map(\.name) == ["minced beef"])
    }

    // The consumption fence

    @Test
    func readsTheConsumptionFence() throws {
        let reference = try reference(in: "Layer the >{300 g} sauce> in a dish.")

        #expect(reference.target == "sauce")
        #expect(reference.amount?.text == "300 g")
        #expect(reference.amount?.kind.preciseQuantity?.value == 300)
        #expect(reference.amount?.unit == "g")
    }

    @Test
    func readsAFenceWithNoSeparatingSpace() throws {
        #expect(try reference(in: "Layer the >{300 g}sauce> in a dish.").target == "sauce")
    }

    @Test
    func readsAFenceStatingNoQuantityAsImprecise() throws {
        let reference = try reference(in: "Spread the >{half} sauce> over it.")

        #expect(reference.target == "sauce")
        #expect(reference.amount?.kind.impreciseText == "half")
    }

    @Test
    func readsTheFixedMarkerInAFence() throws {
        #expect(try reference(in: "Spread the >{=300 g} sauce> over it.").amount?.isFixed == true)
    }

    @Test
    func readsEverySigilInsideAFenceAsText() throws {
        // Sigils are inert between the braces, the span's own included.
        let reference = try reference(in: "Spread the >{>300 g} sauce> over it.")

        #expect(reference.target == "sauce")
        #expect(reference.amount?.kind.impreciseText == ">300 g")
    }

    @Test
    func degradesAReferenceWhoseFenceNeverCloses() {
        let parsed = SousParser().parseRecipe("Spread the >{300 g sauce> over it.")

        #expect(parsed.value.references.isEmpty)
        #expect(parsed.diagnostics.map(\.kind) == [.unclosedSpan])
    }

    // Flags

    @Test
    func readsTheShorthandFlagAfterAReference() throws {
        let reference = try reference(in: "Serve with >chili-oil>? on the side.")

        #expect(reference.target == "chili-oil")
        #expect(reference.flags.isOptional)
    }

    @Test
    func readsAChainOfNamedFlagsAfterAReference() throws {
        let reference = try reference(in: "Serve with >chili-oil>:optional:staple now.")

        #expect(reference.flags.isOptional)
        #expect(reference.flags.isStaple)
    }

    @Test
    func preservesAnUnrecognizedFlagOnAReference() throws {
        let parsed = SousParser().parseRecipe("Serve with >chili-oil>:homemade now.")

        #expect(try #require(parsed.value.references.first).flags.unrecognized == ["homemade"])
        #expect(parsed.diagnostics.map(\.kind) == [.unknownFlag])
    }

    // Projections

    @Test
    func listsItsReferencesOnTheStepTheGroupAndTheRecipe() throws {
        let value = recipe("""
        ## Assemble
        Layer the >sauce> in a dish.

        Dot the >topping> over it.
        """)

        let group = try #require(value.groups.first)
        #expect(group.steps.map({ $0.references.map(\.target) }) == [["sauce"], ["topping"]])
        #expect(group.references.map(\.target) == ["sauce", "topping"])
        #expect(value.references.map(\.target) == ["sauce", "topping"])
    }

    // Writing

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
        #expect(recipe(source).serialized() == source)
    }

    @Test
    func escapesTheClosingSigilInATarget() {
        #expect(recipe("Spread the >a\\>b> on top.").serialized() == "Spread the >a\\>b> on top.")
    }

    @Test
    func escapesProseThatWouldOpenAFlagAfterAReference() {
        // A flag chain reads on from the closing sigil, so prose needing a literal flag
        // character there escapes it, exactly as it does after an ingredient.
        #expect(recipe("Is the >sauce>\\? Yes.").serialized() == "Is the >sauce>\\? Yes.")
    }

    @Test
    func escapesProseThatWouldOpenAReference() {
        #expect(recipe("Reduce by \\>half.").serialized() == "Reduce by \\>half.")
    }
}
