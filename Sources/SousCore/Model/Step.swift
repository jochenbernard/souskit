/// A single step of a recipe, corresponding to one paragraph of the body.
public struct Step: Equatable, Hashable, Sendable {
    /// The step's body, as an ordered list of prose and annotation segments.
    ///
    /// The segments are the store the annotation lists read, so editing them moves the lists with them.
    public var segments: [Segment]

    /// The step's source text, with any line endings within it normalized to line feeds.
    ///
    /// Scaling rewrites it from ``segments`` for a step whose amounts moved, and leaves it as
    /// read for one whose amounts did not.
    public var text: String

    /// The ingredients annotated in the step, in document order.
    public var ingredients: [Ingredient] {
        segments.compactMap(\.ingredient)
    }

    /// The cookware annotated in the step, in document order.
    public var cookware: [Cookware] {
        segments.compactMap(\.cookware)
    }

    /// The timers annotated in the step, in document order.
    public var timers: [Timer] {
        segments.compactMap(\.timer)
    }

    /// The references annotated in the step, in document order.
    public var references: [Reference] {
        segments.compactMap(\.reference)
    }
}
