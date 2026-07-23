import SousCore
import Testing

@Suite("Serialization round-trip")
struct SerializationTests {
    /// The recipe a source reads as, and the recipe its serialized output re-reads as, which
    /// is the pair a round-trip expectation is stated over.
    private func roundTrip(_ source: String) -> (recipe: Recipe, reRead: Recipe) {
        let recipe = Recipe.read(source)

        return (recipe, recipe.reRead())
    }

    /// Expects a source to survive being written back and read again as the same recipe, which
    /// is what the round-trip guarantee promises whatever a writer normalizes on the way out.
    private func expectTheRecipeSurvivesARoundTrip(
        _ source: String,
        sourceLocation: Testing.SourceLocation = #_sourceLocation
    ) {
        let (recipe, reRead) = roundTrip(source)

        #expect(reRead.steps.map(\.segments) == recipe.steps.map(\.segments), sourceLocation: sourceLocation)
        #expect(reRead.metadata == recipe.metadata, sourceLocation: sourceLocation)
    }

    /// Layout a writer is free to normalize: a trailing newline, a run of blank lines, a
    /// whitespace-only line, a fence line with trailing space, and the space an amount fence
    /// is set off from its name by.
    private static let normalizedLayouts = [
        "Toast the bread.\n",
        "Toast the bread.\n\n",
        "\nToast the bread.",
        "First step.\n\n\nSecond step.",
        "---\n---",
        "---\ntitle: Toast\n---\nBody line.",
        "Cook @{200 g}pasta@.",
        "Toast the bread.\n   \nSpread with butter.",
        "--- \ntitle: Toast\n--- ",
        "Add @{200 g}@ now.",
        "Toast the bread\u{2028}and butter it.",
        "---\ntags: [italian, quick] \n---",
        "---\ntags:  [italian, quick]\n---"
    ]

    @Test(arguments: [
        "Toast the bread and spread it with butter.",
        "Fry @garlic@ until fragrant, then add @baby spinach@.",
        "Bring a #large pot# of water to a boil and cook @{200 g} spaghetti@.",
        "Add @{1-2 tbsp} olive oil@ and @{a pinch} salt@.",
        """
        Toast the bread.

        Spread with butter.
        """,
        """
        ---
        title: Garlic Butter Pasta
        servings: 2
        ---

        Melt @{30 g} butter@ in a #pan#, fry @{2 cloves} garlic@.
        """,
        "Mix @salt@@pepper@ in.",
        "Simmer gently for ~40 min~, then rest ~overnight~.",
        "Bake ~8-10 min~ and rest ~1 h 30 min~.",
        "Chill ~over\\~night~ now.",
        "Wait \\~40 min here.",
        "Stir in @{=1 tsp} baking soda@.",
        "Season with @salt@:staple and @black pepper@:staple.",
        "Scatter @rosemary@? over the top.",
        "Scatter @rosemary@?y over the top.",
        "Loosen with @{50 ml} water@:non-food if needed.",
        "Add @{=10 g} salt@:staple now.",
        "Add @water@:staple:non-food now.",
        "Add @salt@:staple?y here.",
        "Add @sauce@:homemade now.",
        "Add @sauce@:homemade?2 now.",
        "Is it @salt@\\? Yes.",
        "Serve @rice@\\:about 200 g each.",
        "Season with @salt@:staple\\?y.",
        "Add @sauce@:homemade\\:more now.",
        "Season with @salt@: to taste.",
        "Use a #{200 g} pan#.",
        "Add @{} salt@.",
        "Season with salt @",
        "Season to taste \\",
        "## Sauce\nBrown the beef.",
        "Layer the >{300 g} bolognese> in a dish.",
        "Read the \\note here.",
        "Note the path C:\\Users, then add @garlic@.",
        "Use a #8\\ pan#.",
        "Path C:\\\\@garlic@ now.",
        "Add @flour\\\\@ now.",
        "  Toast the bread.  ",
        "---\n: Alice\n---",
        "---\ntitle:  Toast\n---",
        "---\ntitle: a: b\n---",
        "---\nprep-time: 15 min\n---",
        "---\ntitle:\n---",
        "---\nnutrition:\n  calories: 640 kcal\n---",
        "---\ntags: [comfort food\\, italian]\n---",
        "---\ntags: [\\[sugar]\n---",
        "---\nsource: C:\\photos\\x\n---"
    ])
    func reproducesTheSourceExactly(source: String) {
        #expect(Recipe.read(source).serialized() == source)
    }

