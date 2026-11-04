# Fifth Edition census

The Fifth Edition (5ED) cards not yet in the pool, and which wait on a capability.
Derived 2026-11-03 from MTGJSON's set list against `data/cards/`. Re-derive the
missing list by writing the set list as a deck (`1 Name` per line) and running
`parun deck` on it: every unresolved name is reported.

## Needs a capability

Each card is tracked by its issue and is added when that issue lands. Hardest
first.

- #5216: Ghazbán Ogre. Nothing names the player with the most life.
- #4892: Personal Incarnation. An ability's activator can be its controller or
  any player, not its owner.
- #5686: Panic. No casting restriction spans combat before blockers are
  declared.
- #5992: Serra Bestiary. A prohibition can't name activated abilities with {T}
  in their cost (CR 602.5).
- #5993: Instill Energy. Nothing lifts only the attack half of summoning
  sickness (CR 302.6).
- #5995: Coral Helm. A discard cost can't be at random (CR 701.9b).
- #5996: Orcish Farmer. A duration measured to a step can't name the target's
  controller (CR 611.2a).
