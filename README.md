# SousKit

A Swift package for Sous, a plain text format for recipes.

[![CI](https://github.com/jochenbernard/souskit/actions/workflows/ci.yml/badge.svg)](https://github.com/jochenbernard/souskit/actions/workflows/ci.yml)

Sous writes a recipe the way a cook reads one: a metadata header, then steps as prose, with the
ingredients, cookware, timers, and intermediates marked inline. SousKit parses that text into
value types, writes them back, validates them, and scales them.

SousKit is pre-1.0. Both the format and the API may change between minor versions.

## Requirements

| | |
|---|---|
| Swift | 6.3 |
| Platforms | iOS 15, macCatalyst 15, macOS 12, tvOS 15, visionOS 1, watchOS 8 |

## Installation

Add the package to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/jochenbernard/souskit", from: "0.4.0")
]
```

Then add the product to a target:

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "SousKit", package: "souskit")
    ]
)
```

## The format

A recipe is a metadata header between `---` fences, followed by steps written as paragraphs. A
blank line separates one step from the next.

```
---
title: Crepes
servings: 4
yield: [12 crepes]
prep-time: 10 min
cook-time: 25 min
tags: [dessert, classic, french]
allergens: [gluten, dairy, eggs]
---

Whisk @{200 g} flour@ into a batter with @{4} eggs@, @{500 ml} milk@,
@{50 g} melted butter@, and @{1/2 tsp} salt@:staple, then rest it ~1 h~.

Wipe a #crepe pan# with @{10 g} butter@ over medium heat, ladle in a thin layer,
and cook each crepe for ~1 min~ a side until lacy and gold.
```

### Annotations

Four sigils mark a span inside a step. A sigil followed by whitespace opens no span, so prose
such as `Bake @ 180C` reads as written.

| Written | Read as |
|---------|---------|
| `@parsley@` | An ingredient with no amount |
| `@{200 g} flour@` | An ingredient with an amount |
| `#crepe pan#` | Cookware |
| `~1 min~`, `~8-10 min~`, `~1 h 30 min~`, `~overnight~` | A timer |
| `>pastry>` | A reference to the group named `Pastry` |
| `>{400 g} bechamel>` | A reference consuming an amount |

An amount sits in braces at the head of the span. `{200 g}` holds one quantity, `{1-2 tbsp}` a
range, and `{1 1/2 tbsp}` a mixed fraction. Text opening with no usable number, such as
`{a pinch}`, is imprecise and never moves under scaling. A leading `=`, as in `{=10 g}`, holds
the amount constant when the recipe is scaled.

A timer is read as its components. With one component it takes that component's form, so
`~1 min~` is precise, `~8-10 min~` is a range, and `~overnight~` is qualitative. More than one
component makes it compound, whatever the parts hold, so `~1 h 30 min~` and `~1 h 20-30 min~` are
both compound.

### Flags

Ingredients and references take flags after the closing sigil, and flags chain, as in
`@thyme@?:staple`.

| Written | Read as |
|---------|---------|
| `@cream@?` | Optional, in the `?` shorthand |
| `@cayenne@:optional` | Optional, written in full |
| `@salt@:staple` | A staple, assumed to be on hand |
| `@foil@:non-food` | Not something eaten |

An unrecognized flag is preserved rather than dropped, so a file using a flag from a later
version still writes back unchanged.

### Groups

A `## Name` heading opens a group, and a reference consumes what another group produces. Steps
written before any heading belong to a group whose name is `nil`.

```
## Pastry
Rub @{125 g} butter@ into @{250 g} flour@ with @{1/2 tsp} salt@:staple in a
#mixing bowl# until it looks like breadcrumbs, bind it with @{3 tbsp} water@, and
rest the dough in the fridge for ~30 min~.

## Filling
Fry @{200 g} lardons@ in a #frying pan# over medium heat for ~5-6 min~ until the
fat runs, drain them, and stir them through @{4} eggs@ beaten with
@{300 ml} cream@, @{1/4 tsp} nutmeg@, and @black pepper@:staple.

## Assemble
Roll the >pastry> out and line a 24 cm #tart tin#. Cover it with @parchment@:non-food,
fill it with @{500 g} baking beans@:non-food, and bake it blind at 190C for ~15 min~.
Lift them out, pour in the >filling>, scatter over @{50 g} gruyere@?, and bake at
180C for ~35 min~ until just set.
```

### Header fields

`title`, `language`, `version`, and `source` are read as text, `servings` as a number, and
`yield` and `tags` as lists. Every other key is kept as written and reachable by subscript.

### Escapes

A backslash escapes the character after it, so `Wait \~40 min here.` writes a tilde that opens
no timer.

## Reading a recipe

```swift
import SousKit

let parser = SousParser()
let parsed = parser.parseRecipe(source)
let recipe = parsed.value

recipe.metadata.title            // "Crepes"
recipe.metadata.servings         // 4
recipe.metadata.yields           // one amount, "12 crepes"
recipe.metadata.tags             // ["dessert", "classic", "french"]
recipe.metadata["prep-time"]     // "10 min"

recipe.steps.count               // 2
recipe.ingredients.map(\.name)   // ["flour", "eggs", "milk", "melted butter", "salt", "butter"]
recipe.cookware.map(\.name)      // ["crepe pan"]
recipe.timers.map(\.text)        // ["1 h", "1 min"]
```

`ingredients`, `cookware`, `timers`, and `references` roll up in document order, and each is
available on a `Step` and a `StepGroup` as well as on the whole `Recipe`. A `Step` also holds its
`segments`, which carry the prose between the annotations.

Every model type is a value type, `Equatable`, `Hashable`, and `Sendable`.

## Groups and references

```swift
let quiche = parser.parseRecipe(quicheSource).value

if let assemble = quiche.group(named: "assemble") {
    quiche.dependencies(of: assemble).compactMap(\.name)   // ["Pastry", "Filling"]
}
```

Group names are matched normalized, so case, accents, and surrounding whitespace do not affect
the result. `Normalization.normalized(_:)` reduces a name to that form.

## Diagnostics

Parsing always succeeds. A malformed construct is recovered as literal text and reported, so a
recipe is always returned.

```swift
for diagnostic in parsed.diagnostics {
    print(diagnostic.severity, diagnostic.kind, diagnostic.message)

    if let range = diagnostic.range {
        print(range.start.line, range.start.column)
    }
}
```

An `.error` covers the whole recipe, so what parsed is not what the file describes. A `.warning`
covers one construct, which is preserved, and the rest reads as written.

## Validation

```swift
let problems = recipe.validate()
```

Validation applies five rules: the header declares each unit's yield at most once, counting
`servings` and every `yield` item together; it declares no yield of zero; no two group headings
share a name; every reference matches a group; and no group consumes an intermediate that depends
on it.

Its diagnostics carry no `range`, because validation reads a parsed recipe rather than source
text.

## Scaling

```swift
let doubled = try recipe.scaled(by: 2)
let forSix = try recipe.scaled(toServings: 6)
let eighteen = try recipe.scaled(to: parser.parseAmount("18 crepes"))
```

Scaling to servings divides by the declared `servings`, and scaling to an amount divides by the
declared `yield` of the same unit. Units are matched as written, with no conversion between
spellings. Fixed and imprecise amounts hold still, and so do timers. Of the header, only
`servings` and `yield` move. A request that cannot be met throws a `ScalingError`.

## Writing back

```swift
let text = recipe.serialized()
```

Content is preserved and incidental layout such as repeated blank lines is normalized, so
re-reading the result yields the same recipe.

## Modules

| Module | Contents |
|--------|----------|
| `SousCore` | The model, the parser, and everything acting on them |
| `SousKit` | The layer built on `SousCore` |

Import `SousKit`. It re-exports `SousCore`, so every symbol above is reachable through it.
`SousKit` holds no symbols yet, and is where the higher-level API will land.

## Documentation

The API reference is at
[jochenbernard.github.io/souskit](https://jochenbernard.github.io/souskit/documentation/).

## License

MIT. See [LICENSE](LICENSE).
