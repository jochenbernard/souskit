import SousCore
import Testing

@Suite("Group validation")
struct GroupValidationTests {
    /// The diagnostics validating a whole source produces.
    private func validate(_ source: String) -> [Diagnostic] {
        Recipe.read(source).validate()
    }

    @Test
    func reportsTwoHeadingsThatNormalizeToOneName() throws {
        let diagnostics = validate("## Bechamel\nWhisk it.\n\n## bechamel\nWhisk it again.")

        #expect(diagnostics.count == 1)
        let diagnostic = try #require(diagnostics.first)
        #expect(diagnostic.kind == .repeatedGroupName)
        #expect(diagnostic.severity == .warning)
        #expect(diagnostic.range == nil)
        #expect(diagnostic.message == "Recipe has more than one group named 'Bechamel'.")
    }

    @Test(arguments: [
        "## Filling\nBrown it.\n\n## filling\nBrown it again.",
        "## B\u{E9}chamel\nWhisk it.\n\n## Bechamel\nWhisk it again.",
        "## Filling\nBrown it.\n\n##  Filling \nBrown it again."
    ])
    func reportsANameTwoHeadingsShareUnderNormalization(source: String) {
        #expect(validate(source).map(\.kind) == [.repeatedGroupName])
    }

    @Test(arguments: [
        "## Filling\nBrown it.\n\n## Garnish\nGrate it.",
        "## Filling\nBrown it.\n\n## Fillings\nBrown them.",
        "## The\nBrown it.\n\n## A\nBrown it again.",
        "Warm the oven.\n\n## Filling\nBrown it."
    ])
    func acceptsGroupsWhoseNamesDiffer(source: String) {
        #expect(validate(source).isEmpty)
    }

