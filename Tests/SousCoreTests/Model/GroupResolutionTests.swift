import SousCore
import Testing

@Suite("Group resolution")
struct GroupResolutionTests {
    /// A recipe of three groups where the last consumes the other two.
    private var quicheLorraine: Recipe {
        Recipe.read("""
        ## Pastry
        Rub in the butter.

        ## Filling
        Whisk the eggs.

        ## Assemble
        Line a tin with the >pastry> and pour in the >filling>.
        """)
    }

    @Test
    func findsTheGroupANameRefersTo() {
        #expect(quicheLorraine.group(named: "Pastry")?.steps.map(\.text) == ["Rub in the butter."])
    }

    @Test(arguments: ["pastry", "PASTRY", "  pastry  ", "Pastry"])
    func matchesANameNormalized(name: String) {
        #expect(quicheLorraine.group(named: name)?.name == "Pastry")
    }

    @Test
    func matchesANameHoldingAPathSeparator() throws {
        let value = Recipe.read("## sauces/rouille\nBlend it.\n\n## Assemble\nLayer the >sauces/rouille>.")
        let assemble = try #require(value.groups.last)

        #expect(value.group(named: "sauces/rouille")?.name == "sauces/rouille")
        #expect(value.dependencies(of: assemble).map(\.name) == ["sauces/rouille"])
    }

    @Test
    func matchesANameWrittenWithoutTheAccentTheHeadingCarries() {
        #expect(Recipe.read("## B\u{E9}chamel\nWhisk it.").group(named: "bechamel")?.name == "B\u{E9}chamel")
    }

    @Test(arguments: ["Bechamel", "sauces/rouille", "pastry filling"])
    func findsNoGroupForANameNoHeadingStates(name: String) {
        #expect(quicheLorraine.group(named: name) == nil)
    }

    @Test
    func refersToTheDefaultGroupByNothing() {
        let value = Recipe.read("Warm the oven.\n\n## Pastry\nRub in the butter.")

        #expect(value.group(named: "") == nil)
        #expect(value.group(named: "   ") == nil)
        #expect(value.group(named: "Pastry")?.name == "Pastry")
    }

    @Test
    func returnsTheFirstOfTwoGroupsThatShareAName() {
        let value = Recipe.read("## Pastry\nRub in the butter.\n\n## pastry\nWhisk the eggs.")

        #expect(value.group(named: "pastry")?.steps.map(\.text) == ["Rub in the butter."])
    }

    @Test
    func findsAGroupExactlyWhenTheTwoNamesNormalizeTheSame() {
        let parts = ["of", "the", "a", " ", "x", "\u{E9}", "E\u{301}", "-"]
        let names = parts.flatMap({ first in parts.map({ first + $0 }) }) + parts
        let failures = names.flatMap { heading in
            names.compactMap { target -> String? in
                let value = Recipe.read("## \(heading)\nMix it.")
                guard value.groups.first?.name != nil else { return nil }

                let found = value.group(named: target) != nil
                let normalizesTheSame = Normalization.normalized(heading) == Normalization.normalized(target)
                guard found != normalizesTheSame else { return nil }

                return "\(heading.debugDescription) and \(target.debugDescription) disagree"
            }
        }

        TestSupport.expectNoFailures(failures)
    }

    @Test
    func listsTheGroupsAGroupDependsOn() throws {
        let value = quicheLorraine
        let assemble = try #require(value.groups.last)

        #expect(value.dependencies(of: assemble).map(\.name) == ["Pastry", "Filling"])
    }

    @Test
    func listsNoDependencyForAGroupThatConsumesNothing() throws {
        let value = quicheLorraine
        let pastry = try #require(value.groups.first)

        #expect(value.dependencies(of: pastry).isEmpty)
    }

    @Test
    func listsEachGroupOnceHoweverOftenItIsConsumed() throws {
        let value = Recipe.read("""
        ## Pastry
        Rub in the butter.

        ## Assemble
        Spread the >pastry>, then the lardons, then the rest of the >pastry>.
        """)
        let assemble = try #require(value.groups.last)

        #expect(value.dependencies(of: assemble).map(\.name) == ["Pastry"])
    }

    @Test
    func listsDependenciesInTheOrderTheirReferencesAppear() throws {
        let value = Recipe.read("""
        ## Pastry
        Rub in the butter.

        ## Filling
        Whisk the eggs.

        ## Assemble
        Pour the >filling> onto the >pastry>.
        """)
        let assemble = try #require(value.groups.last)

        #expect(value.dependencies(of: assemble).map(\.name) == ["Filling", "Pastry"])
    }

    @Test
    func dependsOnAGroupWrittenAfterIt() throws {
        let value = Recipe.read("""
        ## Assemble
        Line a tin with the >pastry>.

        ## Pastry
        Rub in the butter.
        """)
        let assemble = try #require(value.groups.first)

        #expect(value.dependencies(of: assemble).map(\.name) == ["Pastry"])
    }

    @Test
    func leavesOutATargetThatNamesNoGroup() throws {
        let value = Recipe.read("""
        ## Pastry
        Rub in the butter.

        ## Assemble
        Line a tin with the >pastry> and the >bechamel>.
        """)
        let assemble = try #require(value.groups.last)

        #expect(value.dependencies(of: assemble).map(\.name) == ["Pastry"])
    }

    @Test
    func listsAGroupThatConsumesItsOwnIntermediate() throws {
        let value = Recipe.read("## Pastry\nStir the >pastry> again.")
        let pastry = try #require(value.groups.first)

        #expect(value.dependencies(of: pastry).map(\.name) == ["Pastry"])
    }

    @Test
    func letsTheDefaultGroupDependOnANamedGroup() throws {
        let value = Recipe.read("Line a tin with the >pastry>.\n\n## Pastry\nRub in the butter.")
        let group = try #require(value.groups.first)

        #expect(group.name == nil)
        #expect(value.dependencies(of: group).map(\.name) == ["Pastry"])
    }
}
