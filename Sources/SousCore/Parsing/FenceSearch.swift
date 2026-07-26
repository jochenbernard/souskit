/// Finds the brace an amount fence closes on, remembering the region already searched.
///
/// Memoized: a line holding no closing brace would otherwise have every fence on it scan to the
/// line end, which is quadratic. A search starting outside the remembered region starts over, so
/// the answer never depends on the order the questions arrive in.
struct FenceSearch {
    private var searchedFrom = 0
    private var searchedTo = 0

    mutating func closingBrace(in characters: [Character], from start: Int) -> Int? {
        let from: Int
        if start >= searchedFrom, start <= searchedTo {
            from = searchedTo
        } else {
            from = start
            searchedFrom = start
        }

        let cursor = SourceText.firstUnescaped(
            AmountFence.closing,
            in: characters,
            from: from
        )
        searchedTo = cursor

        return cursor < characters.count && characters[cursor] == AmountFence.closing ? cursor : nil
    }
}
