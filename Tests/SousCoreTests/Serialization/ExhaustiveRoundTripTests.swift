import SousCore
import Testing

@Suite("Exhaustive round-trip")
struct ExhaustiveRoundTripTests {
    /// How a source fails to round-trip, or `nil` when it survives.
    ///
    /// Checks the header, the group names, the segments, that the result is well-formed, and
    /// that writing it a second time is stable.
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
        if
            reRead.value.groups.map({ $0.steps.map(\.segments) })
                != recipe.groups.map({ $0.steps.map(\.segments) })
        {
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

    /// Every string of up to the given length over the alphabet, the empty string included.
    ///
    /// The count grows as the alphabet size to the power of the length, so raising either is
    /// expensive.
    private func strings(over alphabet: [String], upTo length: Int) -> [String] {
        var all = [""]
        var longest = [""]

        for _ in 0..<length {
            longest = longest.flatMap({ prefix in alphabet.map({ prefix + $0 }) })
            all += longest
        }

        return all
    }

    /// Expects every string over the alphabet, wrapped in the prefix and suffix, to round-trip.
    private func expectRoundTrips(
        _ alphabet: [String],
        upTo length: Int,
        prefix: String = "",
        suffix: String = ""
    ) {
        TestSupport.expectNoFailures(strings(over: alphabet, upTo: length)
            .compactMap({ roundTripFailure(prefix + $0 + suffix) }))
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
        expectRoundTrips(
            ["0", ".", "/", "-", "=", " ", "g", "}"],
            upTo: 4,
            prefix: "Add @{",
            suffix: "} cream@."
        )
    }

    @Test(arguments: [0.5, 2.0, 4.0])
    func everyScaledAmountFence(factor: Double) {
        let parser = SousParser()

        TestSupport.expectNoFailures(strings(over: ["1", ".", "/", " "], upTo: 7).compactMap { fence -> String? in
            let source = "Add @{\(fence)} cream@."
            guard let scaled = try? parser.parseRecipe(source).value.scaled(by: factor) else { return nil }

            let written = scaled.serialized()
            guard parser.parseRecipe(written).value.steps.map(\.segments) != scaled.steps.map(\.segments) else {
                return nil
            }

            return "\(source.debugDescription) scaled by \(factor) wrote \(written.debugDescription)"
        })
    }

    @Test
    func everyReferenceContent() {
        expectRoundTrips(
            [">", "{", "}", "\\", "a", " "],
            upTo: 4,
            prefix: "Spread the >",
            suffix: "> now."
        )
    }

    @Test(arguments: [
        ["#", " ", "\n", "\\", ">"],
        ["## a", "\n", "a", " ", "#"]
    ])
    func everyHeadingLine(alphabet: [String]) {
        expectRoundTrips(alphabet, upTo: 4)
    }

    @Test(arguments: ["", "Add @", "Use a #", "Wait ~", "Spread the >"])
    func everyContentThatCouldOpenAHeading(prefix: String) {
        expectRoundTrips(
            ["#", " ", "\n", "\\", "a"],
            upTo: 5,
            prefix: prefix
        )
    }

    @Test(arguments: ["@a@", "#p#", ">a>", "~4 h~"])
    func everyContentThatCouldOpenAHeadingBeforeAnAnnotation(suffix: String) {
        expectRoundTrips(
            ["#", " ", "\n", "\\", "a"],
            upTo: 5,
            suffix: suffix
        )
    }

    @Test
    func everyContentThatCouldOpenAHeadingAfterASpanEndingALine() {
        expectRoundTrips(
            ["#", " ", "\\", "a", "\n"],
            upTo: 5,
            prefix: "Use a #x\n"
        )
    }

    @Test
    func everyTimerContent() {
        expectRoundTrips(
            ["~", "\\", "4", "-", " ", "h"],
            upTo: 4,
            prefix: "Wait ~",
            suffix: "~ now."
        )
    }

    @Test
    func everyFlagPunctuation() {
        expectRoundTrips(
            [":", "?", "-", "a", "2", " ", "\\"],
            upTo: 4,
            prefix: "Add @salt@"
        )
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
        expectRoundTrips(
            ["[", "]", ",", "\\", "a", " "],
            upTo: 4,
            prefix: "---\ntags: ",
            suffix: "\n---"
        )
    }

    @Test
    func everyYieldValue() {
        expectRoundTrips(
            ["[", "]", ",", "\\", "2", " ", "g"],
            upTo: 4,
            prefix: "---\nyield: ",
            suffix: "\n---"
        )
    }

    @Test
    func everyScalarValue() {
        expectRoundTrips(
            ["[", "]", ",", "\\", ":", " ", "a"],
            upTo: 4,
            prefix: "---\ntitle: ",
            suffix: "\n---"
        )
    }

    @Test
    func everyHeaderLine() {
        expectRoundTrips(
            ["-", ":", " ", "a", "\n", "["],
            upTo: 4,
            prefix: "---\n",
            suffix: "\n---"
        )
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
            "~4 h~", "@a@?", "@a@:staple", "@{=2 g} a@", ">a>", ">{2 g} a>", ">a>?", "## a",
            "\\## ", "## "
        ]

        expectRoundTrips(constructs, upTo: 3)
    }
}
