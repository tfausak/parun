# Magic Origins census

The Magic Origins (ORI) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-29 from MTGJSON's set list against `data/cards/`.
Re-derive the missing list by writing the set list as a deck (`1 Name` per
line) and running `parun deck` on it: every unresolved name is reported.

## Expressible today

Every expressible Magic Origins card has been added to `data/cards/`.

## Needs a capability

Each card is tracked by its issue and is added when that issue lands. Hardest
first.

- #5395: Demonic Pact. Nothing remembers which modes an object has already
  chosen, so "choose one that hasn't been chosen" has no reading.
- #4781: Alhammarret's Archive. No draw replacement can spare the first draw in
  a draw step, and none rewrites a draw as two.
- #5756: Alhammarret, High Arbiter. No as-enters step reveals the opponents'
  hands, and a name choice can't be confined to the cards revealed.
- #5758, #5759: Chandra, Fire of Kaladesh // Chandra, Roaring Flame. Nothing
  totals the damage a source dealt this turn, and a damage instruction can't
  bind the players it damaged.
- #5757: Archangel of Tithes. Attack and block costs carry no condition, so
  "as long as this creature is untapped" can't switch them.
- #5762: Exquisite Firecraft. A card's own "can't be countered" carries no
  condition, so spell mastery can't switch it.
- #5765: Harbinger of the Tides. No cast permission at instant timing carries
  a cost increase, so "as though it had flash if you pay {2} more" has no
  reading.
- #5778: Swift Reckoning. No cast permission at instant timing carries a
  condition, so spell mastery can't grant its own flash.
- #5779: The Great Aurora. No instruction lets each player put any number of
  cards from their hand onto the battlefield together.
- #5764: Hallowed Moonlight. An enters redirect to exile is offered only
  against a zone change, so a creature token that wasn't cast still enters.
- #4735: Jace, Vryn's Prodigy // Jace, Telepath Unbound. No permission lets
  one targeted card be cast from a graveyard, so the −3 has no reading.
- #5768: Mizzium Meddler. Nothing changes one target of a spell or ability to
  a named object, and no slot targets a spell or ability (#4564).
- #5771: Psychic Rebuttal. A counter binds only how many it countered, so
  "copy the spell countered this way" names no spell to copy.
- #5770: Nissa's Revelation. No quantity reads a revealed library card's power
  and toughness, nor its last known toughness once it is drawn.
- #5776: Sphinx's Tutelage. No count reads the most members sharing a color,
  so "two nonland cards that share a color" has no reading.
- #5775: Somberwald Alpha. "Becomes blocked" fires only for its source, so "a
  creature you control becomes blocked" has no reading.
- #5754: Tainted Remedy. `LifeGainRewrite` cannot turn a gain into a loss of
  that much life.
