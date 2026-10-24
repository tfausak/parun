# Eighth Edition census

The Eighth Edition (8ED) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-24 from MTGJSON's set list against `data/cards/`.
Re-derive the missing list by writing the set list as a deck (`1 Name` per
line) and running `pawl deck` on it: every unresolved name is reported.

## Expressible today

Every expressible Eighth Edition card has been added to `data/cards/`.

## Needs a capability

Each group is tracked by its issue; its cards are added when it lands. Hardest
first.

- #5549: Death Pits of Rath, Noble Purpose, Curiosity. Damage triggers watch
  only their own bearer, and the enchanted-creature one can't say whom it
  damaged; the fix is a parameter across several trigger arms that read
  different things.
- #4853: Star Compass. No mana production reads the colours another permanent
  could produce (CR 106.7), which mana-ability enumeration has to answer.
- #5550: Shifting Sky, Distorting Lens. The chosen colour can be added but not
  set, and a colour chosen on resolution isn't locked into the stored effect.
