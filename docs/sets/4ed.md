# Fourth Edition census

The Fourth Edition (4ED) cards not yet in the pool, and which wait on a capability.
Derived 2026-11-04 from MTGJSON's set list against `data/cards/`. Re-derive the
missing list by writing the set list as a deck (`1 Name` per line) and running
`parun deck` on it: every unresolved name is reported.

## Expressible today

These need no new capability, but `parun translate` does not translate them yet.
Each names the mtgish node the translator stops at.

- Energy Tap: `_Action:MustCost`
- Gaea's Liege: `_Permanents:IsntAttacking`
- Goblin Rock Sled: `_Permanents:AttackedDuringLastPlayersTurn`
- Island Fish Jasconius: `_PermanentRule:DoesntUntapDuringControllersUntap`
- Ivory Tower: `_GameNumber:Minus`
- Junún Efreet: `_Action:MayCost`
- Land Tax: `_Players:ControlsMorePermanentThanPlayer`
- Lifelace: `_Actions:Targeted_Modal`
- Mishra's Factory: `_LayerEffect:SetPT`
- Mishra's War Machine: `_Action:MayCost`
- Oasis: `_Action:CreateFuturePreventDamage`
- Osai Vultures: `_Condition:ACreatureOrPlaneswalkerDiedThisTurn`
- Power Leak: `_Action:PayAnyAmountOfMana`
- Psionic Entity: `_Action:PermanentDealsMultipleDamage`
- Purelace: `_Actions:Targeted_Modal`
- Relic Bind: `_Trigger:WhenAPermanentBecomesTapped`
- Scavenging Ghoul: `_GameNumber:NumCreaturesOrPlaneswalkersThatDiedThisTurn`
- Seeker: renders differently
- Simulacrum: `_GameNumber:DamageDealtToPlayerThisTurn`
- Sindbad: `_Action:RevealTheCardDrawnThisWay`
- Spirit Shackle: `_Trigger:WhenAPermanentBecomesTapped`
- Sunken City: `_Action:MayCost`
- Tawnos's Wand: `_Permanents:PowerIs`
- The Rack: `_ReplacementActionWouldEnter:ChooseAPlayer`
- Thoughtlace: `_Actions:Targeted_Modal`
- Uncle Istvan: `_Rule:PreventDamage`
- Visions: `_Action:LookAtTheTopNumberCardsOfPlayersLibrary`
- Volcanic Eruption: `_GameNumber:ValueX`
- Word of Binding: `_GameNumber:ValueX`

## Needs a capability

Each card is tracked by its issue and is added when that issue lands. Hardest
first.

- #6081: Balance. Nothing reads the fewest across players, and keeping an exact
  number and sacrificing or discarding the rest takes only "up to".
- #6082: Tetravus. Separate abilities can't share the tokens one of them made
  (CR 607.2a), across turns and after it leaves.
- #6083: Power Surge. Nothing records a player's untapped lands as the turn
  began, before CR 502.3 untaps them.
- #6084: Nafs Asp. A payment is asked once on resolution (CR 118.12a), not left
  open until a later step.
- #6085: Channel. A mana ability belongs to a permanent; nothing gives a player
  one wherever CR 605.3a offers it.
- #6086: Magnetic Mountain. No payment scales with the permanents chosen at
  resolution; asking per creature plays differently.
- #6087: Aladdin's Lamp. A one-shot draw replacement has no mandatory instruction
  list, nor reads its ability's X.
- #6088: Erosion. A clause's `payGate` names one cost, not a choice of two.
