extension StepGroup {
    /// The group as source text: its heading when it has a name, then its steps separated by
    /// blank lines.
    func serialized() -> String {
        let body = steps.map({ $0.serialized() }).joined(separator: "\n\n")
        guard let name else { return body }

        let heading = Heading.line(naming: name)

        return body.isEmpty ? heading : "\(heading)\n\(body)"
    }
}
