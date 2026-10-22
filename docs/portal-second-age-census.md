# Portal Second Age census

The Portal Second Age (P02) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-21 from MTGJSON's set list against `data/cards/`.
Re-derive the missing list by writing the set list as a deck (`1 Name` per
line) and running `pawl deck` on it: every unresolved name is reported.

## Expressible today

Every expressible Portal Second Age card has been added to `data/cards/`.

## Needs a capability

Each group is tracked by its issue; its cards are added when it lands.

- #5437: Lone Wolf and Deathcoil Wurm (assign combat damage as though it
  weren't blocked), Cunning Giant (an unblocked creature assigns its damage to
  a creature).
- #5438: Piracy (tap lands you don't control for mana).
- #5413: Goblin War Cry ("other creatures they control can't block", leaving
  out a chosen creature).

## Decks

MTGJSON lists nine P02 decks, all in `data/decks/` as
`portal-second-age-*.txt`: both demo decks, both preconstructed starter decks,
and the Goblin Fire, Martial Law, Nature's Assault, Spellweaver and The
Nightstalkers theme decks.