    @Test
    func reportsOneDiagnosticPerRepeatedName() {
        #expect(validate("## Filling\nOne.\n\n## filling\nTwo.\n\n## FILLING\nThree.").map(\.kind)
            == [.repeatedGroupName])
        #expect(validate("## Filling\nOne.\n\n## filling\nTwo.\n\n## Roux\nThree.\n\n## roux\nFour.").map(\.kind)
            == [.repeatedGroupName, .repeatedGroupName])
    }

    @Test
    func reportsAReferenceThatMatchesNoGroup() throws {
        let diagnostics = validate("## Assemble\nLayer the >bechamel> in a dish.")

        #expect(diagnostics.count == 1)
        let diagnostic = try #require(diagnostics.first)
        #expect(diagnostic.kind == .unresolvedReference)
        #expect(diagnostic.severity == .warning)
        #expect(diagnostic.range == nil)
        #expect(diagnostic.message == "Reference to 'bechamel' matches no group.")
    }

    @Test(arguments: [
        "## Filling\nBrown it.\n\n## Assemble\nLayer the >filling> in a dish.",
        "## B\u{E9}chamel\nWhisk it.\n\n## Assemble\nLayer the >bechamel> in a dish.",
        "Layer the >filling> in a dish.\n\n## Filling\nBrown it.",
        "## sauces/rouille\nBrown it.\n\n## Assemble\nLayer the >sauces/rouille> in a dish."
    ])
    func acceptsAReferenceThatMatchesAGroup(source: String) {
        #expect(validate(source).isEmpty)
    }

    @Test
    func reportsEachUnresolvedTargetOnce() {
        let source = """
        ## Assemble
        Layer the >bechamel> in a dish, then the >ragout>, then the rest of the >bechamel>.
        """

        #expect(validate(source).map(\.message) == [
            "Reference to 'bechamel' matches no group.",
            "Reference to 'ragout' matches no group."
        ])
    }

    @Test
    func reportsAReferenceHoldingAPathSeparator() {
        #expect(validate("## Assemble\nLayer the >sauces/rouille> in a dish.").map(\.kind)
            == [.unresolvedReference])
    }

    @Test
    func reportsAGroupThatConsumesItsOwnIntermediate() throws {
        let diagnostics = validate("## Filling\nStir the >filling> again.")

        #expect(diagnostics.count == 1)
        let diagnostic = try #require(diagnostics.first)
        #expect(diagnostic.kind == .referenceCycle)
        #expect(diagnostic.severity == .warning)
        #expect(diagnostic.range == nil)
        #expect(diagnostic.message == "Group 'Filling' consumes an intermediate that depends on it.")
    }

    @Test
    func reportsGroupsThatConsumeEachOther() {
        let source = """
        ## Filling
        Stir in the >garnish>.

        ## Garnish
        Stir in the >filling>.
        """

        #expect(validate(source).map(\.message) == [
            "Group 'Filling' consumes an intermediate that depends on it."
        ])
    }

    @Test
    func reportsALoopThatRunsThroughAThirdGroup() {
        let source = """
        ## Filling
        Stir in the >garnish>.

        ## Garnish
        Stir in the >custard>.

        ## Custard
        Stir in the >filling>.
        """

        #expect(validate(source).map(\.kind) == [.referenceCycle])
    }

    @Test
    func reportsOneDiagnosticPerLoop() {
        let source = """
        ## Filling
        Stir in the >garnish>.

        ## Garnish
        Stir in the >filling>.

        ## Custard
        Stir in the >pastry>.

        ## Pastry
        Stir in the >custard>.
        """

        #expect(validate(source).map(\.message) == [
            "Group 'Filling' consumes an intermediate that depends on it.",
            "Group 'Custard' consumes an intermediate that depends on it."
        ])
    }

    @Test(arguments: [
        """
        ## Filling
        Brown it.

        ## Garnish
        Stir in the >filling>.

        ## Assemble
        Layer the >filling> and the >garnish>.
        """,
        """
        ## Assemble
        Layer the >filling> and the >garnish>.

        ## Filling
        Brown it.

        ## Garnish
        Grate it.
        """
    ])
    func acceptsAGroupGraphWithNoLoop(source: String) {
        #expect(validate(source).isEmpty)
    }

    @Test
    func reportsEveryProblemOfTheFile() {
        let source = """
        ---
        servings: 4
        yield: 6 servings
        ---

        ## Filling
        Stir in the >filling> and the >bechamel>.

        ## filling
        Brown it.
        """

        #expect(validate(source).map(\.kind) == [
            .repeatedYield, .repeatedGroupName, .unresolvedReference, .referenceCycle
        ])
    }

    @Test
    func reportsTwoLoopsSharingAGroupOnce() {
        let source = """
        ## Filling
        Stir in the >garnish> and the >custard>.

        ## Garnish
        Stir in the >filling>.

        ## Custard
        Stir in the >filling>.
        """

        #expect(validate(source).map(\.message) == [
            "Group 'Filling' consumes an intermediate that depends on it."
        ])
    }

    @Test
    func reportsTheSameSetsAsAnIndependentWalkOfTheEdges() {
        var failures: [String] = []

        for encoded in 0..<512 {
            let edges = (0..<3).map { group in
                (0..<3).filter({ target in encoded >> (group * 3 + target) & 1 == 1 })
            }
            let groups = (0..<3).map { group in
                "## g\(group)\n" + edges[group].map({ "Stir the >g\($0)>." }).joined(separator: " ")
            }
            let source = groups.joined(separator: "\n\n")

            let reported = validate(source).filter({ $0.kind == .referenceCycle }).map(\.message)
            let expected = Self.loops(in: edges)
                .map({ "Group 'g\($0)' consumes an intermediate that depends on it." })

            if reported != expected {
                failures.append("\(edges) reported \(reported) rather than \(expected)")
            }
        }

        TestSupport.expectNoFailures(failures)
    }

    /// The groups a cycle should be reported at, worked out independently of the implementation
    /// so the expectation is not derived from the code it checks.
    private static func loops(in edges: [[Int]]) -> [Int] {
        let reaches = edges.indices.map({ reached(from: $0, edges: edges) })
        var loops: [Int] = []
        var reported: Set<Int> = []

        for group in edges.indices where reaches[group].contains(group) && !reported.contains(group) {
            reported.formUnion(reaches[group].filter({ reaches[$0].contains(group) }))
            loops.append(group)
        }

        return loops
    }

    /// Every group reachable from a start, directly or through others.
    private static func reached(from start: Int, edges: [[Int]]) -> Set<Int> {
        var seen: Set<Int> = []
        var pending = edges[start]

        while let next = pending.popLast() {
            guard seen.insert(next).inserted else { continue }

            pending += edges[next]
        }

        return seen
    }

    @Test
    func validatesARecipeWithNoGroupProblemWithoutDiagnostics() {
        let source = """
        ---
        title: Quiche Lorraine
        servings: 4
        ---

        ## Filling
        Fry @{500 g} lardons@ in a #frying pan#.

        ## Assemble
        Layer the >filling> in a #tart tin#.
        """

        #expect(validate(source).isEmpty)
    }
}
