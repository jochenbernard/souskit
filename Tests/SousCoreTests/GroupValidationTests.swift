import SousCore
import Testing

// Version 0.4 brings the three conditional requirements groups and references carry: a name two
// headings share leaves a reference to it reaching only the first of them, a reference matching
// no group consumes nothing, and groups consuming each other in a loop can none of them be made
// first.
//
// Each leaves the file well-formed but not valid, so each is an error rather than a warning.
// Validation reads a recipe, which holds no source map, so no diagnostic carries a range, and
// each problem is reported once, where it is first stated.

@Suite("Group validation")
struct GroupValidationTests {
    private func validate(_ source: String) -> [Diagnostic] {
        Recipe.read(source).validate()
    }

    // Repeated group names

    @Test
    func reportsTwoHeadingsThatNormalizeToOneName() throws {
        let diagnostics = validate("## Bechamel\nWhisk it.\n\n## bechamel\nWhisk it again.")

        #expect(diagnostics.count == 1)
        let diagnostic = try #require(diagnostics.first)
        #expect(diagnostic.kind == .repeatedGroupName)
        #expect(diagnostic.severity == .error)
        #expect(diagnostic.range == nil)
        #expect(diagnostic.message == "Recipe states more than one group named 'Bechamel'.")
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
        // The default group has no name, so it collides with nothing.
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

    // Unresolved references

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
        // The default group may consume a named one.
        "Layer the >sauce> in a dish.\n\n## Sauce\nBrown it.",
        // A path separator is ordinary text in a name, so a target holding one matches the
        // group holding one. From v0.5 such a target names a file instead.
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

    // A reference is unresolved whatever its content, because only a group of the same file
    // can match it in this version.

    @Test
    func reportsAReferenceHoldingAPathSeparator() {
        #expect(validate("## Assemble\nLayer the >sauces/red> in a dish.").map(\.kind)
            == [.unresolvedReference])
    }

    // Cycles

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

    // A group consumed by two others, or consumed twice along different routes, is not a loop:
    // nothing consumes its own intermediate, however indirectly.

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

    // Every rule reports together, in the order the rules are stated.

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

    // Groups that reach each other are one problem however many loops run through them, so two
    // loops sharing a group are one report.

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

    // Which groups a set runs through is easy to state and easy to get subtly wrong, so every
    // graph three groups can form is checked against a walk of the edges written separately
    // from the one validation does.

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

        let report = failures.isEmpty ? "" : "\(failures.count) failures, the first being that \(failures[0])"
        #expect(report.isEmpty)
    }

    /// The first group of each mutually-consuming set the edges form, in document order, which
    /// is the group each diagnostic is reported under.
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

    /// Which groups a group reaches, found by walking the edges one at a time.
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
