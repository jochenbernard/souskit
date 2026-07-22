import SousCore
import Testing

// The escaping the writer produces has to undo exactly what the reader resolves, and the
// two are easy to drift apart on inputs no hand-written example thinks of. These suites
// check every string of a bounded length over the characters the reader gives a meaning
// to, so a gap between them cannot survive unnoticed.
//
// The round-trip contract is semantic, so what must survive is the recipe: its header
// entries and its step segments. Incidental layout may change, but only once, so writing
// the re-read recipe must reproduce the same text.

@Suite("Exhaustive round-trip")
struct ExhaustiveRoundTripTests {
    private func roundTripFailure(_ source: String) -> String? {
        let parser = SousParser()
        let recipe = parser.parseRecipe(source).value
        let written = recipe.serialized()
        let reRead = parser.parseRecipe(written)

        if reRead.value.metadata != recipe.metadata {
            return "\(source.debugDescription) wrote \(written.debugDescription), losing header entries"
        }
        if reRead.value.groups.map(\.name) != recipe.groups.map(\.name) {
            return "\(source.debugDescription) wrote \(written.debugDescription), losing groups"
        }
        if reRead.value.groups.map({ $0.steps.map(\.segments) })
            != recipe.groups.map({ $0.steps.map(\.segments) }) {
            return "\(source.debugDescription) wrote \(written.debugDescription), losing step segments"
        }
        if reRead.diagnostics.contains(where: { $0.kind == .unclosedSpan }) {
            return "\(source.debugDescription) wrote \(written.debugDescription), which is not well-formed"
        }
        if reRead.value.serialized() != written {
            return "\(source.debugDescription) wrote \(written.debugDescription), then "
                + "\(reRead.value.serialized().debugDescription)"
        }

        return nil
    }

    /// Every string of up to `length` pieces drawn from `alphabet`, the empty string included.
    private func strings(over alphabet: [String], upTo length: Int) -> [String] {
        var all = [""]
        var longest = [""]

        for _ in 0..<length {
            longest = longest.flatMap({ prefix in alphabet.map({ prefix + $0 }) })
            all += longest
        }

        return all
    }

    private func expectRoundTrips(
        _ alphabet: [String],
        upTo length: Int,
        prefix: String = "",
        suffix: String = ""
    ) {
        expectNoFailures(strings(over: alphabet, upTo: length)
            .compactMap({ roundTripFailure(prefix + $0 + suffix) }))
    }

    /// Reported as one line, because a broken escape rule fails on hundreds of inputs at once.
    private func expectNoFailures(_ failures: [String]) {
        let report = failures.isEmpty ? "" : "\(failures.count) failures, the first being that \(failures[0])"

        #expect(report.isEmpty)
    }

    @Test(arguments: [
        ["@", "#", "{", "}", "\\", "a", " "],
        ["@", "#", "~", ">", "\\", "a"],
        ["@", "#", "\n", "\\", "a", " "],
        ["@", "{", "}", "\\"]
    ])
    func everyBodyOverTheSigilsAndEscapes(alphabet: [String]) {
        expectRoundTrips(alphabet, upTo: 4)
    }

    @Test(arguments: [["@", "\\", "a"], ["#", "\\", "a"], ["@", "#", "\\"]])
    func everyDeeplyEscapedBody(alphabet: [String]) {
        expectRoundTrips(alphabet, upTo: 7)
    }

    @Test
    func everyAmountFence() {
        expectRoundTrips(["0", ".", "/", "-", "=", " ", "g", "}"], upTo: 4, prefix: "Add @{", suffix: "} water@.")
    }

    // Scaling writes amounts nobody wrote, so what it writes has to read back as what it
    // states. The quantity and the unit decide that together: a whole quantity, one space,
    // and a fraction is a mixed number, whichever side of the space each character came from.

    // One digit reaches every shape a quantity takes, so a second only multiplies the sweep.
    // Seven characters is the shortest fence that scales into a mixed number, `1/1 1/1`.

