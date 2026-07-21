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
        if reRead.value.steps.map(\.segments) != recipe.steps.map(\.segments) {
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
        let failures = strings(over: alphabet, upTo: length)
            .compactMap({ roundTripFailure(prefix + $0 + suffix) })
        // Reported as one line, because a broken escape rule fails on hundreds of inputs at once.
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

    @Test
    func everyTimerContent() {
        expectRoundTrips(["~", "\\", "4", "-", " ", "h"], upTo: 4, prefix: "Wait ~", suffix: "~ now.")
    }

    @Test
    func everyFlagPunctuation() {
        expectRoundTrips([":", "?", "-", "a", " ", "\\"], upTo: 4, prefix: "Add @salt@")
    }

    @Test
    func everyFlagChain() {
        let pieces = [":", "?", "staple", "non-food", "optional", "homemade", " x"]

        expectRoundTrips(pieces, upTo: 3, prefix: "Add @salt@")
    }

    @Test
    func everyListValue() {
        expectRoundTrips(["[", "]", ",", "\\", "a", " "], upTo: 4, prefix: "---\ntags: ", suffix: "\n---")
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
            "~4 h~", "@a@?", "@a@:staple", "@{=2 g} a@"
        ]

        expectRoundTrips(constructs, upTo: 3)
    }
}
