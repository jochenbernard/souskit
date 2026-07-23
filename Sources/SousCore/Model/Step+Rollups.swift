// The annotations rolled up across a run of steps, read the same way wherever a body is
// grouped: a recipe reads them across all of its steps, and a group reads them across its own.

extension [Step] {
    /// The ingredients annotated across the steps, in document order.
    var ingredients: [Ingredient] {
        flatMap(\.ingredients)
    }

    /// The cookware annotated across the steps, in document order.
    var cookware: [Cookware] {
        flatMap(\.cookware)
    }

    /// The timers annotated across the steps, in document order.
    var timers: [Timer] {
        flatMap(\.timers)
    }

    /// The references annotated across the steps, in document order.
    var references: [Reference] {
        flatMap(\.references)
    }
}
