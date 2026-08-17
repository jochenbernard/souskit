import SousCore
import Testing

@Suite("Scaling to a target")
struct TargetScalingTests {
    @Test
    func readsATargetAmountFromItsText() {
        let target = SousParser().parseAmount("18 crepes")

        #expect(target.kind.preciseQuantity?.value == 18.0)
        #expect(target.unit == "crepes")
        #expect(target.text == "18 crepes")
    }

    @Test
    func readsATargetTheWhitespaceAroundItStatesNothingOf() {
        let target = SousParser().parseAmount(" 800 g ")

        #expect(target.kind.preciseQuantity?.value == 800.0)
        #expect(target.unit == "g")
        #expect(target.text == "800 g")
    }

    @Test
    func readsTheFixedMarkerOfATargetAndScalesByItAnyway() throws {
        let parser = SousParser()
        let target = parser.parseAmount("=8 servings")
        #expect(target.isFixed)

        let scaled = try parser.parseRecipe(Fixtures.crepeBatter("servings: 4")).value.scaled(to: target)
        #expect(try scaled.firstQuantityValue() == 400.0)
    }

    @Test
    func derivesTheFactorFromTheYieldOfTheTargetsUnit() throws {
        let source = "---\nyield: 12 crepes\n---\n\nWhisk @{200 g} flour@ into a batter."

        let recipe = try SousParser().scaled(source, to: "18 crepes")
        #expect(try recipe.firstQuantityValue() == 300.0)
        #expect(recipe.metadata.yields.map(\.text) == ["18 crepes"])
    }

    @Test
    func derivesTheFactorFromTheOtherCountableYield() throws {
        let source = "---\nyield: [12 madeleines]\n---\n\nWhisk @{100 g} flour@ into a batter."

        let recipe = try SousParser().scaled(source, to: "18 madeleines")
        #expect(try recipe.firstQuantityValue() == 150.0)
        #expect(recipe.metadata.yields.map(\.text) == ["18 madeleines"])
    }

    @Test
    func scalesARecipeWhoseHeaderCarriesMoreKeysAfterItsServings() throws {
        let scaled = try Recipe.read(Recipes.crepes).scaled(toServings: 8.0)

        #expect(scaled.metadata["servings"] == "8")
        #expect(try scaled.firstQuantityValue() == 400.0)
    }

    @Test
    func countsServingsAsAYieldInPortions() throws {
        let source = "---\nservings: 4\n---\n\nWhisk @{200 g} flour@ into a batter."

        let recipe = try SousParser().scaled(source, to: "8 servings")
        #expect(try recipe.firstQuantityValue() == 400.0)
        #expect(recipe.metadata.servings == 8.0)
    }

    @Test
    func picksTheYieldOfTheTargetsOwnUnitFromSeveral() throws {
        let source = "---\nyield: [6 servings, 3.2 kg]\n---\n\nWhisk @{200 g} flour@ into a batter."

        let recipe = try SousParser().scaled(source, to: "1.6 kg")
        #expect(try recipe.firstQuantityValue() == 100.0)
        #expect(recipe.metadata.yields.map(\.text) == ["3 servings", "1.6 kg"])
    }

    @Test
    func matchesAUnitThroughTheWhitespaceAroundIt() throws {
        let source = "---\nyield: 800  g\n---\n\nWhisk @{200 g} flour@ into a batter."

        #expect(try SousParser().scaled(source, to: "1000 g").firstQuantityValue() == 250.0)
    }

    @Test
    func matchesAUnitThroughTheWhitespaceAroundTheTarget() throws {
        let scaled = try SousParser().scaled(Fixtures.crepeBatter("yield: 12 crepes"), to: "18  crepes")

        #expect(try scaled.firstQuantityValue() == 300.0)
    }

    @Test
    func matchesAnEmptyUnitAgainstAnEmptyUnit() throws {
        let source = "---\nyield: 12\n---\n\nWhisk @{200 g} flour@ into a batter."

        #expect(try SousParser().scaled(source, to: "18").firstQuantityValue() == 300.0)
    }

