// swiftlint:disable:this file_name

extension [Step] {
    /// The ingredients annotated across these steps, in document order.
    var ingredients: [Ingredient] {
        flatMap(\.ingredients)
    }

    /// The cookware annotated across these steps, in document order.
    var cookware: [Cookware] {
        flatMap(\.cookware)
    }

    /// The timers annotated across these steps, in document order.
    var timers: [Timer] {
        flatMap(\.timers)
    }

    /// The references annotated across these steps, in document order.
    var references: [Reference] {
        flatMap(\.references)
    }
}
