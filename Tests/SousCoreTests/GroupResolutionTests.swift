import SousCore
import Testing

@Suite("Group resolution")
struct GroupResolutionTests {
    /// A recipe of three groups where the last consumes the other two.
    private var pastaBake: Recipe {
        Recipe.read("""
        ## Sauce
        Brown the beef.

        ## Topping
        Grate the cheese.

        ## Assemble
        Layer the >sauce> in a dish and dot the >topping> over it.
        """)
    }

    @Test
    func findsTheGroupANameRefersTo() {
        #expect(pastaBake.group(named: "Sauce")?.steps.map(\.text) == ["Brown the beef."])
    }

    @Test(arguments: ["sauce", "SAUCE", "  sauce  ", "the sauce", "of the sauce", "Sauce"])
    func matchesANameNormalized(name: String) {
        #expect(pastaBake.group(named: name)?.name == "Sauce")
    }

    @Test
    func matchesANameHoldingAPathSeparator() throws {
        let value = Recipe.read("## sauces/red\nBrown it.\n\n## Assemble\nLayer the >sauces/red>.")
        let assemble = try #require(value.groups.last)

        #expect(value.group(named: "sauces/red")?.name == "sauces/red")
        #expect(value.dependencies(of: assemble).map(\.name) == ["sauces/red"])
    }

    @Test
    func matchesANameWrittenWithoutTheAccentTheHeadingCarries() {
        #expect(Recipe.read("## B\u{E9}chamel\nWhisk it.").group(named: "bechamel")?.name == "B\u{E9}chamel")
    }

    @Test(arguments: ["Filling", "sauces/red", "sauce topping"])
    func findsNoGroupForANameNoHeadingStates(name: String) {
        #expect(pastaBake.group(named: name) == nil)
    }

    @Test
    func refersToTheDefaultGroupByNothing() {
        let value = Recipe.read("Warm the oven.\n\n## Sauce\nBrown the beef.")

        #expect(value.group(named: "") == nil)
        #expect(value.group(named: "   ") == nil)
        #expect(value.group(named: "Sauce")?.name == "Sauce")
    }

    @Test
    func returnsTheFirstOfTwoGroupsThatShareAName() {
        let value = Recipe.read("## Sauce\nBrown the beef.\n\n## sauce\nGrate the cheese.")

        #expect(value.group(named: "sauce")?.steps.map(\.text) == ["Brown the beef."])
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
        let value = pastaBake
        let assemble = try #require(value.groups.last)

        #expect(value.dependencies(of: assemble).map(\.name) == ["Sauce", "Topping"])
    }

    @Test
    func listsNoDependencyForAGroupThatConsumesNothing() throws {
        let value = pastaBake
        let sauce = try #require(value.groups.first)

        #expect(value.dependencies(of: sauce).isEmpty)
    }

    @Test
    func listsEachGroupOnceHoweverOftenItIsConsumed() throws {
        let value = Recipe.read("""
        ## Sauce
        Brown the beef.

        ## Assemble
        Spread the >sauce>, then the pasta, then the rest of the >the sauce>.
        """)
        let assemble = try #require(value.groups.last)

        #expect(value.dependencies(of: assemble).map(\.name) == ["Sauce"])
    }

    @Test
    func listsDependenciesInTheOrderTheirReferencesAppear() throws {
        let value = Recipe.read("""
        ## Sauce
        Brown the beef.

        ## Topping
        Grate the cheese.

        ## Assemble
        Dot the >topping> over the >sauce>.
        """)
        let assemble = try #require(value.groups.last)

        #expect(value.dependencies(of: assemble).map(\.name) == ["Topping", "Sauce"])
    }

    @Test
    func dependsOnAGroupWrittenAfterIt() throws {
        let value = Recipe.read("""
        ## Assemble
        Layer the >sauce> in a dish.

        ## Sauce
        Brown the beef.
        """)
        let assemble = try #require(value.groups.first)

        #expect(value.dependencies(of: assemble).map(\.name) == ["Sauce"])
    }

    @Test
    func leavesOutATargetThatNamesNoGroup() throws {
        let value = Recipe.read("""
        ## Sauce
        Brown the beef.

        ## Assemble
        Layer the >sauce> and the >bechamel> in a dish.
        """)
        let assemble = try #require(value.groups.last)

        #expect(value.dependencies(of: assemble).map(\.name) == ["Sauce"])
    }

    @Test
    func listsAGroupThatConsumesItsOwnIntermediate() throws {
        let value = Recipe.read("## Sauce\nStir the >sauce> again.")
        let sauce = try #require(value.groups.first)

        #expect(value.dependencies(of: sauce).map(\.name) == ["Sauce"])
    }

    @Test
    func letsTheDefaultGroupDependOnANamedGroup() throws {
        let value = Recipe.read("Layer the >sauce> in a dish.\n\n## Sauce\nBrown the beef.")
        let group = try #require(value.groups.first)

        #expect(group.name == nil)
        #expect(value.dependencies(of: group).map(\.name) == ["Sauce"])
    }
}
