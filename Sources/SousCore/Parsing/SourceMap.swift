/// Converts between string indices, character offsets, and source locations.
struct SourceMap {
    private let source: String
    private let lineStarts: [String.Index]
    private let lineOffsets: [Int]
    private let endOffset: Int

    init(_ source: String, lines: [Substring]) {
        self.source = source
        self.lineStarts = lines.map(\.startIndex)

        var offsets: [Int] = []
        var offset = 0
        for line in lines {
            offsets.append(offset)
            offset += line.count + 1
        }
        self.lineOffsets = offsets

        self.endOffset = offset - 1
    }

    /// The character offset of a string index.
    func offset(of index: String.Index) -> Int {
        let number = lineNumber(startingAtOrBefore: index, in: lineStarts)
        return lineOffsets[number] + source.distance(from: lineStarts[number], to: index)
    }

    /// The location at a character offset, clamped to the bounds of the source.
    func location(atOffset offset: Int) -> SourceLocation {
        let bounded = min(max(offset, 0), endOffset)
        let number = lineNumber(startingAtOrBefore: bounded, in: lineOffsets)
        return SourceLocation(
            line: number + 1,
            column: bounded - lineOffsets[number] + 1,
            offset: bounded
        )
    }

    /// The range covering a length of characters from an offset.
    func range(fromOffset offset: Int, length: Int) -> SourceRange {
        SourceRange(
            start: location(atOffset: offset),
            end: location(atOffset: offset + length)
        )
    }

    /// The range covering a length of characters from a string index.
    func range(from start: String.Index, length: Int) -> SourceRange {
        range(fromOffset: offset(of: start), length: length)
    }

    // Binary search: a linear scan here would be quadratic over a whole source.
    private func lineNumber<Position: Comparable>(
        startingAtOrBefore position: Position,
        in starts: [Position]
    ) -> Int {
        var low = 0
        var high = starts.count - 1

        while low < high {
            let middle = (low + high + 1) / 2
            if starts[middle] <= position {
                low = middle
            } else {
                high = middle - 1
            }
        }

        return low
    }
}
