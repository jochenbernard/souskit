// Resolves positions in the source text to a line, column, and offset, so a diagnostic
// can point at the construct it describes.
//
// Lines and columns are one-based; the offset is a zero-based character offset.

struct SourceMap {
    private let source: String
    private let lineStarts: [String.Index]

    /// The lines are the source already split on newlines, so their start indices are the
    /// line starts and the source is not scanned a second time.
    init(_ source: String, lines: [Substring]) {
        self.source = source
        self.lineStarts = lines.map(\.startIndex)
    }

    func location(at index: String.Index) -> SourceLocation {
        let number = lineStarts.lastIndex(where: { $0 <= index }) ?? 0

        return SourceLocation(
            line: number + 1,
            column: source.distance(from: lineStarts[number], to: index) + 1,
            offset: source.distance(from: source.startIndex, to: index)
        )
    }

    func index(_ base: String.Index, offsetBy offset: Int) -> String.Index {
        source.index(base, offsetBy: offset, limitedBy: source.endIndex) ?? source.endIndex
    }

    func range(from start: String.Index, length: Int) -> SourceRange {
        SourceRange(
            start: location(at: start),
            end: location(at: index(start, offsetBy: length))
        )
    }

    /// A range measured from a base position, used where a scanner works in offsets
    /// within a paragraph rather than in source indices.
    func range(from base: String.Index, offset: Int, length: Int) -> SourceRange {
        range(from: index(base, offsetBy: offset), length: length)
    }
}