    @Test(arguments: [0.5, 2.0, 4.0])
    func everyScaledAmountFence(factor: Double) {
        let parser = SousParser()

        expectNoFailures(strings(over: ["1", ".", "/", " "], upTo: 7).compactMap({ fence -> String? in
            let source = "Add @{\(fence)} water@."
            guard let scaled = try? parser.parseRecipe(source).value.scaled(by: factor) else { return nil }

            let written = scaled.serialized()
            guard parser.parseRecipe(written).value.steps.map(\.segments) != scaled.steps.map(\.segments)
            else { return nil }

            return "\(source.debugDescription) scaled by \(factor) wrote \(written.debugDescription)"
        }))
    }

    @Test
    func everyReferenceContent() {
        expectRoundTrips([">", "{", "}", "\\", "a", " "], upTo: 4, prefix: "Spread the >", suffix: "> now.")
    }

    // A heading is a line-level construct, so what decides it is the shape of the whole line:
    // the two hashes, the one space after them, and whether a name follows.

    @Test(arguments: [
        ["#", " ", "\n", "\\", ">"],
        ["## a", "\n", "a", " ", "#"]
    ])
    func everyHeadingLine(alphabet: [String]) {
        expectRoundTrips(alphabet, upTo: 4)
    }

    // A heading needs five characters to be written out of content, an escaped one included, so
    // this is the shortest sweep that reaches content a reader would take for a heading.

    @Test(arguments: ["", "Add @", "Use a #", "Wait ~", "Spread the >"])
    func everyContentThatCouldOpenAHeading(prefix: String) {
        expectRoundTrips(["#", " ", "\n", "\\", "a"], upTo: 5, prefix: prefix)
    }

    @Test
    func everyTimerContent() {
        expectRoundTrips(["~", "\\", "4", "-", " ", "h"], upTo: 4, prefix: "Wait ~", suffix: "~ now.")
    }

    @Test
    func everyFlagPunctuation() {
        // A number ends a flag word without opening one, so it borders the chain from a side
        // no other character does.
        expectRoundTrips([":", "?", "-", "a", "2", " ", "\\"], upTo: 4, prefix: "Add @salt@")
    }

    @Test
    func everyFlagChain() {
        expectRoundTrips(
            [":", "?", "staple", "non-food", "optional", "homemade", " x"],
            upTo: 3,
            prefix: "Add @salt@"
        )
    }

    @Test
    func everyListValue() {
        expectRoundTrips(["[", "]", ",", "\\", "a", " "], upTo: 4, prefix: "---\ntags: ", suffix: "\n---")
    }

    @Test
    func everyYieldValue() {
        // The yield key is a list key like tags, so the same escaping has to survive it, and
        // each item is additionally read as an amount.
        expectRoundTrips(["[", "]", ",", "\\", "2", " ", "g"], upTo: 4, prefix: "---\nyield: ", suffix: "\n---")
    }

    @Test
    func everyScalarValue() {
        expectRoundTrips(["[", "]", ",", "\\", ":", " ", "a"], upTo: 4, prefix: "---\ntitle: ", suffix: "\n---")
    }

    @Test
    func everyHeaderLine() {
        expectRoundTrips(["-", ":", " ", "a", "\n", "["], upTo: 4, prefix: "---\n", suffix: "\n---")
    }

    @Test
    func everyFileOverFencesAndSigils() {
        expectRoundTrips(["-", "\n", "a", "@", " ", ":"], upTo: 4)
    }

    @Test
    func everyFileOverByteOrderMarksAndFences() {
        expectRoundTrips(["\u{FEFF}", "-", "\n", "a"], upTo: 5)
    }

    @Test
    func everyFileOverWholeConstructs() {
        let constructs = [
            "@{2 g} a@", "#p#", "\\@", "\n\n", "\n", "---\n", "@a@", "tags: [a, b]\n",
            "~4 h~", "@a@?", "@a@:staple", "@{=2 g} a@", ">a>", ">{2 g} a>", ">a>?", "## a"
        ]

        expectRoundTrips(constructs, upTo: 3)
    }
}