    // A pair of identical sigils reads as ordinary text only while both stay unescaped: the
    // reader closes the span the first one opens on the second one at once, and keeps both.

    @Test(arguments: [
        "Use @@ here.",
        "Use ## here.",
        "Use >> here.",
        "Rate it @@ out of five."
    ])
    func leavesAnInertSigilPairUnescaped(source: String) {
        #expect(Recipe.read(source).serialized() == source)
    }

    @Test(arguments: [
        "\\@\\@garlic\\@ here.",
        "\\#\\#pan\\# here.",
        "\\@\\@garlic\\@",
        "Mix \\@\\@a\\@ into @flour@.",
        "\\@\\@\\@a\\@"
    ])
    func keepsProseWithAnEscapedSigilPairOnRoundTrip(source: String) {
        let (recipe, reRead) = roundTrip(source)

        #expect(reRead.steps.map(\.segments) == recipe.steps.map(\.segments))
        #expect(reRead.ingredients == recipe.ingredients)
    }

    // A flag chain is written in one canonical order: the named flags, then the unrecognized
    // ones in document order, and last of all the optional shorthand. The shorthand goes last
    // because a flag word runs on through letters, so a named flag written before prose that
    // starts with one would read back as a single unrecognized flag.

    @Test(arguments: [
        (source: "Add @water@:non-food:staple now.", written: "Add @water@:staple:non-food now."),
        (source: "Add @salt@:optional now.", written: "Add @salt@? now."),
        (source: "Add @salt@:staple:staple now.", written: "Add @salt@:staple now."),
        (source: "Add @salt@?:staple now.", written: "Add @salt@:staple? now."),
        (source: "Add @sauce@:homemade:staple now.", written: "Add @sauce@:staple:homemade now.")
    ])
    func writesAFlagChainInItsCanonicalOrder(source: String, written: String) {
        #expect(Recipe.read(source).serialized() == written)
    }

    // The inline form is the only one a list is written in, because escaping lets any item
    // survive it.

    @Test
    func escapesASeparatorInAListItem() {
        let source = "---\ntags: comfort food, italian\n---"

        #expect(Recipe.read(source).serialized() == "---\ntags: [comfort food\\, italian]\n---")
    }

    @Test
    func escapesABracketInAListItem() {
        let source = "---\ntags: [italian\n---"

        #expect(Recipe.read(source).serialized() == "---\ntags: [\\[italian]\n---")
    }

    @Test(arguments: [
        "---\ntags: comfort food, italian\n---",
        "---\ntags: [italian\n---",
        "---\ntags: a]b\n---",
        "---\ntags: [a\\]\n---",
        "---\ntags: C:\\x\n---",
        "---\ntags: [a\\\\b, c]\n---",
        "---\ntags: [a, b] \n---"
    ])
    func keepsEveryListItemOnRoundTrip(source: String) {
        let (recipe, reRead) = roundTrip(source)

        #expect(reRead.metadata.tags == recipe.metadata.tags)
        #expect(reRead.metadata.entries == recipe.metadata.entries)
    }

    @Test
    func writesAnEmptyScalarValueWithoutATrailingSpace() {
        #expect(Recipe.read("---\ntitle:\n---").serialized() == "---\ntitle:\n---")
    }

    @Test
    func preservesAnUnrecognizedHeaderKeyOnRoundTrip() {
        let source = """
        ---
        title: Toast
        chef: Alice
        ---
        """

        #expect(Recipe.read(source).serialized() == source)
    }

