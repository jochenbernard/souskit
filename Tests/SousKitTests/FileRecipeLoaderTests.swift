import Foundation
import SousKit
import Testing

@Suite("File recipe loader")
struct FileRecipeLoaderTests {
    /// Runs a body against a fresh folder holding the given files, keyed by path from the folder.
    private func withFolder(
        _ files: [String: Data],
        _ body: (URL) throws -> Void
    ) throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }

        for (path, contents) in files {
            let url = root.appendingPathComponent(path)
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try contents.write(to: url)
        }
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        try body(root)
    }

    /// Runs a body against a fresh folder holding the given text files.
    private func withFolder(
        texts: [String: String],
        _ body: (URL) throws -> Void
    ) throws {
        try withFolder(texts.mapValues({ Data($0.utf8) }), body)
    }

    @Test
    func readsTheFileAtAPathWithTheExtensionAdded() throws {
        try withFolder(texts: ["pasta/sauces/bolognese.sous": "Brown the @mince@."]) { root throws in
            #expect(try FileRecipeLoader(root: root).text(at: "pasta/sauces/bolognese") == "Brown the @mince@.")
        }
    }

    @Test
    func readsAFileWhoseNameHoldsSpacesAndAccents() throws {
        let texts = ["tomato sauce.sous": "Simmer it.", "b\u{E9}chamel.sous": "Whisk it."]

        try withFolder(texts: texts) { root throws in
            let loader = FileRecipeLoader(root: root)

            #expect(try loader.text(at: "tomato sauce") == "Simmer it.")
            #expect(try loader.text(at: "b\u{E9}chamel") == "Whisk it.")
        }
    }

    @Test
    func addsTheExtensionToANameAlreadyEndingInIt() throws {
        let texts = ["bolognese.sous": "Brown it.", "bolognese.sous.sous": "Brown it twice."]

        try withFolder(texts: texts) { root throws in
            #expect(try FileRecipeLoader(root: root).text(at: "bolognese.sous") == "Brown it twice.")
        }
    }

    @Test
    func readsNoFileWithoutTheExtension() throws {
        try withFolder(texts: ["bolognese": "Brown it."]) { root throws in
            #expect(try FileRecipeLoader(root: root).text(at: "bolognese") == nil)
        }
    }

    @Test(arguments: ["ragu", "sauces/ragu", "missing/folder/ragu", "notes/ragu", "folder", ""] as [RecipePath])
    func returnsNothingWhereNoRecipeFileExists(path: RecipePath) throws {
        let texts = ["notes": "A file, not a folder.", "folder.sous/inside.sous": "Nested."]

        try withFolder(texts: texts) { root throws in
            #expect(try FileRecipeLoader(root: root).text(at: path) == nil)
        }
    }

    @Test
    func throwsForAFileThatIsNotUTF8() throws {
        try withFolder(["bolognese.sous": Data([0xFF, 0xFE, 0xFA])]) { root throws in
            #expect(throws: (any Error).self) {
                try FileRecipeLoader(root: root).text(at: "bolognese")
            }
        }
    }

    @Test
    func resolvesReferencesAcrossFolders() throws {
        let texts = [
            "pasta/lasagna.sous": "Layer the >sauces/bolognese>, the >../shared/stock>, and the >bechamel>.",
            "pasta/sauces/bolognese.sous": "---\ntitle: Bolognese\n---\n\nBrown the @mince@.",
            "shared/stock.sous": "---\ntitle: Stock\n---\n\nSimmer the @bones@.",
            "pasta/bechamel.sous": "---\ntitle: Bechamel\n---\n\nWhisk the @milk@."
        ]

        try withFolder(texts: texts) { root throws in
            let loader = FileRecipeLoader(root: root)
            let path: RecipePath = "pasta/lasagna"
            let lasagna = try #require(try loader.recipe(at: path)).value
            let resolutions = try lasagna.references.map({ try lasagna.resolve($0, from: path, using: loader) })
            let resolved = resolutions.compactMap { resolution -> String? in
                guard case let .recipe(parsed, path: path)? = resolution else { return nil }

                return "\(path): \(parsed.value.metadata.title ?? "")"
            }

            #expect(resolved == [
                "pasta/sauces/bolognese: Bolognese",
                "shared/stock: Stock",
                "pasta/bechamel: Bechamel"
            ])
        }
    }
}
