# Fifth Edition census

The Fifth Edition (5ED) cards not yet in the pool, and which wait on a capability.
Derived 2026-11-03 from MTGJSON's set list against `data/cards/`. Re-derive the
missing list by writing the set list as a deck (`1 Name` per line) and running
`parun deck` on it: every unresolved name is reported.

## Needs a capability

Each card is tracked by its issue and is added when that issue lands. Hardest
first.

- #5988: Nether Shadow. Nothing reads a card's position in a graveyard (CR
  404.1).
- #5989: Shapeshifter. A permanent can't keep a chosen number, change it later,
  and read it as its power and toughness.
- #5991: Eye for an Eye. A one-shot damage shield prevents or redirects; none
  lets the damage through and copies it (CR 614).
- #5990: Clockwork Beast; Clockwork Steed. A counter effect can't put up to X
  on, capped by a total, as `ChooseNumber.upTo` is fixed.
- #6010: Sacred Boon. A delayed trigger can't read how much damage a shield
  stopped; a rider arming one misplays (CR 615.5, 615.7).
- #6002: Island Sanctuary. No draw replacement offers skipping the draw for an
  effect, or reads "during your draw step" (CR 614.10).
- #6012: Venom. An Aura can't watch its host block or be blocked by a creature
  it filters, naming the other creature.
- #5999: Errantry. Nothing lets a creature attack only with no other attacker
  beside it; `CantAttackAlone` is the opposite direction.
- #5177: Gauntlets of Chaos. No filter reads a shared card type with a sibling
  target.
- #5462: Cloak of Confusion; Orcish Squatters. Nothing makes a creature assign
  no combat damage this turn.
- #5089: Funeral March. An Aura can't trigger when its creature leaves the
  battlefield other than by dying.
- #5208: Mana Flare. No mana ability adds a type the tapped land produced (CR
  106.12a).
- #5216: Ghazbán Ogre. Nothing names the player with the most life.
- #4892: Personal Incarnation. An ability's activator can be its controller or
  any player, not its owner.
- #5686: Panic. No casting restriction spans combat before blockers are
  declared.
- #5992: Serra Bestiary. A prohibition can't name activated abilities with {T}
  in their cost (CR 602.5).
- #5993: Instill Energy. Nothing lifts only the attack half of summoning
  sickness (CR 302.6).
- #5994: Orcish Conscripts. `AloneUnless` asks for one companion, not two (CR
  508.1c, 509.1b).
- #5995: Coral Helm. A discard cost can't be at random (CR 701.9b).
- #5996: Orcish Farmer. A duration measured to a step can't name the target's
  controller (CR 611.2a).
