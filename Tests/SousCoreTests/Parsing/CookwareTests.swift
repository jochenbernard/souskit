import SousCore
import Testing

@Suite("Cookware")
struct CookwareTests {
    @Test
    func parsesASingleWordName() throws {
        let cookware = try #require(Recipe.read("Warm a #casserole#.").firstCookware)
        #expect(cookware.name == "casserole")
    }

    @Test
    func parsesAMultiWordName() throws {
        let cookware = try #require(Recipe.read("Bring a #heavy pot# of water to a boil.").firstCookware)
        #expect(cookware.name == "heavy pot")
    }

    @Test(arguments: ["#heavy pot #", "#heavy pot\t#"])
    func trimsTheWhitespaceAroundAName(span: String) throws {
        #expect(try #require(Recipe.read("Bring a \(span) to a boil.").firstCookware).name == "heavy pot")
    }
}
