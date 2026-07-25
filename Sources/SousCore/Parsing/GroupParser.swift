/// Splits a recipe body into groups and their steps.
enum GroupParser {
    /// The groups of the body, in document order.
    ///
    /// Steps written before any heading form a group whose name is `nil`. A run holding neither a
    /// heading nor a step contributes no group, so a body of only blank lines yields none.
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

    /// The lines grouped under each heading.
    ///
    /// A heading is only recognized on a line that starts a paragraph, so `## text` in the middle
    /// of a step continues that step rather than opening a group.
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

    /// The steps of a run, one per paragraph separated by blank lines.
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
