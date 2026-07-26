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
        #expect(diagnostic.severity == .error)
        #expect(diagnostic.range == nil)
        #expect(diagnostic.message == "Recipe has more than one group named 'Bechamel'.")
    }

    @Test(arguments: [
        "## Sauce\nBrown it.\n\n## sauce\nBrown it again.",
        "## Sauce\nBrown it.\n\n## the sauce\nBrown it again.",
        "## B\u{E9}chamel\nWhisk it.\n\n## Bechamel\nWhisk it again.",
        "## Sauce\nBrown it.\n\n##  Sauce \nBrown it again."
    ])
    func reportsANameTwoHeadingsShareUnderNormalization(source: String) {
        #expect(validate(source).map(\.kind) == [.repeatedGroupName])
    }

    @Test(arguments: [
        "## Sauce\nBrown it.\n\n## Topping\nGrate it.",
        "## Sauce\nBrown it.\n\n## Sauces\nBrown them.",
        "## The\nBrown it.\n\n## A\nBrown it again.",
        "Warm the oven.\n\n## Sauce\nBrown it."
    ])
    func acceptsGroupsWhoseNamesDiffer(source: String) {
        #expect(validate(source).isEmpty)
    }

    @Test
    func reportsOneDiagnosticPerRepeatedName() {
        #expect(validate("## Sauce\nOne.\n\n## sauce\nTwo.\n\n## SAUCE\nThree.").map(\.kind)
            == [.repeatedGroupName])
        #expect(validate("## Sauce\nOne.\n\n## sauce\nTwo.\n\n## Top\nThree.\n\n## top\nFour.").map(\.kind)
            == [.repeatedGroupName, .repeatedGroupName])
    }

    @Test
    func reportsAReferenceThatMatchesNoGroup() throws {
        let diagnostics = validate("## Assemble\nLayer the >bechamel> in a dish.")

        #expect(diagnostics.count == 1)
        let diagnostic = try #require(diagnostics.first)
        #expect(diagnostic.kind == .unresolvedReference)
        #expect(diagnostic.severity == .error)
        #expect(diagnostic.range == nil)
        #expect(diagnostic.message == "Reference to 'bechamel' matches no group.")
    }

    @Test(arguments: [
        "## Sauce\nBrown it.\n\n## Assemble\nLayer the >sauce> in a dish.",
        "## B\u{E9}chamel\nWhisk it.\n\n## Assemble\nLayer the >bechamel> in a dish.",
        "## Sauce\nBrown it.\n\n## Assemble\nLayer the >the sauce> in a dish.",
        "Layer the >sauce> in a dish.\n\n## Sauce\nBrown it.",
        "## sauces/red\nBrown it.\n\n## Assemble\nLayer the >sauces/red> in a dish."
    ])
    func acceptsAReferenceThatMatchesAGroup(source: String) {
        #expect(validate(source).isEmpty)
    }

    @Test
    func reportsEachUnresolvedTargetOnce() {
        let source = """
        ## Assemble
        Layer the >bechamel> in a dish, then the >ragu>, then the rest of the >the bechamel>.
        """

        #expect(validate(source).map(\.message) == [
            "Reference to 'bechamel' matches no group.",
            "Reference to 'ragu' matches no group."
        ])
    }

    @Test
    func reportsAReferenceHoldingAPathSeparator() {
        #expect(validate("## Assemble\nLayer the >sauces/red> in a dish.").map(\.kind)
            == [.unresolvedReference])
    }

    @Test
    func reportsAGroupThatConsumesItsOwnIntermediate() throws {
        let diagnostics = validate("## Sauce\nStir the >sauce> again.")

        #expect(diagnostics.count == 1)
        let diagnostic = try #require(diagnostics.first)
        #expect(diagnostic.kind == .referenceCycle)
        #expect(diagnostic.severity == .error)
        #expect(diagnostic.range == nil)
        #expect(diagnostic.message == "Group 'Sauce' consumes an intermediate that depends on it.")
    }

    @Test
    func reportsGroupsThatConsumeEachOther() {
        let source = """
        ## Sauce
        Stir in the >topping>.

        ## Topping
        Stir in the >sauce>.
        """

        #expect(validate(source).map(\.message) == [
            "Group 'Sauce' consumes an intermediate that depends on it."
        ])
    }

    @Test
    func reportsALoopThatRunsThroughAThirdGroup() {
        let source = """
        ## Sauce
        Stir in the >topping>.

        ## Topping
        Stir in the >base>.

        ## Base
        Stir in the >sauce>.
        """

        #expect(validate(source).map(\.kind) == [.referenceCycle])
    }

    @Test
    func reportsOneDiagnosticPerLoop() {
        let source = """
        ## Sauce
        Stir in the >topping>.

        ## Topping
        Stir in the >sauce>.

        ## Base
        Stir in the >crust>.

        ## Crust
        Stir in the >base>.
        """

        #expect(validate(source).map(\.message) == [
            "Group 'Sauce' consumes an intermediate that depends on it.",
            "Group 'Base' consumes an intermediate that depends on it."
        ])
    }

    @Test(arguments: [
        """
        ## Sauce
        Brown it.

        ## Topping
        Stir in the >sauce>.

        ## Assemble
        Layer the >sauce> and the >topping>.
        """,
        """
        ## Assemble
        Layer the >sauce> and the >topping>.

        ## Sauce
        Brown it.

        ## Topping
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

        ## Sauce
        Stir in the >sauce> and the >bechamel>.

        ## sauce
        Brown it.
        """

        #expect(validate(source).map(\.kind) == [
            .repeatedYield, .repeatedGroupName, .unresolvedReference, .referenceCycle
        ])
    }

    @Test
    func reportsTwoLoopsSharingAGroupOnce() {
        let source = """
        ## Sauce
        Stir in the >topping> and the >base>.

        ## Topping
        Stir in the >sauce>.

        ## Base
        Stir in the >sauce>.
        """

        #expect(validate(source).map(\.message) == [
            "Group 'Sauce' consumes an intermediate that depends on it."
        ])
    }

    @Test
    func reportsTheSameSetsAsAnIndependentWalkOfTheEdges() {
        var failures: [String] = []

        for encoded in 0..<512 {
            let edges = (0..<3).map({ group in
                (0..<3).filter({ target in encoded >> (group * 3 + target) & 1 == 1 })
            })
            let groups = (0..<3).map({ group in
                "## g\(group)\n" + edges[group].map({ "Stir the >g\($0)>." }).joined(separator: " ")
            })
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
        title: Pasta Bake
        servings: 4
        ---

        ## Sauce
        Brown @{500 g} minced beef@ in a #pan#.

        ## Assemble
        Layer the >sauce> in a #baking dish#.
        """

        #expect(validate(source).isEmpty)
    }
}
