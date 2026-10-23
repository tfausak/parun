# Seventh Edition census

The Seventh Edition (7ED) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-23 from MTGJSON's set list against `data/cards/`.
Re-derive the missing list by writing the set list as a deck (`1 Name` per
line) and running `pawl deck` on it: every unresolved name is reported.

## Expressible today

Every expressible Seventh Edition card has been added to `data/cards/`.

## Needs a capability

Each group is tracked by its issue; its cards are added when it lands. Hardest
first.

- #5530: Sacred Ground. Zone moves record no cause, so nothing can tell an
  opponent's spell or ability from a state-based action or your own cost.
- #5531: Static Orb. A cap on how many permanents untap is a new choice inside
  the untap step's turn-based action.
- #5532: Okk. Attacking or blocking needs a stronger creature beside it, a
  restriction read off the whole declaration; blocking has no "alone" arm yet.
- #5087: Ensnaring Bridge. A filter can't compare power with a computed count.
- #5174: Disorder. No "each player who controls" player scope.
- #5533: Mana Clash. A coin can be flipped only by the spell's controller.
- #5534: Phyrexian Colossus. Menace fixes the blocker minimum at two.
- #5535: Coat of Arms. No filter compares a creature's types with the creature
  being pumped.
- #5536: Persecute. No color can be chosen as a spell resolves.
- #5537: Gang of Elk. Only blockers beyond the first can be counted.
