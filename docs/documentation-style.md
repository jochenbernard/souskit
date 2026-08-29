# Documentation style

This guide governs every comment under `Sources` and `Tests`: public DocC
documentation, internal and private doc comments, and inline comments. A good
comment says what a symbol is and what it guarantees, in one voice, at a length
a reader absorbs in one pass. The failures it exists to prevent are the comment
that argues for the design, the comment that narrates the code, and the comment
that poses a riddle; each costs the reader more attention than it returns.

## Rule 1: the summary is the contract

A summary is a single sentence giving what the symbol is, or what it does. The
reasoning that produced the design belongs in the commit message; failing that,
it belongs nowhere. A reader comes to use the symbol correctly, not to review
its history.

Never restate the symbol's name, and never dodge the restatement with a
synonym. The synonym is the worse failure: it leaves the codebase with two
nouns for one concept, and a reader cannot tell whether they denote different
things.

Rejected, for `SourceLocation` in
`Sources/SousCore/Diagnostic/SourceLocation.swift`:

```swift
/// A single position in the source.
```

"Position" is "location" in disguise. The accepted summary carries the
contract:

```swift
/// Where something sits in the source, given as a line, a column, and a character offset.
```

## Rule 2: no anthropomorphism

Code does not state, ask for, owe, or possess. Describe what it does: a parser
reads, a property holds, a function returns, a value is trimmed.

| Banned         | Write instead                |
| -------------- | ---------------------------- |
| states         | is, holds, contains, reports |
| asks, asks for | requires, takes              |
| owes           | returns, provides            |
| which is what  | end the sentence             |
| nobody wrote   | name the actual condition    |
| of its own     | delete it                    |

`so the` and `rather than` are restricted: admissible when they carry
information, never as connective filler between clauses already clear without
them. To test one, delete the phrase along with the clause it introduces.
Losing a fact means keep it; losing only rhythm means it was filler.

## Rule 3: a second paragraph must earn its place

Every paragraph after the summary faces one question: does it change what a
caller writes? If not, cut it.

- A public symbol gets the summary plus at most one short paragraph, admissible
  only where observable behavior would otherwise surprise a caller.
- An internal or private symbol gets one line. The sole exception is a trap
  note.
- An inline comment gets one line, for what the code below cannot convey, and
  never narrates the next statement.

A paragraph correctly cut, from `Amount.isFixed` in
`Sources/SousCore/Model/Amount.swift`. The cut paragraph made three points: the
`=` marker opens the fence, it fixes an imprecise amount as readily as a
numeric one, and on an imprecise amount, which scaling never moves, it records
only intent. A design argument; no caller writes anything differently for it.
What survived:

```swift
    /// Whether the fence's `=` marker holds this amount constant when the recipe is scaled.
    public var isFixed: Bool
```

A second paragraph correctly kept, on `ScalingError.unusableFactor` in
`Sources/SousCore/Scaling/ScalingError.swift`:

```swift
    /// The factor is negative, or is not a finite number.
    ///
    /// Zero is permitted; negative zero is not.
    case unusableFactor
```

That second line teaches the caller that zero is safe to pass and negative
zero is not; the case name conveys neither, and a wrong guess produces an
error. The paragraph originally went on to explain why, and Rule 3 cut that
part.

### Trap notes

An internal symbol may record why the obvious simpler implementation is wrong.
That is the one thing a maintainer cannot recover from the code, and it earns
space nothing else gets: one line, extended only where the invariant the trap
turns on must sit beside it. The note names the trap, never the history; it is
no route back to a design argument. From `FenceSearch` in
`Sources/SousCore/Parsing/FenceSearch.swift`:

```swift
/// Finds the brace an amount fence closes on, remembering the region already searched.
///
/// Memoized: a line holding no closing brace would otherwise have every fence on it scan to the
/// line end, which is quadratic. A search starting outside the remembered region starts over, so
/// the answer never depends on the order the questions arrive in.
```

The trap is the fresh scan per fence; the extension is the invariant the
memoization turns on, and its `so the` carries a fact. A second instance sits
on `DeclaredYield.matching(_:)` in
`Sources/SousCore/Scaling/DeclaredYield.swift`, where the trap is normalizing
units the way group names are and conflating `T` with `t`.

## DocC structured sections

Rule 3 governs prose only. Every public symbol taking a parameter or returning
a value carries `- Parameter` and `- Returns` sections, even where a tag only
restates a name and a type: Xcode Quick Help renders these sections, and a
symbol without them reads as undocumented there however complete its summary
is. From `Normalization.normalized(_:)` in
`Sources/SousCore/Normalization/Normalization.swift`, whole:

```swift
    /// The matching form of a name: lowercased, accent-folded, and trimmed.
    ///
    /// This is idempotent: normalizing an already normalized name returns it unchanged.
    ///
    /// - Parameter text: The name to reduce.
    /// - Returns: The matching form.
    public static func normalized(_ text: String) -> String {
```

## Test files

Test method names and `@Suite` display names are the documentation, and no
prose blocks sit above suites or cases. A comment is admissible only where a
name cannot carry why the case exists: a regression against a specific past
bug, or a non-obvious reason for the shape the case takes. Shared helpers in a
test support file are ordinary internal symbols, governed by Rule 3.

## Mechanics

The first two rules below also cover the Markdown files in this repository,
this document included.

- ASCII only, in comments and string literals alike. Write a non-ASCII
  character as an escape, as in "Cr\u{EA}pes". The build reports no literal
  non-ASCII character, leaving this rule and the second command under Checking
  as the only enforcement.
- No em-dash constructions: neither the character itself nor a double hyphen
  standing in for one.
- Lines fit in 120 characters; SwiftLint reports the overruns.
- A public declaration without a doc comment is reported by the SwiftLint rule
  `missing_docs`, active because `.swiftlint.yml` sets `opt_in_rules: all`. Its
  severity is warning; nothing fails on it.
- Exempt from all of the above: the `// swift-tools-version:` line in
  `Package.swift`, and any `// swiftlint:` comment.

## Checking

Run these from the repository root. Each is expected to print nothing.

```bash
# Banned vocabulary, conjugations included. "State" as a noun is fine,
# as in "a parser holds no state".
find Sources Tests -name '*.swift' | xargs grep -niE '^[[:space:]]*//.*\b(state|states|stating|stated|ask|asks|asking|owe|owes|of its own|which is what|nobody wrote)\b' | grep -v 'holds no state'

# Non-ASCII anywhere in source, which also catches a literal em-dash
LC_ALL=C grep -rn '[^ -~]' Sources Tests --include='*.swift'

# Double hyphen standing in for an em-dash
find Sources Tests -name '*.swift' | xargs grep -nE '^[[:space:]]*//.*[^-]-{2}[^-]'
```

SwiftLint covers the rest: `swiftlint lint Sources Tests` reports line length
and missing docs.
