enum NormalizedLayouts {
    /// Sources whose layout serializing normalizes, so re-reading them is stable but their text
    /// is not preserved byte for byte.
    static let sources = [
        "Whisk the vinegar.\n",
        "Whisk the vinegar.\n\n",
        "\nWhisk the vinegar.",
        "First step.\n\n\nSecond step.",
        "---\n---",
        "---\ntitle: Vinaigrette\n---\nBody line.",
        "Sift @{200 g}flour@.",
        "Sift @{200 g}  flour@.",
        "Sift @flour @.",
        "Add @{ 200 g } flour@.",
        "Add @{200\tg} flour@.",
        "Wait ~40 min ~ now.",
        "Layer the >{300 g}  bechamel> in a dish.",
        "##  Filling\nBrown the beef.",
        "##\tFilling\nBrown the beef.",
        "Whisk the vinegar.\n   \nBeat in the oil.",
        "--- \ntitle: Vinaigrette\n--- ",
        "Add @{200 g}@ now.",
        "Whisk the vinegar\u{2028}and beat in the oil.",
        "---\ntitle:  Vinaigrette\n---",
        "---\ntitle:\tVinaigrette\n---",
        "---\ntags: [french, quick] \n---",
        "---\ntags:  [french, quick]\n---"
    ]
}