    @Test(arguments: ["1 kg", "18 Crepes", "18", "500 ml"])
    func refusesATargetNoDeclaredYieldStates(target: String) {
        #expect(throws: ScalingError.noMatchingYield) {
            try SousParser().scaled(Fixtures.crepeBatter("servings: 4\nyield: [800 g, 12 crepes]"), to: target)
        }
    }

    @Test
    func refusesATargetOnlyATagMatches() {
        #expect(throws: ScalingError.noMatchingYield) {
            try SousParser().scaled(Fixtures.crepeBatter("tags: [12 crepes]"), to: "18 crepes")
        }
    }

    @Test
    func refusesARecipeThatDeclaresNothingToDivideBy() {
        #expect(throws: ScalingError.noMatchingYield) {
            try SousParser().scaled("Mix @{200 g} flour@.", to: "400 g")
        }
    }

    @Test(arguments: ["1-2 g", "1-2 kg", "plenty", "a lot of g"])
    func refusesATargetThatStatesNoSingleQuantity(target: String) {
        #expect(throws: ScalingError.noMatchingYield) {
            try SousParser().scaled(Fixtures.crepeBatter("yield: 800 g"), to: target)
        }
    }

    @Test(arguments: [
        (header: "yield: 0 g", target: "500 g"),
        (header: "servings: 0", target: "8 servings")
    ])
    func refusesToDivideByAYieldOfZero(header: String, target: String) {
        #expect(throws: ScalingError.zeroYield) {
            try SousParser().scaled(Fixtures.crepeBatter(header), to: target)
        }
    }

    @Test(arguments: [
        (header: "servings: six\nyield: 4 servings", target: "8 servings", expected: 400.0),
        (header: "yield: [plenty, 12]", target: "18", expected: 300.0),
        (header: "yield: [plenty g, 800 g]", target: "1600 g", expected: 400.0)
    ])
    func looksPastAYieldThatStatesNoQuantity(
        header: String,
        target: String,
        expected: Double
    ) throws {
        #expect(try SousParser().scaled(Fixtures.crepeBatter(header), to: target).firstQuantityValue() == expected)
    }

    @Test
    func looksPastAServingsValueThatStatesNoQuantity() throws {
        let parsed = Recipe.read(Fixtures.crepeBatter("servings: six\nyield: 4 servings"))

        #expect(try parsed.scaled(toServings: 8.0).firstQuantityValue() == 400.0)
    }

    @Test(arguments: ["servings: =4", "yield: =4 servings"])
    func readsNoFixedMarkerInAHeaderValue(header: String) {
        #expect(throws: ScalingError.noMatchingYield) {
            try SousParser().scaled(Fixtures.crepeBatter(header), to: "8 servings")
        }
    }

    @Test
    func readsNoFixedMarkerInAHeaderValueItRestates() throws {
        let header = "servings: =4\nyield: [6 servings, =8 servings]"

        let scaled = try SousParser().scaled(Fixtures.crepeBatter(header), to: "12 servings")
        #expect(scaled.metadata["servings"] == "=4")
        #expect(scaled.metadata.yields.map(\.text) == ["12 servings", "=8 servings"])
    }

    @Test(arguments: [
        "servings: 4\nyield: 4 servings",
        "yield: [4 servings, 4.0 servings]",
        "yield: 4 servings\nyield: 4 servings"
    ])
    func dividesByADimensionStatedTwiceThatAgrees(header: String) throws {
        let scaled = try SousParser().scaled(Fixtures.crepeBatter(header), to: "8 servings")

        #expect(try scaled.firstQuantityValue() == 400.0)
        #expect(scaled.validate().map(\.kind) == [.repeatedYield])
    }

    @Test(arguments: [
        "servings: 4\nyield: 6 servings",
        "yield: [4 servings, 6 servings]",
        "yield: [4 servings, 4-6 servings]",
        "yield: [4-6 servings, 8-10 servings]"
    ])
    func refusesADimensionStatedTwiceThatDisagrees(header: String) {
        #expect(throws: ScalingError.conflictingYields) {
            try SousParser().scaled(Fixtures.crepeBatter(header), to: "8 servings")
        }
    }

    @Test
    func refusesANumberOfServingsWhenThePortionsDisagree() {
        let parsed = Recipe.read(Fixtures.crepeBatter("servings: 4\nyield: 6 servings"))

        #expect(throws: ScalingError.conflictingYields) {
            try parsed.scaled(toServings: 8.0)
        }
    }

    @Test
    func scalesByAFactorThroughADimensionThatDisagrees() throws {
        let parsed = Recipe.read(Fixtures.crepeBatter("servings: 4\nyield: 6 servings"))

        let scaled = try parsed.scaled(by: 2.0)
        #expect(scaled.metadata["servings"] == "8")
        #expect(scaled.metadata.yields.map(\.text) == ["12 servings"])
    }

    @Test(arguments: [
        (
            header: "yield: [10-12 madeleines, 10-12 madeleines]",
            target: "18 madeleines",
            error: ScalingError.noMatchingYield
        ),
        (header: "yield: [0 g, 0 g]", target: "500 g", error: ScalingError.zeroYield),
        (header: "yield: [0 g, 5 g]", target: "500 g", error: ScalingError.conflictingYields)
    ])
    func reportsWhatStoppedTheDivision(
        header: String,
        target: String,
        error: ScalingError
    ) {
        #expect(throws: error) {
            try SousParser().scaled(Fixtures.crepeBatter(header), to: target)
        }
    }

    @Test
    func refusesToDivideByAYieldThatStatesARange() {
        #expect(throws: ScalingError.noMatchingYield) {
            try SousParser().scaled(Fixtures.crepeBatter("yield: 10-12 madeleines"), to: "18 madeleines")
        }
    }

    @Test(arguments: ["---\nservings: 6\n---", "---\nyield: 6 servings\n---"])
    func scalesToANumberOfServings(header: String) throws {
        let source = "\(header)\n\nWhisk @{200 g} flour@ into a batter."

        let recipe = try Recipe.read(source).scaled(toServings: 9.0)
        #expect(try recipe.firstQuantityValue() == 300.0)
    }

    @Test
    func refusesANumberOfServingsWhenNoPortionsAreDeclared() {
        let parsed = Recipe.read(Fixtures.crepeBatter("yield: 800 g"))

        #expect(throws: ScalingError.noMatchingYield) {
            try parsed.scaled(toServings: 8.0)
        }
    }

    @Test
    func refusesANumberOfServingsWhenThePortionsStateARange() {
        let parsed = Recipe.read(Fixtures.crepeBatter("servings: 4-6"))

        #expect(throws: ScalingError.noMatchingYield) {
            try parsed.scaled(toServings: 8.0)
        }
    }

    @Test
    func refusesATargetDerivingAFactorItCouldNotWriteBack() {
        let parser = SousParser()
        let parsed = parser.parseRecipe(Fixtures.crepeBatter("yield: 800 g")).value
        let target = parser.parseAmount(String.quantity(digits: 400) + " g")

        #expect(throws: ScalingError.unusableFactor) {
            try parsed.scaled(to: target)
        }
    }

    @Test
    func refusesZeroDeclaredServings() {
        let parsed = Recipe.read(Fixtures.crepeBatter("servings: 0"))

        #expect(throws: ScalingError.zeroYield) {
            try parsed.scaled(toServings: 8.0)
        }
    }

    @Test(arguments: [-2.0, -0.0, Double.infinity, -Double.infinity, Double.nan])
    func refusesAServingsTargetItCouldNotWriteBack(servings: Double) {
        let parsed = Recipe.read(Fixtures.crepeBatter("servings: 4"))

        #expect(throws: ScalingError.unusableFactor) {
            try parsed.scaled(toServings: servings)
        }
    }

    @Test
    func scalingToWhatIsAlreadyDeclaredChangesNothing() throws {
        let source = "---\nservings: 4\n---\n\nMix @{200g} flour@ and @{=1 tsp} salt@."
        let parsed = Recipe.read(source)

        #expect(try parsed.scaled(toServings: 4.0) == parsed)
    }

    @Test
    func aTargetOfZeroScalesToNothing() throws {
        let scaled = try Recipe.read(Fixtures.crepeBatter("servings: 4")).scaled(toServings: 0.0)

        #expect(try scaled.firstQuantityValue() == 0.0)
        #expect(scaled.metadata.servings == 0.0)
    }
}