    @Test
    func preservesAnUnclosedSpanAsLiteralTextOnRoundTrip() {
        let (recipe, reRead) = roundTrip("Fry @garlic until fragrant.")

        #expect(reRead.steps.map(\.segments) == recipe.steps.map(\.segments))
        #expect(reRead.ingredients.isEmpty)
    }

    @Test(arguments: [
        "Add @\\{not a fence@ now.",
        "Use a #8\\# pan#.",
        "Add @a\\@b@ now.",
        "Email \\@user today.",
        "Weigh a \\#5 sieve here."
    ])
    func reEscapesParsedEscapesForByteExactRoundTrip(source: String) {
        #expect(Recipe.read(source).serialized() == source)
    }

    @Test
    func reEscapesAProseSigilAdjacentToAnAnnotation() {
        let source = "\\@@garlic@ now."

        #expect(Recipe.read(source).serialized() == source)
    }

    // An escape that was not needed, such as a sigil already followed by whitespace, loses
    // its backslash on the way out. The recipe it re-reads to is unchanged.

    @Test(arguments: [
        "Add a \\@ symbol here.",
        "Write a \\{ brace here.",
        "All of them: \\@ \\# \\~ \\{ \\: \\? \\\\ done.",
        "Mix @{200 g} flour@ and \\@ the rest.",
        "Halve the \\\\ ratio.",
        "Add @a\\\\b@ now."
    ])
    func normalizesAnUnneededEscapeButPreservesTheRecipe(source: String) {
        expectTheRecipeSurvivesARoundTrip(source)
    }

    // Incidental layout, such as repeated blank lines or a trailing newline, is normalized
    // rather than preserved. What must hold is that the output re-reads to the same recipe,
    // and that normalizing an already normalized file changes nothing further.

    @Test(arguments: normalizedLayouts)
    func normalizingLayoutIsStable(source: String) {
        let parser = SousParser()
        let normalized = parser.parseRecipe(source).value.serialized()

        #expect(parser.parseRecipe(normalized).value.serialized() == normalized)
    }

    @Test(arguments: normalizedLayouts)
    func normalizingLayoutKeepsTheContent(source: String) {
        expectTheRecipeSurvivesARoundTrip(source)
    }

    // A body step that opens with a fence line would read back as a metadata header, so the
    // output keeps it in the body rather than losing it.

    @Test(arguments: [
        "\n---",
        "\n---\nBring the water to a boil.",
        "\n\n--- ",
        "\n---\n\nSpread with butter."
    ])
    func keepsABodyThatOpensWithAFenceLineInTheBody(source: String) {
        let (recipe, reRead) = roundTrip(source)

        #expect(reRead == recipe)
    }

    // A body that opens with a byte-order mark would have it stripped as the file's own on the
    // way back in, so the output keeps it in the body rather than losing it.

    @Test(arguments: [
        "\u{FEFF}",
        "\u{FEFF}x",
        "\n\u{FEFF}",
        "\u{FEFF}\u{FEFF}x",
        "\u{FEFF}\u{FEFF}\n\nSpread with butter."
    ])
    func keepsABodyThatOpensWithAByteOrderMarkInTheBody(source: String) {
        let (recipe, reRead) = roundTrip(source)

        #expect(reRead == recipe)
    }

    @Test
    func doesNotSeparateABodyFenceLineFromAHeaderThatPrecedesIt() {
        let source = "---\ntitle: Toast\n---\n\n---\nBring the water to a boil."

        #expect(Recipe.read(source).serialized() == source)
    }

    @Test
    func reReadingTheOutputYieldsTheSameRecipe() {
        let source = """
        ---
        title: Garlic Pasta
        servings: 2
        tags: [italian, quick]
        ---


        Cook @{200 g}pasta@ in a #large pot#.


        Season with @{a pinch} salt@ and serve.
        """

        let (recipe, reRead) = roundTrip(source)

        #expect(reRead.metadata == recipe.metadata)
        #expect(reRead.steps.count == recipe.steps.count)
        #expect(reRead.ingredients == recipe.ingredients)
        #expect(reRead.cookware == recipe.cookware)
    }
}
