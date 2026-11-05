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

- #5067: Fastbond. Nothing reads how many lands a player has played this turn.
