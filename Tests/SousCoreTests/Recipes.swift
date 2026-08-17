/// The recipes the tests draw their example data from.
///
/// Each is a complete, cookable version of a classic French dish that reads back byte for byte.
/// Every ingredient, cookware, group name, and reference target the tests use as vocabulary
/// comes from one of these ten; bare parser placeholders such as `@a@` and `#p#` do not.
enum Recipes {
    /// A braise, with a header, four steps, precise timers, and two staples.
    static let boeufBourguignon = """
    ---
    title: Boeuf Bourguignon
    servings: 6
    prep-time: 30 min
    cook-time: 3 h
    tags: [dinner, classic, french]
    allergens: [gluten, dairy]
    ---

    Cut @{1.2 kg} beef@ into large cubes and pat them dry. Brown @{150 g} lardons@ in a
    #casserole# for ~5 min~ until the fat runs, lift them out, then brown the beef in
    batches in the rendered fat over high heat.

    Return the beef and the lardons, dust them with @{2 tbsp} flour@, and stir over the
    heat for ~3 min~. Add @{3 cloves} garlic@ and @{2 sprigs} thyme@, pour over
    @{750 ml} red wine@ and @{500 ml} beef stock@, and bring it to a simmer.

    Cover the pot and braise at 150C for ~3 h~, until the beef gives to a fork.

    Fry @{250 g} pearl onions@ and @{250 g} button mushrooms@ in @{30 g} butter@ in a
    #frying pan# for ~20 min~ until browned, fold them through, and season with
    @salt@:staple and @black pepper@:staple.
    """

    /// A quick dish, with eight ingredients, an optional one, a staple, and two cookware.
    static let moulesMarinieres = """
    ---
    title: Moules Marinieres
    servings: 2
    prep-time: 20 min
    cook-time: 10 min
    tags: [dinner, quick, french]
    allergens: [molluscs, dairy]
    ---

    Scrub @{2 kg} mussels@ under cold water, pull away the beards, and discard any
    that stay open when tapped.

    Soften @{2} shallots@ and @{2 cloves} garlic@ in @{50 g} butter@ in a #heavy pot#
    for ~3 min~ without browning them.

    Pour in @{300 ml} white wine@, tip in the mussels, cover the pot, and steam them
    over high heat for ~4-5 min~, shaking it once, until they open. Discard any that
    stayed shut.

    Lift them into bowls with a #slotted spoon#, stir @cream@? into the liquor, season
    it with @black pepper@:staple, and pour it over. Scatter with @parsley@.
    """

    /// A tart, with three groups, references between them, and a full header above its body.
    static let quicheLorraine = """
    ---
    title: Quiche Lorraine
    language: en
    version: 1.0
    servings: 6
    prep-time: 30 min
    cook-time: 50 min
    tags: [lunch, classic, french]
    allergens: [gluten, dairy, eggs]
    ---

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
    """

    /// A gratin, with a compound timer and, in its header alone, every field of the form.
    static let gratinDauphinois = """
    ---
    title: Gratin Dauphinois
    language: en
    version: 1.0
    servings: 6
    yield: [1.8 kg]
    tags: [comfort food, french, make-ahead]
    diet: [vegetarian]
    allergens: [dairy]
    source: https://example.com/gratin-dauphinois
    author: Jean Dupont
    license: CC-BY-4.0
    image: images/gratin-dauphinois.jpg
    prep-time: 30 min
    cook-time: 1 h 30 min
    make-ahead: best assembled a day ahead and baked from cold
    nutrition:
      calories: 3300 kcal
      protein: 44 g
    ---

    Rub a #gratin dish# with @{1 clove} garlic@, butter it with @{20 g} butter@, and
    heat the oven to 150C.

    Peel @{1.2 kg} potatoes@ and slice them 3 mm thick on a #mandoline#, then bring
    them to a simmer in @{500 ml} cream@ and @{300 ml} milk@ in a #heavy pot# with
    @salt@:staple, @black pepper@:staple, and @{1/4 tsp} nutmeg@.

    Tip everything into the dish, level the top, and bake for ~1 h 30 min~ until the
    potatoes are tender and the top is deep gold. Rest it ~15 min~ before serving.
    """

