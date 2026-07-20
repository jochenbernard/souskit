extension Recipe {
    /// Renders the recipe back to Sous source text.
    ///
    /// The round-trip is non-destructive: any content the reader did not modify is reproduced exactly.
    ///
    /// - Returns: The recipe rendered as Sous source text.
    public func serialized() -> String {
        var blocks: [String] = []

        if !metadata.entries.isEmpty {
            blocks.append(Self.rendered(metadata))
        }

        if !steps.isEmpty {
            blocks.append(steps.map(Self.rendered).joined(separator: "\n\n"))
        }

        return blocks.joined(separator: "\n\n")
    }

    private static func rendered(_ metadata: Metadata) -> String {
        var lines = ["---"]

        for entry in metadata.entries {
            switch entry.value {
            case let .scalar(value):
                lines.append("\(entry.key): \(value)")
            case let .list(items):
                lines.append("\(entry.key): [\(items.joined(separator: ", "))]")
            }
        }

        lines.append("---")

        return lines.joined(separator: "\n")
    }

    private static func rendered(_ step: Step) -> String {
        step.segments.map(Self.rendered).joined()
    }

    private static func rendered(_ segment: Segment) -> String {
        switch segment {
        case let .text(text):
            text
        case let .ingredient(ingredient):
            rendered(ingredient)
        case let .cookware(cookware):
            "#\(cookware.name)#"
        }
    }

    private static func rendered(_ ingredient: Ingredient) -> String {
        guard let amount = ingredient.amount else {
            return "@\(ingredient.name)@"
        }

        return "@{\(amount.text)} \(ingredient.name)@"
    }
}
