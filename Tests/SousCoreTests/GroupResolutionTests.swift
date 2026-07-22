import SousCore
import Testing

// A reference names a group of the same file, matched normalized, and consuming that group's
// intermediate is what makes the consumer depend on it. The dependency follows from the
// consumption rather than from the position, so a group may be written before or after the
// groups it depends on.

@Suite("Group resolution")
struct GroupResolutionTests {
    private func recipe(_ source: String) -> Recipe {
        SousParser().parseRecipe(source).value
    }

    private var pastaBake: Recipe {
        recipe("""
        ## Sauce
        Brown the beef.

        ## Topping
        Grate the cheese.

        ## Assemble
        Layer the >sauce> in a dish and dot the >topping> over it.
        """)
    }

    // Resolving a name

    @Test
    func findsTheGroupANameRefersTo() {
        #expect(pastaBake.group(named: "Sauce")?.steps.map(\.text) == ["Brown the beef."])
    }

    @Test(arguments: ["sauce", "SAUCE", "  sauce  ", "the sauce", "of the sauce", "Sauce"])
    func matchesANameNormalized(name: String) {
        #expect(pastaBake.group(named: name)?.name == "Sauce")
    }

    @Test
    func matchesANameWrittenWithoutTheAccentTheHeadingCarries() {
        #expect(recipe("## B\u{E9}chamel\nWhisk it.").group(named: "bechamel")?.name == "B\u{E9}chamel")
    }

    @Test(arguments: ["Filling", "sauces/red", "sauce topping"])
    func findsNoGroupForANameNoHeadingStates(name: String) {
        #expect(pastaBake.group(named: name) == nil)
    }

    @Test
    func refersToTheDefaultGroupByNothing() {
        // The default group has no name, so no name reaches it, an empty one included.
        let value = recipe("Warm the oven.\n\n## Sauce\nBrown the beef.")

        #expect(value.group(named: "") == nil)
        #expect(value.group(named: "   ") == nil)
        #expect(value.group(named: "Sauce")?.name == "Sauce")
    }

    @Test
    func returnsTheFirstOfTwoGroupsThatShareAName() {
        // The file is not valid, but a reference to that name still resolves to one group.
        let value = recipe("## Sauce\nBrown the beef.\n\n## sauce\nGrate the cheese.")

        #expect(value.group(named: "sauce")?.steps.map(\.text) == ["Brown the beef."])
    }

    // Dependencies

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
        let value = recipe("""
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
        let value = recipe("""
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
        let value = recipe("""
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
        let value = recipe("""
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
        let value = recipe("## Sauce\nStir the >sauce> again.")
        let sauce = try #require(value.groups.first)

        #expect(value.dependencies(of: sauce).map(\.name) == ["Sauce"])
    }

    @Test
    func letsTheDefaultGroupDependOnANamedGroup() throws {
        let value = recipe("Layer the >sauce> in a dish.\n\n## Sauce\nBrown the beef.")
        let group = try #require(value.groups.first)

        #expect(group.name == nil)
        #expect(value.dependencies(of: group).map(\.name) == ["Sauce"])
    }
}
