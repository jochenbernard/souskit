// The annotation a segment was read from, which is what lets the writer ask the shared
// table what a segment allows rather than restating the answer per case.

extension Segment {
    /// The annotation the segment stands for, or `nil` for a run of prose.
    var annotation: Annotation? {
        switch self {
        case .text: nil
        case .ingredient: .ingredient
        case .cookware: .cookware
        case .timer: .timer
        // The reference sigil joins the shared table with the reading rules that give it a
        // meaning, so until then no segment names it.
        case .reference: nil
        }
    }
}
