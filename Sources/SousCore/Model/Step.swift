/// A single step of a recipe, corresponding to one paragraph of the body.
public struct Step: Equatable, Hashable, Sendable {
    /// The step's body, as an ordered list of prose and annotation segments.
    public var segments: [Segment]

    /// The ingredients annotated in the step, in document order.
    public var ingredients: [Ingredient]

    /// The cookware annotated in the step, in document order.
    public var cookware: [Cookware]

    /// The step's source text, with any line endings within it normalized to line feeds.
    public var text: String
}
