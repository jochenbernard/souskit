# Documentation style

This document governs every comment in this repository: public DocC comments, internal and
private doc comments, and inline comments, in `Sources` and in `Tests` alike. Its purpose is to
keep documentation stating what a symbol is and what it guarantees, in one voice, at a length the
reader can absorb. Documentation that argues for the design, narrates the code, or reads as a
riddle costs more attention than it returns. Read this document before writing or editing any
comment, and follow it exactly.

## The three rules

### Rule 1: the summary states the contract

One sentence saying what the symbol is, or what it does. It may not contain the reasoning that
produced it.

The reasoning belongs in a commit message, or nowhere. A reader reaching for a symbol wants to
know how to use it correctly, not how it came to be shaped that way.

### Rule 2: no anthropomorphism

Code does not state, ask for, or owe, and does not have things of its own. A parser reads, a
property holds, a function returns, a value is trimmed.

Banned outright:

| Banned | Use instead |
|--------|-------------|
| `states` | `is`, `holds`, `contains`, `reports` |
| `asks`, `asks for` | `requires`, `takes` |
| `owes` | `returns`, `provides` |
| `which is what` | end the sentence |
| `nobody wrote` | name the actual condition |
| `of its own` | delete it |

Restricted. These are permitted only where they carry information, never as connective filler
joining two clauses that were already clear apart:

* `so the`
* `rather than`

The test for a restricted phrase: delete it and the clause it introduces. If the reader loses a
fact, keep it. If they lose only rhythm, it was filler.

### Rule 3: a second paragraph must earn its place

The test is whether it changes what a caller writes. If it does not, cut it.

| Symbol kind | Budget |
|-------------|--------|
| Public | A summary, plus at most one short paragraph, and only where a caller would otherwise be surprised by observable behavior. |
| Internal and private | One line. |
| Inline | One line, flagging only what the following code cannot convey. Never a narration of the next statement. |

## DocC structured sections

Rule 3 governs prose. It does not govern DocC's structured sections.

Keep `- Parameter` and `- Returns` on every public symbol that takes a parameter or returns a
value, including where the tag only restates the name and type. Xcode Quick Help renders those
sections, and a symbol missing them reads as undocumented there even when its summary is complete.

```swift
/// Parses the content of an amount fence into an amount.
///
/// - Parameter text: The fence content to parse.
/// - Returns: The parsed amount.
public func parseAmount(_ text: String) -> Amount {
```

## Trap notes

Internal code sometimes holds knowledge of why the obvious simpler implementation is wrong. Keep
it, capped at one line, under the same rule that governs everything else: keep what the reader
cannot get from the code. For an internal helper the reader is a maintainer, and what they cannot
get by reading is why this shape and not the obvious one.

A trap note states the trap, not the history. It is not a place to reintroduce design argument.

```swift
// Memoized: a per-fence scan is quadratic on a line holding no closing brace.
private struct FenceSearch {
```

## Test files

Test method names and `@Suite` display names carry the documentation. They are already
descriptive, so prose blocks above suites and cases are removed.

A comment survives in a test file only where a name cannot convey why the case exists. In
practice that means a regression against a specific past bug, or a non-obvious reason the case is
written the way it is.

```swift
// Regression: `\## @a@` used to serialize as a group heading, destroying the step.
@Test
func escapesAHeadingAcrossSegments() throws {
```

Shared helpers in a test support file are ordinary internal symbols and take a one-line summary
under Rule 3.

## Mechanics

* ASCII only. No character outside the printable ASCII range in any comment.
* No em-dash constructions, neither the character nor a double hyphen standing in for one.
* Maximum line length 120, enforced by SwiftLint.
* Every public declaration must carry a doc comment. SwiftLint's `missing_docs` rule enforces
  this, because `.swiftlint.yml` sets `opt_in_rules: all`.
* Some comments are directives rather than documentation, and are exempt from everything above:
  `// swift-tools-version:` in `Package.swift`, and any `// swiftlint:` comment.

## Worked examples

### A summary carrying design argument

```swift
// Before
/// A textual amount, captured as the trimmed text states it: one with no leading
/// number, or one opening as a number it cannot finish, such as a decimal written with
/// a comma. Reading the second reports it, so a number nobody wrote never scales.
case imprecise(String)

// After
/// An amount with no usable leading number, such as "a pinch" or "1,5 l".
/// Scaling leaves it unchanged.
case imprecise(String)
```

Three sentences of reasoning collapse to one statement of the contract plus the one fact that
changes what a caller writes: scaling will not move this value.

### A property documented by argument

```swift
// Before
/// Whether the fence's `=` marker fixes the amount, holding it constant when the recipe is
/// scaled.
///
/// The marker opens the fence and states that the whole amount holds still, so it fixes an
/// imprecise amount as readily as a numeric one, whatever whitespace separates the two. An
/// imprecise amount never moves under scaling in any case, so there the marker records the
/// author's intent and nothing more.
public var isFixed: Bool

// After
/// Whether the fence's `=` marker holds this amount constant when the recipe is scaled.
public var isFixed: Bool
```

The second paragraph argued for the design. It changed nothing a caller writes, so Rule 3 cut it.

### An inline comment narrating the code

```swift
// Before
// A line break bounds the search, so the region remembered as holding no brace
// ends there and a fence opening past it starts a search of its own line.
let cursor = StepParser.firstUnescaped(AmountFence.closing, in: characters, from: from)

// After
let cursor = StepParser.firstUnescaped(AmountFence.closing, in: characters, from: from)
```

The call names what it does. The comment restated it at greater length.

### An enum case with a surviving second line

```swift
// Before
/// The factor is negative, or is not a finite number, so nothing can be multiplied by it.
///
/// A scaled amount writes its value back as text, and a negative, infinite, or
/// not-a-number factor leaves a value writing text no reader reads as an amount. Zero is
/// allowed and negative zero is not, because only the second writes a sign.
case unusableFactor

// After
/// The factor is negative, or is not a finite number.
///
/// Zero is permitted; negative zero is not.
case unusableFactor
```

Here the second line survives, because it tells a caller that zero is safe to pass and negative
zero is not. The case name does not convey that, and a caller who guesses wrong gets an error.
The rest of the old paragraph explained why, which Rule 3 cuts.

## Checking

Run from the repository root. Each command expects no output.

```bash
# Banned vocabulary
find Sources Tests -name '*.swift' | xargs grep -niE '^[[:space:]]*//.*\b(states|asks|owes|of its own|which is what|nobody wrote)\b'

# Non-ASCII in comments, which also catches a literal em-dash
find Sources Tests -name '*.swift' | xargs grep -nE '^[[:space:]]*//' | LC_ALL=C grep '[^ -~]'

# Double hyphen standing in for an em-dash
find Sources Tests -name '*.swift' | xargs grep -nE '^[[:space:]]*//.*[^-]-{2}[^-]'
```

Coverage and line length are enforced by SwiftLint:

```bash
swiftlint lint Sources Tests
```
