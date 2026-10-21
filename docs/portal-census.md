# Portal census

The Portal (POR) cards not yet in the pool, for #5182 unit 6: which can be
written today, from which template, and which wait on a capability. Derived
2026-10-17 from MTGJSON's set list against `data/cards/`. Re-derive the missing
list by writing the set list as a deck (`1 Name` per line) and running `pawl
deck` on it: every unresolved name is reported.

## Expressible today

Every expressible Portal card has been added to `data/cards/`.

## Needs a capability

Each group is tracked by its issue; its cards are added when it lands.

### A per-player "may draw up to N" with a per-player follow-up (#5239)
ChooseNumber has no chooser, and Repeat/ForEach/ForEachNumber don't loop over
players with each one choosing.
- Temporary Truce: "Each player may draw up to two cards. For each card less than two a player draws this way, that player gains 2 life."

### "That many" after cards are shuffled away (#5240)
ShuffleIntoLibrary has no slot for the moved cards (fields `library`, `refs`),
and a Count read after the shuffle sees an empty hand. timetwister draws a
literal 7, and flux binds `discarded`, which a shuffle can't.
- Winds of Change: "Each player shuffles the cards from their hand into their library, then draws that many cards."

### A spell's rules-modifying effect over a live set of objects (CR 611.2c second sentence) (#5241)
The resolution-created carriers take an ObjectRef, which freezes the set when
the spell resolves. CR 611.2c says an effect that doesn't modify
characteristics can affect objects that arrive later. RequireAttack has a
RestrictedCreatures.Matching arm for this; RequireBlock and DoesNotUntapNext
don't (every pool use of DoesNotUntapNext is InSlot).
- Alluring Scent: "All creatures able to block target creature this turn do so." RequireBlock (lineprancers) needs a Matching blocker side. BlockRequirement's haddock already names Alluring Scent as the "Nothing subject" shape, but that is the static carrier.
- Exhaustion: "Creatures and lands target opponent controls don't untap during their next untap step." DoesNotUntapNext needs a filter arm (ControlledByBound target, Or(creature, land)). Freezing at resolution misses a permanent that comes under that player's control before their untap step.

### The caster orders another player's library cards (#5243)
ArrangeInLibrary asks the cards' owner (CR 401.4), but "in any order" on a
spell that reorders an opponent's library is the caster's choice (Portent's
ruling). Ponder and Tome of the Infinite only reorder their caster's own.
- Cruel Fate: "Look at the top five cards of target opponent's library. Put one of those cards into that player's graveyard and the rest on top of their library in any order."
