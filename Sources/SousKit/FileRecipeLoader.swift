import Foundation

/// A recipe loader reading UTF-8 `.sous` files below a root folder.
///
/// A path's components name the folders below the root, then the file, to which `.sous` is always added. The
/// file system matches each name, so a case-insensitive volume matches regardless of case.
public struct FileRecipeLoader: RecipeLoader {
    /// The folder every path starts from.
    private let root: URL

    /// Creates a loader reading below a folder.
    ///
    /// - Parameter root: The folder every path starts from.
    public init(root: URL) {
        self.root = root
    }

    /// Reads the text of the recipe file at a path.
    ///
    /// - Parameter path: The path of the recipe, without the extension.
    /// - Returns: The text, or `nil` when no file sits at the path, including when a folder sits there or the
    ///   path runs through a file.
    /// - Throws: The error reading the file, such as when its contents are not UTF-8.
    public func text(at path: RecipePath) throws -> String? {
        guard let name = path.components.last else {
            return nil
        }

        let folder = path.components.dropLast().reduce(root) { url, component in
            url.appendingPathComponent(component, isDirectory: true)
        }
        let url = folder.appendingPathComponent("\(name).sous", isDirectory: false)

        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch let error as CocoaError where Self.reportsNoFile(error) {
            return nil
        }
    }

    /// Whether a read error reports that no file sits at the path read.
    private static func reportsNoFile(_ error: CocoaError) -> Bool {
        if error.code == .fileReadNoSuchFile {
            return true
        }

        guard
            let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError,
            underlying.domain == NSPOSIXErrorDomain
        else {
            return false
        }

        return [ENOTDIR, EISDIR].contains(Int32(underlying.code))
    }
}
