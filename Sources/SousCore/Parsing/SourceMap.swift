// Resolves positions in the source text to a line, column, and offset, so a diagnostic
// can point at the construct it describes.
//
// Lines and columns are one-based; the offset is a zero-based character offset.

struct SourceMap {
    private let source: String
    private let lineStarts: [String.Index]
    private let lineOffsets: [Int]

    /// The lines are the source already split on newlines, so their start indices are the
    /// line starts and the source is not scanned a second time. Splitting yields at least
    /// one line for any source, so there is always a line to resolve against.
    init(_ source: String, lines: [Substring]) {
        self.source = source
        self.lineStarts = lines.map(\.startIndex)

        // Each line start's offset, accumulated once here rather than measured from the
        // start of the source on every lookup. One line break separates two lines, and a
        // Windows line ending is a single character, so counting one per line is exact.
        var offsets: [Int] = []
        var offset = 0
        for line in lines {
            offsets.append(offset)
            offset += line.count + 1
        }
        self.lineOffsets = offsets
    }

    func location(at index: String.Index) -> SourceLocation {
        let number = lineNumber(at: index)
        let column = source.distance(from: lineStarts[number], to: index) + 1

        return SourceLocation(
            line: number + 1,
            column: column,
            offset: lineOffsets[number] + column - 1
        )
    }

    /// The zero-based number of the line an index falls on. The line starts ascend, so
    /// bisecting them keeps a lookup from walking every line before the one it wants.
    private func lineNumber(at index: String.Index) -> Int {
        var low = 0
        var high = lineStarts.count - 1

        while low < high {
            let middle = (low + high + 1) / 2
            if lineStarts[middle] <= index {
                low = middle
            } else {
                high = middle - 1
            }
        }

        return low
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
}
