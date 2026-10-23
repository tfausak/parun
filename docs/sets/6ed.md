# Sixth Edition census

The Sixth Edition (6ED) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-23 from MTGJSON's set list against `data/cards/`.
Re-derive the missing list by writing the set list as a deck (`1 Name` per
line) and running `pawl deck` on it: every unresolved name is reported.

## Expressible today

Every expressible Sixth Edition card has been added to `data/cards/`.

## Needs a capability

Each group is tracked by its issue; its cards are added when it lands. Hardest
first.

- #5496: Syphon Soul. The amount of damage an instruction dealt; "each other
  player" is also related to #5404.
- #5499: Dense Foliage. A targeting restriction for spells only, from any
  player.
- #5524: Derelor. A cost increase of coloured mana.

## Decks

MTGJSON lists two 6ED decks, the preconstructed Deck A and Deck B. Neither is in
`data/decks/` yet, though every card of both is in the pool.
