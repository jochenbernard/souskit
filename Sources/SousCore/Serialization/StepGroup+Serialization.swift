extension StepGroup {
    /// The group as source text: its heading, when it carries a name, and then its steps.
    ///
    /// A heading ends the paragraph before it, so the first step needs no blank line between
    /// it and the heading, while the steps after it are separated by one like every other
    /// block. The default group states no heading, so one holding no step states nothing.
    func serialized() -> String {
        let body = steps.map({ $0.serialized() }).joined(separator: "\n\n")
        guard let name else { return body }

        let heading = Heading.line(naming: name)

        return body.isEmpty ? heading : "\(heading)\n\(body)"
    }
}
