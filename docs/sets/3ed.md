# Revised Edition census

The Revised Edition (3ED) cards not yet in the pool, and which wait on a capability.
Derived 2026-11-05 from MTGJSON's set list against `data/cards/`. Re-derive the
missing list by writing the set list as a deck (`1 Name` per line) and running
`parun deck` on it: every unresolved name is reported.

## Expressible today

Every expressible Revised Edition card has been added to `data/cards/`.

## Needs a capability

Each card is tracked by its issue and is added when that issue lands. Hardest
first.

- #6277: Jandor's Ring. No discard cost can name the last card drawn this turn.
- #6278: Reverse Polarity. Damage dealt to a player this turn can't be summed by
  what dealt it.
- #5067: Fastbond. Nothing reads how many lands a player has played this turn.
