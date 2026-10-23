# Seventh Edition census

The Seventh Edition (7ED) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-23 from MTGJSON's set list against `data/cards/`.
Re-derive the missing list by writing the set list as a deck (`1 Name` per
line) and running `pawl deck` on it: every unresolved name is reported.

## Expressible today

These need no new capability, but `pawl translate` does not translate them yet.
Each names the mtgish node the translator stops at, or what its rendering gets
wrong. No missing Seventh Edition card's whole text is keywords, so
`script/ingest` adds none of them.

- Arcane Laboratory: `PlayerEffect:CantCastMoreThanNumberSpellsEachTurn`
- Befoul: renders as nothing
- Bellowing Fiend: `Trigger:WhenAPermanentDealsDamageToAPermanent`
- Bereavement: `Player:ControllerOfDeadPermanent`
- Blanchwood Armor: `StaticLayerEffect:AdjustPTForEach`
- Bloodshot Cyclops: `GameNumber:PowerOfTheSacrificedCreature`
- Caltrops: `Trigger:WhenACreatureAttacks`
- Compost: `Trigger:WhenACardIsPutIntoAPlayersGraveyardFromAnywhere`
- Corrupt: `GameNumber:TheAmountOfDamageDealtThisWay`
- Crypt Rats: `Cost:PayManaX`
- Darkest Hour: `StaticLayerEffect:SetColor`
- Delusions of Mediocrity: `Trigger:WhenAPermanentLeavesTheBattlefield`
- Dregs of Sorrow: `GameNumber:ValueX`
- Engineered Plague: `ReplacementActionWouldEnter:ChooseACreatureType`
- Force Spike: `Action:PlayerMayCost`
- Grafted Skullcap: `Action:DiscardHand`
- Granite Grip: `StaticLayerEffect:AdjustPTForEach`
- Impatience: `Player:Trigger_ThatPlayer`
- Intrepid Hero: `Permanents:PowerIs`
- Mana Breach: `Action:PutAPermanentIntoItsOwnersHand`
- Master Healer: `Action:CreateFuturePreventDamage`
- Nature's Revolt: `StaticLayerEffect:SetPT`
- Opposition: `Cost:TapAPermanent`
- Ostracize: `Action:RevealHandAndPlayerChoosesACardToDiscard`
- Reclaim: `Action:PutGraveyardCardOnTopOfLibrary`
- Reprocess: `Action:SacrificeAnyNumberOfPermanents`
- Rolling Stones: `PermanentRule:CanAttackAsThoughItDidntHaveDefender`
- Sanctimony: `Trigger:WhenAPlayerTapsAPermanentForMana`
- Seismic Assault: `Cost:DiscardACardOfType`
- Spellbook: `Rule:PlayerEffect`
- Steal Artifact: `StaticLayerEffect:SetController`
- Tainted Aether: `Permanent:Trigger_ThatPermanent`
- Telepathic Spies: `Action:LookAtPlayersHand`
- Telepathy: `PlayerEffect:PlaysWithHandRevealed`
- Thoughtleech: `Trigger:WhenAPermanentBecomesTapped`
- Tolarian Winds: `Action:DiscardHand`
- Vernal Bloom: `Trigger:WhenAPermanentIsTappedForMana`
- Wall of Wonder: `Action:CreatePermanentRuleEffectUntil`
- Yavimaya Enchantress: `StaticLayerEffect:AdjustPTForEach`

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
