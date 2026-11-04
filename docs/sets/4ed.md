# Fourth Edition census

The Fourth Edition (4ED) cards not yet in the pool, and which wait on a capability.
Derived 2026-11-04 from MTGJSON's set list against `data/cards/`. Re-derive the
missing list by writing the set list as a deck (`1 Name` per line) and running
`parun deck` on it: every unresolved name is reported.

## Expressible today

Every expressible Fourth Edition card has been added to `data/cards/`.

## Needs a capability

Each card is tracked by its issue and is added when that issue lands. Hardest
first.

- #6083: Power Surge. Nothing records a player's untapped lands as the turn
  began, before CR 502.3 untaps them.
- #6084: Nafs Asp. A payment is asked once on resolution (CR 118.12a), not left
  open until a later step.
- #6085: Channel. A mana ability belongs to a permanent; nothing gives a player
  one wherever CR 605.3a offers it.
- #6086: Magnetic Mountain. No payment scales with the permanents chosen at
  resolution; asking per creature plays differently.
- #6128: Power Leak. A shield can stand only for the turn, not one instruction's
  "prevent X of that damage".
- #6087: Aladdin's Lamp. A one-shot draw replacement has no mandatory instruction
  list, nor reads its ability's X.
- #6088: Erosion. A clause's `payGate` names one cost, not a choice of two.
