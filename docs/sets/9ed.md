# Ninth Edition census

The Ninth Edition (9ED) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-24 from MTGJSON's set list against `data/cards/`.
Re-derive the missing list by writing the set list as a deck (`1 Name` per
line) and running `parun deck` on it: every unresolved name is reported.

## Expressible today

These need no new capability, but `parun translate` does not translate them yet.
Each names the mtgish node the translator stops at, or what its rendering gets
wrong. No missing Ninth Edition card's whole text is keywords, so
`script/ingest` adds none of them.

- Annex: `StaticLayerEffect:SetController`
- Aven Windreader: `Action:RevealTopCardOfLibrary`
- Ballista Squad: `Cost:PayManaX`
- Battle of Wits: `Players:NumCardsInLibraryIs`
- Blackmail: `Action:RevealNumberCardsFromHand`
- Consume Spirit: `Rule:CastEffect`
- Contaminated Bond: `Trigger:Or`
- Crafty Pathmage: `Permanents:PowerIs`
- Dream Prowler: `Rule:If`
- Elvish Bard: `PermanentRule:AllCreaturesMustBlockIt`
- Final Punishment: `GameNumber:DamageDealtToPlayerThisTurn`
- Flame Wave: `Permanents:ControlledByPlayer`
- Flowstone Slide: `LayerEffect:AdjustPTX`
- Force of Nature: `Action:MayCost`
- Form of the Dragon: `Action:SetLifeTotal`
- Goblin Brigand: `PermanentRule:MustAttack`
- Greater Good: `GameNumber:PowerOfTheSacrificedCreature`
- Hell's Caretaker: `Action:PutGraveyardCardOntoBattlefield`
- Hypnotic Specter: `Action:DiscardACardAtRandom`
- Imaginary Pet: renders as nothing
- Inspirit: renders "it gets an additional +2/+4" where Oracle says "It gets +2/+4"
- Jester's Cap: `Action:SearchPlayersLibrary`
- Magnivore: `CardsInGraveyards:IsCardtype`
- Marble Titan: `Permanents:PowerIs`
- Mindslicer: `Action:DiscardHand`
- Mortivore: `CardsInGraveyards:IsCardtype`
- Overgrowth: `Trigger:WhenAPermanentIsTappedForMana`
- Peace of Mind: `Cost:DiscardACard`
- Rathi Dragon: `Action:MayCost`
- Reminisce: `Action:ShuffleGraveyardIntoLibrary`
- Rogue Kavu: `Trigger:WhenACreatureAttacksAlone`
- Sage Aven: `Action:LookAtTheTopNumberCardsOfLibrary`
- Sanctum Guardian: `Action:ChooseADamageSource`
- Sea's Claim: `StaticLayerEffect:SetLandType`
- Sengir Vampire: `Permanents:WasDealtDamageByPermanentThisTurn`
- Shard Phoenix: `Rule:FromGraveyard`
- Silklash Spider: `Cost:PayManaX`
- Thran Golem: `Rule:If`
- Threaten: `Action:GainControlOfPermanentUntil`
- Traumatize: `GameNumber:HalfRoundedDown`
- Treetop Bracers: `PermanentRule:CantBeBlockedExceptByDefenders`
- Wanderguard Sentry: `Action:LookAtPlayersHand`
- Weathered Wayfarer: `Condition:APlayerPassesFilter`
- Weird Harvest: `Action:EachPlayerMayAction`
- Yawgmoth Demon: `Condition:CostWasntPaid`
- Zealous Inquisitor: `Action:CreateFutureReplaceWouldDealDamage`

## Needs a capability

Each card is tracked by its issue and is added when that issue lands. Hardest
first.

- #5560: Booby Trap. The reveal covers only a player's first draw each turn and
  can't be put on a chosen player, and a draw trigger can't read which card was
  drawn.
- #5561: Seedborn Muse. The untap step untaps only the active player's
  permanents, and every untap restriction's "its controller's untap step" has
  to stop holding in someone else's.
- #5562: Storage Matrix. Untap restrictions can't let the player pick a card
  type first; it needs a new hold, plus a prompt in the untap step.
- #5563: Slate of Ancestry. A discard cost discards a fixed number of cards, not
  the whole hand; the fix is a parameter on the count.
