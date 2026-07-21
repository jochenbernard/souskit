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
        }
    }
}
