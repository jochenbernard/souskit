/// Where a paragraph sits in the source, so offsets within it can be reported.
struct Origin {
    /// The paragraph's offset from the start of the source.
    let start: Int

    let map: SourceMap

    /// The range covering a length of characters at an offset within the paragraph.
    func range(offset: Int, length: Int) -> SourceRange {
        map.range(fromOffset: start + offset, length: length)
    }
}
