import SousCore
import Testing

@Suite("Reference destinations")
struct ReferenceDestinationTests {
    /// The destination of every reference in a source, in document order.
    private func destinations(in source: String) -> [Reference.Destination] {
        let recipe = Recipe.read(source)

        return recipe.references.map(recipe.destination(of:))
    }

    @Test
    func sendsABareNameMatchingAGroupToTheGroup() throws {
        let recipe = Recipe.read("## Pastry\nRub in the butter.\n\n## Assemble\nLine a tin with the >pastry>.")
        let pastry = try #require(recipe.groups.first)
        let reference = try #require(recipe.firstReference)

        #expect(recipe.destination(of: reference) == .group(pastry))
    }

    @Test(arguments: ["PASTRY", "P\u{E2}stry", "pastry"])
    func matchesTheGroupOfABareNameNormalized(name: String) throws {
        let recipe = Recipe.read("## Pastry\nRub in the butter.\n\n## Assemble\nLine a tin with the >\(name)>.")
        let pastry = try #require(recipe.groups.first)

        #expect(recipe.references.map(recipe.destination(of:)) == [.group(pastry)])
    }

    @Test
    func sendsABareNameMatchingTheFirstOfTwoGroupsToThatGroup() throws {
        let recipe = Recipe.read("## Pastry\nRub.\n\n## pastry\nRoll.\n\n## Assemble\nLine it with the >pastry>.")
        let first = try #require(recipe.groups.first)

        #expect(recipe.references.map(recipe.destination(of:)) == [.group(first)])
    }

    @Test(arguments: ["bechamel", "tomato sauce", "Bechamel", ".", ".."])
    func sendsABareNameMatchingNoGroupToTheFileOfThatName(name: String) {
        #expect(destinations(in: "## Assemble\nLayer the >\(name)> in a dish.") == [.file(name)])
    }

    @Test(arguments: ["sauces/bolognese", "../shared/stock", "sauces/./bolognese", "sauces//bolognese", "/stock"])
    func sendsANameHoldingASlashToAFile(path: String) {
        #expect(destinations(in: "Layer the >\(path)> in a dish.") == [.file(path)])
    }

    @Test
    func sendsANameHoldingASlashToAFileEvenWhenAGroupCarriesIt() {
        let source = "## sauces/rouille\nBlend it.\n\n## Assemble\nLayer the >sauces/rouille>."

        #expect(destinations(in: source) == [.file("sauces/rouille")])
    }

    @Test
    func sendsALeadingDotSlashToTheFileOverAGroupOfTheSameName() {
        let source = "## Bolognese\nBrown it.\n\n## Assemble\nLayer the >./bolognese>."

        #expect(destinations(in: source) == [.file("bolognese")])
    }

    @Test(arguments: [
        ("./bolognese", "bolognese"),
        ("././bolognese", "bolognese"),
        ("./sauces/bolognese", "sauces/bolognese"),
        ("./../stock", "../stock"),
        ("./", "")
    ])
    func dropsEveryLeadingDotSlash(written: String, path: String) {
        #expect(destinations(in: "Layer the >\(written)>.") == [.file(path)])
    }

    @Test
    func sendsAReferenceWithAnAmountByItsNameAlone() {
        #expect(destinations(in: "Layer >{300 g} sauces/bolognese> on top.") == [.file("sauces/bolognese")])
    }
}
