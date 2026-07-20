// Resolves positions in the source text to a line, column, and offset, so a diagnostic
// can point at the construct it describes.
//
// Lines and columns are one-based; the offset is a zero-based character offset.

struct SourceMap {
    private let source: String
    private let lineStarts: [String.Index]

    init(_ source: String) {
        self.source = source

        var starts = [source.startIndex]
        var cursor = source.startIndex
        while cursor < source.endIndex {
            if source[cursor].isNewline {
                starts.append(source.index(after: cursor))
            }
            cursor = source.index(after: cursor)
        }
        lineStarts = starts
    }

    func location(at index: String.Index) -> SourceLocation {
        var line = 1
        var lineStart = source.startIndex

        for (number, start) in lineStarts.enumerated() {
            guard start <= index else { break }
            line = number + 1
            lineStart = start
        }

        return SourceLocation(
            line: line,
            column: source.distance(from: lineStart, to: index) + 1,
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
