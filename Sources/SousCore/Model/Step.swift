/// One step of a recipe, read from a single paragraph.
public struct Step: Equatable, Hashable, Sendable {
    /// The prose and annotations of the step, in document order.
    public var segments: [Segment]

    /// The step as written, sigils and escapes included.
    ///
    /// Every line break is normalized to a line feed, whatever the source wrote.
    public var text: String

    /// The ingredients annotated in this step, in document order.
    public var ingredients: [Ingredient] {
        segments.compactMap(\.ingredient)
    }

    /// The cookware annotated in this step, in document order.
    public var cookware: [Cookware] {
        segments.compactMap(\.cookware)
    }

    /// The timers annotated in this step, in document order.
    public var timers: [Timer] {
        segments.compactMap(\.timer)
    }

    /// The references annotated in this step, in document order.
    public var references: [Reference] {
        segments.compactMap(\.reference)
    }
}
