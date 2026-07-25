// Divides a recipe body into its step groups: a heading opens a group, and the lines from it
// up to the next heading are its steps. The lines before the first heading form the unnamed
// default group.

enum GroupParser {
    /// The groups the body's lines form. A heading opens one, and the lines from it up to the
    /// next heading are the steps of that group.
    ///
    /// The lines before the first heading form the unnamed default group, which is left out
    /// when it holds no step, so a body opening with a heading forms no default group and a
    /// body of nothing forms no group at all.
    static func parse(
        _ lines: [Substring],
        map: SourceMap,
        diagnostics: inout [Diagnostic]
    ) -> [StepGroup] {
        var groups: [StepGroup] = []

        for run in runs(in: lines) {
            let groupSteps = steps(in: run.lines, map: map, diagnostics: &diagnostics)
            guard run.name != nil || !groupSteps.isEmpty else { continue }

            groups.append(StepGroup(name: run.name, steps: groupSteps))
        }

        return groups
    }

    /// The runs of body lines the headings divide the body into, each carrying the name of the
    /// group it opens. The first run is the default group's and carries none.
    ///
    /// A heading line belongs to no run. It opens a group only where no step line stands
    /// directly before it, so a blank line, another heading, or the start of the body is what
    /// lets one open, and a heading line a step continues is that step's prose.
    private static func runs(in lines: [Substring]) -> [(name: String?, lines: [Substring])] {
        var runs: [(name: String?, lines: [Substring])] = [(name: nil, lines: [])]
        var continuesAStep = false

        for line in lines {
            if !continuesAStep, let name = Heading.name(of: line) {
                runs.append((name: name, lines: []))
            } else {
                runs[runs.count - 1].lines.append(line)
                continuesAStep = !SourceText.isBlank(line)
            }
        }

        return runs
    }

    /// A step is one paragraph: a maximal run of consecutive non-blank lines.
    private static func steps(
        in lines: [Substring],
        map: SourceMap,
        diagnostics: inout [Diagnostic]
    ) -> [Step] {
        var steps: [Step] = []

        for paragraph in lines.split(whereSeparator: SourceText.isBlank) {
            guard let first = paragraph.first else { continue }

            steps.append(StepParser.parse(
                paragraph.joined(separator: "\n"),
                origin: StepParser.Origin(start: map.offset(of: first.startIndex), map: map),
                diagnostics: &diagnostics
            ))
        }

        return steps
    }
}
