import SousCore
import Testing

@Suite("Timers")
struct TimerTests {
    @Test
    func parsesAPreciseDuration() throws {
        let parsed = SousParser().parseRecipe("Simmer gently for ~40 min~.")

        let timer = try #require(parsed.value.firstTimer)
        #expect(timer.kind == .precise)
        #expect(timer.text == "40 min")
        #expect(timer.components.count == 1)
        #expect(timer.components.first?.kind.preciseQuantity?.value == 40.0)
        #expect(timer.components.first?.unit == "min")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func trimsTheWhitespaceAroundADuration() throws {
        // A duration is read as an amount fence is, and the content is trimmed as one, so the
        // unit ends where the text does.
        let timer = try #require(Recipe.read("Simmer gently for ~40 min ~.").firstTimer)

        #expect(timer.kind == .precise)
        #expect(timer.text == "40 min")
        #expect(timer.components.map(\.unit) == ["min"])
    }

    @Test
    func parsesARangeDuration() throws {
        let timer = try #require(Recipe.read("Bake for ~8-10 min~.").firstTimer)
        #expect(timer.kind == .range)
        #expect(timer.components.count == 1)

        let range = try #require(timer.components.first?.kind.rangeQuantities)
        #expect(range.low.value == 8.0)
        #expect(range.high.value == 10.0)
        #expect(timer.components.first?.unit == "min")
    }

    @Test
    func parsesACompoundDuration() throws {
        let timer = try #require(Recipe.read("Rest for ~1 h 30 min~.").firstTimer)
        #expect(timer.kind == .compound)
        #expect(timer.components.count == 2)
        #expect(timer.components.compactMap({ $0.kind.preciseQuantity?.value }) == [1.0, 30.0])
        #expect(timer.components.map(\.unit) == ["h", "min"])
        #expect(timer.components.map(\.text) == ["1 h", "30 min"])
    }

    // A range is read before the parts of a compound are, so a separator whitespace stands
    // around states one duration rather than opening a second part.

    @Test(arguments: ["8 - 10 min", "8- 10 min", "8 -10 min"])
    func parsesARangeWhateverWhitespaceSurroundsItsSeparator(content: String) throws {
        let timer = try #require(Recipe.read("Bake for ~\(content)~.").firstTimer)

        #expect(timer.kind == .range)
        #expect(timer.components.count == 1)
        #expect(timer.components.first?.kind.rangeQuantities?.low.value == 8.0)
        #expect(timer.components.first?.kind.rangeQuantities?.high.value == 10.0)
        #expect(timer.components.first?.unit == "min")
    }

    @Test
    func parsesACompoundDurationOfMoreThanTwoParts() throws {
        let timer = try #require(Recipe.read("Hold for ~1 h 30 min 15 s~.").firstTimer)
        #expect(timer.kind == .compound)
        #expect(timer.components.map(\.unit) == ["h", "min", "s"])
    }

    @Test
    func parsesACompoundDurationWhoseLastPartIsARange() throws {
        let timer = try #require(Recipe.read("Prove for ~1 h 20-30 min~.").firstTimer)
        #expect(timer.kind == .compound)
        #expect(timer.components.count == 2)
        #expect(timer.components.last?.kind.rangeQuantities?.low.value == 20.0)
    }

    @Test(arguments: ["overnight", "a few minutes", "until the edges lift"])
    func parsesAQualitativeDuration(content: String) throws {
        let parsed = SousParser().parseRecipe("Chill ~\(content)~ before serving.")

        let timer = try #require(parsed.value.firstTimer)
        #expect(timer.kind == .qualitative)
        #expect(timer.components.isEmpty)
        #expect(timer.text == content)
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func treatsADurationWithNoLeadingNumberAsQualitative() throws {
        // The quantity is a leading run, exactly as in an amount fence, so a word before the
        // number leaves the duration with no numeric value at all.
        let timer = try #require(Recipe.read("Rest ~about 40 min~.").firstTimer)
        #expect(timer.kind == .qualitative)
        #expect(timer.components.isEmpty)
        #expect(timer.text == "about 40 min")
    }

    @Test
    func readsADurationWithNoUnit() throws {
        let timer = try #require(Recipe.read("Wait ~40~ and check.").firstTimer)
        #expect(timer.kind == .precise)
        #expect(timer.components.first?.kind.preciseQuantity?.value == 40.0)
        #expect(timer.components.first?.unit?.isEmpty == true)
    }

    @Test
    func readsAMultiWordUnit() throws {
        let timer = try #require(Recipe.read("Leave ~2 whole days~ in the fridge.").firstTimer)
        #expect(timer.kind == .precise)
        #expect(timer.components.first?.unit == "whole days")
    }

    @Test(arguments: [
        (content: "1.5 h", value: 1.5),
        (content: "1/2 h", value: 0.5),
        (content: "1 1/2 h", value: 1.5)
    ])
    func readsTheSameQuantityFormsAsAnAmountFence(content: String, value: Double) throws {
        let timer = try #require(Recipe.read("Prove for ~\(content)~.").firstTimer)
        #expect(timer.kind == .precise)
        #expect(timer.components.first?.kind.preciseQuantity?.value == value)
        #expect(timer.components.first?.unit == "h")
    }

    @Test
    func startsANewPartOnlyAtAWhitespaceSeparatedNumber() throws {
        // A digit inside a unit belongs to that unit, so only a number that starts its own
        // word opens the next part of a compound duration.
        let timer = try #require(Recipe.read("Chill ~2 8oz jars~ before filling.").firstTimer)
        #expect(timer.kind == .compound)
        #expect(timer.components.map(\.unit) == ["", "oz jars"])
    }

    @Test
    func doesNotReadAnAmountFenceInATimer() throws {
        // A timer carries a single duration, so it takes no amount fence and the braces are
        // ordinary characters of its text.
        let parsed = SousParser().parseRecipe("Wait ~{40 min}~ now.")

        let timer = try #require(parsed.value.firstTimer)
        #expect(timer.kind == .qualitative)
        #expect(timer.text == "{40 min}")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func readsSeveralTimersFromOneStep() throws {
        let step = try #require(Recipe.read("Refrigerate ~overnight~, then bake ~20-25 min~.").firstStep)
        #expect(step.timers.map(\.text) == ["overnight", "20-25 min"])
        #expect(step.timers.map(\.kind) == [.qualitative, .range])
    }

    @Test
    func unescapesAnEscapedSigilInsideATimer() throws {
        let parsed = SousParser().parseRecipe("Chill ~over\\~night~ now.")

        let timer = try #require(parsed.value.firstTimer)
        #expect(timer.text == "over~night")
        #expect(timer.kind == .qualitative)
        #expect(parsed.diagnostics.isEmpty)
    }

    // The kind is a view over the components rather than a value of its own, so it always
    // states what the components hold.

    @Test
    func classifiesTheKindFromTheComponents() throws {
        var timer = try #require(Recipe.read("Rest ~40 min~.").firstTimer)
        timer.components = []

        #expect(timer.kind == .qualitative)
    }

    @Test
    func classifiesAComponentWithNoNumericValueAsQualitative() throws {
        var timer = try #require(Recipe.read("Rest ~40 min~.").firstTimer)
        timer.components = [try #require(Recipe.read("Add @{a pinch} salt@.").firstAmount)]

        #expect(timer.kind == .qualitative)
    }
}
