extension Segment {
    /// The annotation kind this segment holds, or `nil` for prose.
    var annotation: Annotation? {
        switch self {
        case .text: nil
        case .ingredient: .ingredient
        case .cookware: .cookware
        case .timer: .timer
        case .reference: .reference
        }
    }
}
