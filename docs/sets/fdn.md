# Foundations census

The Foundations (FDN) cards not yet in the pool, and which wait on a capability.
Derived 2026-11-02 from MTGJSON's set list against `data/cards/`. Re-derive the
missing list by writing the set list as a deck (`1 Name` per line) and running
`parun deck` on it: every unresolved name is reported.

## Expressible today

Every expressible Foundations card has been added to `data/cards/`.

## Needs a capability

Each card is tracked by its issue and is added when that issue lands. Hardest
first.

- #5916: Goblin Negotiation. No quantity reads the excess damage an effect just
  dealt (CR 120.10).
- #5921: Cat Collector; Vanguard Seraph. A life-gain trigger has no "first time
  each turn", where a life-loss trigger does.
- #5926: Exemplar of Light. A counters trigger can't say who put the counters (CR
  122.6).
- #5923: Divine Resilience. A kicked spell can't take a different number of targets
  (CR 601.2c).
- #5924: Deadly Brew. Nothing excludes the card a sacrificed permanent became (CR
  400.7).
- #5636: Fiery Annihilation. A target slot can't be narrowed to what's attached to
  another target of the spell: no filter reads the sibling slot as a host.
- #5929: Fiendish Panda. A dies trigger's "another target card" can't exclude the
  card the source became, so a copy could return itself (CR 400.7).
- #5917: Run Away Together. A target slot judges each object alone, with no
  relation among its targets (CR 115.1).
- #5918: Courageous Goblin; Ruby, Daring Tracker. An intervening "if" checks
  again on resolution, where "attacks while" checks only at the event (CR
  603.4).
