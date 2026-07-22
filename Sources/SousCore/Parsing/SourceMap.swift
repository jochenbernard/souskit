// Resolves positions in the source text to a line, column, and offset, so a diagnostic
// can point at the construct it describes.
//
// Lines and columns are one-based; the offset is a zero-based character offset. A position
// becomes an offset once, and every location is resolved from that offset, so a diagnostic
// deep inside a paragraph costs no more to place than one at its start.

struct SourceMap {
    private let source: String
    private let lineStarts: [String.Index]
    private let lineOffsets: [Int]

    /// The offset just past the last character, which every lookup is clamped to.
    private let endOffset: Int

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
        // The running total counted a break after the last line, which the source has not.
        self.endOffset = offset - 1
    }

    /// The offset an index falls at. It is the one lookup that walks the text, so a caller
    /// with many positions in one region resolves the region once and counts from there.
    func offset(of index: String.Index) -> Int {
        let number = lineNumber(startingAtOrBefore: { lineStarts[$0] <= index })

        return lineOffsets[number] + source.distance(from: lineStarts[number], to: index)
    }

    /// The location an offset falls at. An offset past the end of the source resolves to its
    /// last position rather than to nothing, so a range that overshoots still points somewhere.
    func location(atOffset offset: Int) -> SourceLocation {
        let bounded = min(max(offset, 0), endOffset)
        let number = lineNumber(startingAtOrBefore: { lineOffsets[$0] <= bounded })

        return SourceLocation(
            line: number + 1,
            column: bounded - lineOffsets[number] + 1,
            offset: bounded
        )
    }

    func range(fromOffset offset: Int, length: Int) -> SourceRange {
        SourceRange(
            start: location(atOffset: offset),
            end: location(atOffset: offset + length)
        )
    }

    func range(from start: String.Index, length: Int) -> SourceRange {
        range(fromOffset: offset(of: start), length: length)
    }

    /// The zero-based number of the line a position falls on, decided by whether the line of
    /// a given number starts at or before it. The lines ascend, so bisecting them keeps a
    /// lookup from walking every line before the one it wants.
    private func lineNumber(startingAtOrBefore isAtOrBefore: (Int) -> Bool) -> Int {
        var low = 0
        var high = lineStarts.count - 1

        while low < high {
            let middle = (low + high + 1) / 2
            if isAtOrBefore(middle) {
                low = middle
            } else {
                high = middle - 1
            }
        }

        return low
    }
}
