enum NormalizedLayouts {
    /// Sources whose layout serializing normalizes, so re-reading them is stable but their text
    /// is not preserved byte for byte.
    static let sources = [
        "Toast the baguette.\n",
        "Toast the baguette.\n\n",
        "\nToast the baguette.",
        "First step.\n\n\nSecond step.",
        "---\n---",
        "---\ntitle: Tartine Beurree\n---\nBody line.",
        "Sift @{200 g}flour@.",
        "Sift @{200 g}  flour@.",
        "Sift @flour @.",
        "Add @{ 200 g } flour@.",
        "Add @{200\tg} flour@.",
        "Wait ~40 min ~ now.",
        "Layer the >{300 g}  bechamel> in a dish.",
        "##  Filling\nBrown the beef.",
        "##\tFilling\nBrown the beef.",
        "Toast the baguette.\n   \nSpread with butter.",
        "--- \ntitle: Tartine Beurree\n--- ",
        "Add @{200 g}@ now.",
        "Toast the baguette\u{2028}and butter it.",
        "---\ntitle:  Tartine Beurree\n---",
        "---\ntitle:\tTartine Beurree\n---",
        "---\ntags: [french, quick] \n---",
        "---\ntags:  [french, quick]\n---"
    ]
}
