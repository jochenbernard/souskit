import SousCore
import Testing

@Suite("In-memory recipe loader")
struct InMemoryRecipeLoaderTests {
    private let loader = InMemoryRecipeLoader([
        "sauces/bolognese": "---\ntitle: Bolognese\n---\n\nBrown the @mince@."
    ])

    @Test
    func returnsTheTextAtAPath() {
        #expect(loader.text(at: "sauces/bolognese") == "---\ntitle: Bolognese\n---\n\nBrown the @mince@.")
    }

    @Test(arguments: ["sauces/ragu", "bolognese", "Sauces/Bolognese", "sauces", ""] as [RecipePath])
    func returnsNothingWhereNoTextIsHeld(path: RecipePath) {
        #expect(loader.text(at: path) == nil)
    }

    @Test
    func parsesTheRecipeAtAPath() throws {
        let parsed = try #require(try loader.recipe(at: "sauces/bolognese"))

        #expect(parsed.value.metadata.title == "Bolognese")
        #expect(parsed.diagnostics.isEmpty)
    }

    @Test
    func keepsTheDiagnosticsOfTheRecipeAtAPath() throws {
        let stockLoader = InMemoryRecipeLoader(["stock": "Simmer @{2 kg bones@."])
        let parsed = try #require(try stockLoader.recipe(at: "stock"))

        #expect(parsed.diagnostics.map(\.kind) == [.unclosedSpan])
    }

    @Test
    func parsesNoRecipeWhereNoTextIsHeld() throws {
        #expect(try loader.recipe(at: "sauces/ragu") == nil)
    }
}
