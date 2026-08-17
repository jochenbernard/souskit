enum Fixtures {
    /// A reduction of ``Recipes/boeufBourguignon``, exercising a header, an ingredient with an
    /// amount, and cookware.
    static let wellFormedSource = """
    ---
    title: Boeuf Bourguignon
    servings: 6
    ---

    Brown @{150 g} lardons@ in a #casserole# for ~5 min~.
    """

    /// The opening of ``Recipes/crepes`` under the given header, whose one amount is `200 g` of
    /// flour.
    static func crepeBatter(_ header: String) -> String {
        "---\n\(header)\n---\n\nWhisk @{200 g} flour@ into a batter."
    }
}
