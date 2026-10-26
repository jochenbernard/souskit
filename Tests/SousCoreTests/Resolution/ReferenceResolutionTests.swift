import SousCore
import Testing

@Suite("Reference resolution")
struct ReferenceResolutionTests {
    /// A loader that fails every read, to show a resolution reads nothing.
    private struct FailingLoader: RecipeLoader {
        struct Failure: Error {}

        func text(at _: RecipePath) throws -> String? {
            throw Failure()
        }
    }

    private let loader = InMemoryRecipeLoader([
        "pasta/sauces/bolognese": "---\ntitle: Bolognese\n---\n\nBrown the @mince@.",
        "pasta/bechamel": "---\ntitle: Bechamel\n---\n\nWhisk the @milk@.",
        "pasta/tomato sauce": "---\ntitle: Tomato Sauce\n---\n\nSimmer the @tomatoes@.",
        "shared/stock": "---\ntitle: Stock\n---\n\nSimmer the @bones@.",
        "bechamel": "---\ntitle: Root Bechamel\n---\n\nWhisk the @milk@.",
        "pasta/broken": "Stir in @{2 tbsp flour@."
    ])

    /// The resolution of the first reference in a source read from a path.
    private func resolve(
        _ source: String,
        using loader: some RecipeLoader,
        from path: RecipePath = "pasta/lasagna"
    ) throws -> Recipe.Resolution? {
        let recipe = Recipe.read(source)
        let reference = try #require(recipe.firstReference)

        return try recipe.resolve(reference, from: path, using: loader)
    }

    /// The path and title of the recipe the first reference in a source resolves to.
    private func resolvedRecipe(
        _ source: String,
        from path: RecipePath = "pasta/lasagna"
    ) throws -> (path: RecipePath, title: String?)? {
        guard case let .recipe(parsed, path: resolvedPath)? = try resolve(source, using: loader, from: path) else {
            return nil
        }

        return (resolvedPath, parsed.value.metadata.title)
    }

    @Test
    func resolvesAPathIntoAFolderBesideTheReferencingFile() throws {
        let resolved = try #require(try resolvedRecipe("Layer the >sauces/bolognese>."))

        #expect(resolved.path == "pasta/sauces/bolognese")
        #expect(resolved.title == "Bolognese")
    }

    @Test
    func resolvesAPathClimbingOutOfTheReferencingFolder() throws {
        let resolved = try #require(try resolvedRecipe("Pour in the >../shared/stock>."))

        #expect(resolved.path == "shared/stock")
        #expect(resolved.title == "Stock")
    }

    @Test
    func resolvesABareNameMatchingNoGroupToTheFileInTheSameFolder() throws {
        let resolved = try #require(try resolvedRecipe("Layer the >bechamel>."))

        #expect(resolved.path == "pasta/bechamel")
        #expect(resolved.title == "Bechamel")
    }

    @Test
    func resolvesABareNameFromARecipeAtTheRoot() throws {
        let resolved = try #require(try resolvedRecipe("Layer the >bechamel>.", from: "lasagna"))

        #expect(resolved.path == "bechamel")
        #expect(resolved.title == "Root Bechamel")
    }

    @Test
    func resolvesFromAnEmptyPathAsFromTheRoot() throws {
        let resolved = try #require(try resolvedRecipe("Layer the >bechamel>.", from: ""))

        #expect(resolved.path == "bechamel")
    }

    @Test
    func resolvesANameHoldingSpaces() throws {
        let resolved = try #require(try resolvedRecipe("Spoon over the >tomato sauce>."))

        #expect(resolved.path == "pasta/tomato sauce")
        #expect(resolved.title == "Tomato Sauce")
    }

    @Test
    func resolvesALeadingDotSlashToTheFileOverAGroupOfTheSameName() throws {
        let source = "## Bechamel\nWhisk it.\n\n## Assemble\nLayer the >./bechamel>."
        let resolved = try #require(try resolvedRecipe(source))

        #expect(resolved.path == "pasta/bechamel")
    }

    @Test(arguments: [
        ("sauces/./bolognese", "pasta/sauces/bolognese"),
        ("sauces/../bechamel", "pasta/bechamel"),
        ("../pasta/bechamel", "pasta/bechamel"),
        ("../bechamel", "bechamel")
    ] as [(String, RecipePath)])
    func resolvesDotComponentsWithinThePath(written: String, path: RecipePath) throws {
        #expect(try resolvedRecipe("Layer the >\(written)>.")?.path == path)
    }

    @Test
    func resolvesABareNameMatchingAGroupToTheGroupWithoutReading() throws {
        let recipe = Recipe.read("## Bechamel\nWhisk it.\n\n## Assemble\nLayer the >bechamel>.")
        let bechamel = try #require(recipe.groups.first)
        let reference = try #require(recipe.firstReference)

        #expect(try recipe.resolve(reference, from: "pasta/lasagna", using: FailingLoader()) == .group(bechamel))
    }

    @Test
    func keepsTheDiagnosticsOfTheReferencedRecipe() throws {
        let resolution = try resolve("Stir in the >broken>.", using: loader)
        guard case let .recipe(parsed, path: _)? = resolution else {
            Issue.record("Expected a recipe, got \(String(describing: resolution))")
            return
        }

        #expect(parsed.diagnostics.map(\.kind) == [.unclosedSpan])
    }

    @Test(arguments: [
        "sauces/ragu",
        "ragu",
        "Bechamel",
        "b\u{E9}chamel",
        "Sauces/bolognese",
        "sauces/bolognese.sous",
        "sauces"
    ])
    func resolvesNothingWhereNoRecipeIsHeld(written: String) throws {
        #expect(try resolve("Layer the >\(written)>.", using: loader) == nil)
    }

    @Test(arguments: [
        "../../stock",
        "../../../pasta/bechamel",
        "sauces//bolognese",
        "/bechamel",
        "sauces/",
        "sauces/..",
        "sauces/.",
        "./",
        ".",
        ".."
    ])
    func resolvesNothingForAPathNamingNoFileWithoutReading(written: String) throws {
        #expect(try resolve("Layer the >\(written)>.", using: FailingLoader()) == nil)
    }

    @Test
    func throwsWhatTheLoaderThrows() {
        #expect(throws: FailingLoader.Failure.self) {
            try resolve("Layer the >bechamel>.", using: FailingLoader())
        }
    }
}
