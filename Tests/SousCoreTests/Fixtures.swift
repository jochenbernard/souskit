enum Fixtures {
    /// A source exercising a header, an ingredient with an amount, and cookware.
    static let wellFormedSource = """
    ---
    title: Soupe a l'Oignon
    servings: 4
    ---

    Soften @{1 kg} onions@ in a #stockpot#.
    """

    /// A source with the given header and one ingredient of `200 g` flour.
    static func flourRecipe(_ header: String) -> String {
        "---\n\(header)\n---\n\nMix @{200 g} flour@."
    }
}
