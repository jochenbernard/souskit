/// Where a recipe sits in a collection: the folders leading to it, then its name, without an extension.
public struct RecipePath: Equatable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    /// The folder names leading to the recipe, then the recipe's name, each kept as written.
    public var components: [String]

    /// Creates a path from components separated by slashes.
    ///
    /// Empty components are dropped, so `pasta//lasagna/` equals `pasta/lasagna`. Components `.` and `..` are
    /// kept as written.
    ///
    /// - Parameter string: The slash-separated path, such as `pasta/sauces/bolognese`.
    public init(_ string: String) {
        self.init(components: string.split(separator: "/").map(String.init))
    }

    /// Creates a path from a string literal of components separated by slashes.
    ///
    /// - Parameter value: The slash-separated path.
    public init(stringLiteral value: String) {
        self.init(value)
    }

    /// Creates a path from its components.
    init(components: [String]) {
        self.components = components
    }

    /// The components joined by slashes.
    public var description: String {
        components.joined(separator: "/")
    }

    /// The path a reference's relative path leads to from the recipe at this path, or `nil` when it names no file.
    ///
    /// Trap: climbing above the root must fail rather than stop there, or a recipe could reach a file outside the
    /// collection a loader reads.
    func resolving(_ relativePath: String) -> Self? {
        let parts = relativePath.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard let name = parts.last, !["", ".", ".."].contains(name) else {
            return nil
        }

        var resolved = Array(components.dropLast())
        for part in parts {
            switch part {
            case "":
                return nil

            case ".":
                continue

            case "..":
                guard resolved.popLast() != nil else {
                    return nil
                }

            default:
                resolved.append(part)
            }
        }

        return Self(components: resolved)
    }
}