    /// A sauce, with a yield, no servings, and neither cookware nor timers.
    static let vinaigrette = """
    ---
    title: Vinaigrette
    yield: [125 ml]
    prep-time: 5 min
    tags: [sauce, classic, french]
    allergens: [mustard]
    ---

    Whisk @{1 tsp} dijon mustard@ into @{2 tbsp} red wine vinegar@ with
    @{1/4 tsp} salt@:staple until the salt dissolves.

    Beat in @{6 tbsp} olive oil@ a little at a time until it thickens, then season
    with @black pepper@:staple.
    """

    /// A stew, with three groups where the last consumes the other two.
    static let bouillabaisse = """
    ---
    title: Bouillabaisse
    servings: 6
    yield: [4.5 l]
    prep-time: 40 min
    cook-time: 50 min
    tags: [dinner, french, provencal]
    allergens: [fish, gluten, eggs]
    ---

    ## Court-Bouillon
    Soften @{2} fennel bulbs@, @{2} onions@, and @{4 cloves} garlic@ in
    @{4 tbsp} olive oil@ in a #stockpot# for ~10 min~. Add @{800 g} tomatoes@,
    @{=1 tsp} saffron@, and @{1 strip} orange zest@, pour in @{2 l} fish stock@, and
    simmer for ~30-35 min~.

    ## Rouille
    Pound @{3 cloves} garlic@ with @{1/2 tsp} salt@:staple and @{1/4 tsp} cayenne@ in
    a #mortar#, work in @{1} egg yolk@, then beat in @{100 ml} olive oil@ drop by
    drop. Thicken it with @{50 g} breadcrumbs@ soaked in a little court-bouillon.

    ## Assemble
    Poach @{1.5 kg} rockfish@ in the >court-bouillon> for ~8-10 min~ until it flakes,
    ladle it into #soup bowls# with a #ladle#, and serve the >rouille> with @croutons@.
    """

    /// A sandwich, consuming an intermediate no group of the file produces.
    ///
    /// The 400 g of bechamel is 40 g butter, 40 g flour, and 350 ml milk cooked out with nutmeg.
    static let croqueMonsieur = """
    ---
    title: Croque Monsieur
    servings: 4
    prep-time: 15 min
    cook-time: 15 min
    tags: [french, lunch, classic]
    allergens: [gluten, dairy]
    ---

    Butter @{8 slices} pain de mie@ with @{40 g} butter@ and toast them in a
    #frying pan# for ~2-3 min~ a side, then set them aside.

    Spread four slices with half of >{400 g} bechamel>, layer on @{200 g} ham@ and
    half of @{200 g} gruyere@, and close each one with a second slice.

    Sit them in a #baking dish#, spread the rest of the bechamel over the tops,
    scatter on the rest of the gruyere, and grill for ~5-8 min~ until bubbling.
    """

    /// A dough, with a qualitative timer, a precise one in days, and two ranges.
    static let brioche = """
    ---
    title: Brioche
    servings: 10
    yield: [1 loaf]
    prep-time: 40 min
    cook-time: 55 min
    tags: [baking, classic, french]
    allergens: [gluten, dairy, eggs]
    ---

    Mix @{500 g} flour@, @{60 g} caster sugar@, @{10 g} salt@:staple, and
    @{=10 g} yeast@ in a #mixing bowl#, add @{6} eggs@ and @{60 ml} milk@, and work
    the dough until it pulls away clean.

    Beat @{250 g} butter@ in a piece at a time, then bring the dough together and
    refrigerate it ~overnight~ (or up to ~2 days~).

    The next day, shape it into a #loaf tin# buttered with @{10 g} butter@, prove it
    until puffy, about ~2-3 h~, then bake at 180C for ~45-55 min~, tenting it with
    @foil@:non-food once it is deep brown, until it sounds hollow underneath.
    """

    /// A batter, with a countable yield alongside a number of servings.
    static let crepes = """
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
    """

    /// A bake, with a countable yield, a precise timer, and a range timer.
    static let madeleines = """
    ---
    title: Madeleines
    servings: 6
    yield: [12 madeleines]
    prep-time: 15 min
    cook-time: 10 min
    tags: [baking, classic, french]
    allergens: [gluten, dairy, eggs]
    ---

    Whisk @{2} eggs@ with @{100 g} caster sugar@ until pale, then fold in
    @{100 g} flour@ sifted with @{1 tsp} baking powder@ and the zest of @{1} lemon@.

    Fold in @{100 g} melted butter@, chill the batter ~1 h~, then spoon it into a
    #madeleine tin# buttered with @{10 g} butter@ and bake at 200C for ~8-10 min~.
    """
}
