# Unlimited Edition census

The Unlimited Edition (2ED) cards not yet in the pool, and which wait on a capability.
Derived 2026-11-05 from MTGJSON's set list against `data/cards/`. Re-derive the
missing list by writing the set list as a deck (`1 Name` per line) and running
`parun deck` on it: every unresolved name is reported.

## Expressible today

These need no new capability, but `parun translate` does not translate them yet.
Each names the mtgish node the translator stops at.

- Blaze of Glory: `_Rule:CastEffect`. #6070 reads it as writable today.
- Gauntlet of Might: `_Trigger:WhenAPermanentIsTappedForMana`
- Psionic Blast: `_Action:SpellDealsMultipleDamage`
- Time Walk: `_Action:TakeAnExtraTurn`
- Two-Headed Giant of Foriys: `_PermanentRule:CanBlockAnAdditionalCreature`

## Needs a capability

Each card is tracked by its issue and is added when that issue lands. Hardest
first.

- #5464: Camouflage. Nothing replaces declaring blockers with piles assigned to
  attackers at random.
- #5463: Raging River. Nothing labels a player's piles or picks a label per
  attacker.
- #4133: Cyclopean Tomb. Nothing remembers which lands its counters were put
  on after it leaves.
- #6204: Time Vault. A skip can't be optional with a rider; it also needs a
  whole turn skipped (#5746).
- #5005: False Orders. Nothing makes a blocked attacker unblocked or a removed
  creature block again.
- #6371: Forcefield. A next-instance shield can't be confined to combat
  damage or prevent all but 1.

## Out of scope

- Chaos Orb: a dexterity card, out of scope by `docs/design.md` section 6
  (#250).
