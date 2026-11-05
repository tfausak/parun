# Revised Edition census

The Revised Edition (3ED) cards not yet in the pool, and which wait on a capability.
Derived 2026-11-05 from MTGJSON's set list against `data/cards/`. Re-derive the
missing list by writing the set list as a deck (`1 Name` per line) and running
`parun deck` on it: every unresolved name is reported.

## Expressible today

These need no new capability, but `parun translate` does not translate them yet.
Each names the mtgish node the translator stops at.

- Basalt Monolith: `_PermanentRule:DoesntUntapDuringControllersUntap`
- Copy Artifact: `_ReplacementActionWouldEnter:MayActions`
- Demonic Hordes: `_Action:SacrificeAPermanentOfAPlayersChoice`
- Earthbind: `_Permanent:HostPermanent`
- Farmstead: `_Rule:TriggerA`
- Fork: `_Action:CopySpellAndMayChooseNewTargetsWithEffects`
- Kudzu: `_Trigger:WhenAPermanentBecomesTapped`
- Mijae Djinn: `_Action:FlipACoin_OnLose`
- Resurrection: `_Action:PutGraveyardCardOntoBattlefield`
- Rocket Launcher: `_Action:CreateFutureTrigger`
- Sacrifice: `_Rule:CastEffect`
- Veteran Bodyguard: `_Rule:ReplaceWouldDealDamage`
- Wheel of Fortune: `_Action:DiscardHand`

## Needs a capability

Each card is tracked by its issue and is added when that issue lands. Hardest
first.

- #6275: Guardian Angel. Nothing lets a resolved spell leave its caster an
  action to take later that turn.
- #6276: Rock Hydra. A counter removed for each 1 damage, even damage that can't
  be prevented, is more than a prevention's rider reads.
- #6277: Jandor's Ring. No discard cost can name the last card drawn this turn.
- #6278: Reverse Polarity. Damage dealt to a player this turn can't be summed by
  what dealt it.
- #5067: Fastbond. Nothing reads how many lands a player has played this turn.
