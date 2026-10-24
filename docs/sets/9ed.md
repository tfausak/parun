# Ninth Edition census

The Ninth Edition (9ED) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-24 from MTGJSON's set list against `data/cards/`.
Re-derive the missing list by writing the set list as a deck (`1 Name` per
line) and running `parun deck` on it: every unresolved name is reported.

## Expressible today

Every expressible Ninth Edition card has been added to `data/cards/`.

## Needs a capability

Each card is tracked by its issue and is added when that issue lands. Hardest
first.

- #5561: Seedborn Muse. The untap step untaps only the active player's
  permanents, and every untap restriction's "its controller's untap step" has
  to stop holding in someone else's.
- #5562: Storage Matrix. Untap restrictions can't let the player pick a card
  type first; it needs a new hold, plus a prompt in the untap step.
- #5565: Consume Spirit. A spell can't limit which mana pays for its X;
  "Spend only black mana on X" exists only for an activation, over its whole
  cost.
- #5563: Slate of Ancestry. A discard cost discards a fixed number of cards, not
  the whole hand; the fix is a parameter on the count.
