import SousCore
import Testing

@Suite("Cookware")
struct CookwareTests {
    @Test
    func parsesASingleWordName() throws {
        let cookware = try #require(Recipe.read("Warm a #pan#.").firstCookware)
        #expect(cookware.name == "pan")
    }

    @Test
    func parsesAMultiWordName() throws {
        let cookware = try #require(Recipe.read("Bring a #large pot# of water to a boil.").firstCookware)
        #expect(cookware.name == "large pot")
    }

    @Test(arguments: ["#large pot #", "#large pot\t#"])
    func trimsTheWhitespaceAroundAName(span: String) throws {
        #expect(try #require(Recipe.read("Bring a \(span) to a boil.").firstCookware).name == "large pot")
    }

    @Test
    func extractsIngredientsAndCookwareFromTheSameStep() throws {
        let step = try #require(Recipe.read("Melt @{30 g} butter@ in a #pan#.").firstStep)
        #expect(step.ingredients.map(\.name) == ["butter"])
        #expect(step.cookware.map(\.name) == ["pan"])
    }
}
