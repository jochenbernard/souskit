import SousCore
import Testing

@Suite("Recipe paths")
struct RecipePathTests {
    @Test
    func splitsAPathAtEachSlash() {
        #expect(RecipePath("pasta/sauces/bolognese").components == ["pasta", "sauces", "bolognese"])
    }

    @Test
    func keepsANameAsWritten() {
        #expect(RecipePath("Tomato Sauce").components == ["Tomato Sauce"])
        #expect(RecipePath("b\u{E9}chamel").components == ["b\u{E9}chamel"])
        #expect(RecipePath(" stock ").components == [" stock "])
    }

    @Test(arguments: [
        ("pasta//bolognese", ["pasta", "bolognese"]),
        ("/pasta/bolognese/", ["pasta", "bolognese"]),
        ("", []),
        ("/", [])
    ])
    func dropsEmptyComponents(string: String, components: [String]) {
        #expect(RecipePath(string).components == components)
    }

    @Test
    func keepsDotComponentsAsWritten() {
        #expect(RecipePath("./pasta/../bolognese").components == [".", "pasta", "..", "bolognese"])
    }

    @Test
    func readsAStringLiteralAsAPath() {
        let path: RecipePath = "pasta/lasagna"

        #expect(path == RecipePath("pasta/lasagna"))
    }

    @Test
    func describesItselfAsItsComponentsJoinedBySlashes() {
        #expect(RecipePath("pasta//tomato sauce/").description == "pasta/tomato sauce")
        #expect(RecipePath("").description.isEmpty)
    }

    @Test
    func equalsAPathOfTheSameComponents() {
        #expect(RecipePath("pasta/lasagna") == RecipePath("/pasta//lasagna"))
        #expect(RecipePath("pasta/lasagna") != RecipePath("Pasta/lasagna"))
        #expect(Set([RecipePath("pasta/lasagna"), RecipePath("pasta/lasagna/")]).count == 1)
    }
}
