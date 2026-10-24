# Eighth Edition census

The Eighth Edition (8ED) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-24 from MTGJSON's set list against `data/cards/`.
Re-derive the missing list by writing the set list as a deck (`1 Name` per
line) and running `pawl deck` on it: every unresolved name is reported.

## Expressible today

These need no new capability, but `pawl translate` does not translate them yet.
Each names the mtgish node the translator stops at, or what its rendering gets
wrong. No missing Eighth Edition card's whole text is keywords, so
`script/ingest` adds none of them.

- Avatar of Hope: `Rule:CastEffect`
- Blinding Angel: `Action:SkipNextCombatPhase`
- Bribery: `Action:SearchPlayersLibrary`
- Choke: `PermanentRule:DoesntUntapDuringControllersUntap`
- Cinder Wall: `Action:CreateFutureTrigger`
- Coastal Piracy: `Trigger:WhenACreatureDealsCombatDamageToAPlayer`
- Cowardice: `Trigger:WhenAPermanentBecomesTheTargetOfASpellOrAbility`
- Death Pit Offering: `Action:SacrificeEachPermanent`
- Deathgazer: `Action:CreateFutureTrigger`
- Defense Grid: `Players:Other`
- Dehydration: `PermanentRule:DoesntUntapDuringControllersUntap`
- Elvish Pioneer: `Action:PutACardFromHandOnBattlefield`
- Emperor Crocodile: `Trigger:WhenAPlayerControlsNoPermanents`
- Enrage: `LayerEffect:AdjustPTX`
- Fecundity: `Action:PlayerMayAction`
- Fertile Ground: `Trigger:WhenAPermanentIsTappedForMana`
- Fungusaur: `Trigger:WhenAPermanentIsDealtDamage`
- Gaea's Herald: `Rule:StackSpellsEffect`
- Grave Pact: `Players:Other`
- Guerrilla Tactics: `Rule:FromAnyZone`
- Holy Day: `Action:CreatePreventDamageUntil`
- Hunted Wumpus: `Action:EachPlayerMayAction`
- Index: `Action:LookAtTheTopNumberCardsOfLibrary`
- Intruder Alarm: `PermanentRule:DoesntUntapDuringControllersUntap`
- Invisibility: `PermanentRule:CantBeBlockedExceptByDefenders`
- Karma: `Player:Trigger_ThatPlayer`
- Lesser Gargadon: `Action:SacrificeAPermanent`
- Lhurgoyf: `CardsInGraveyards:IsCardtype`
- Living Terrain: `StaticLayerEffect:SetPT`
- Llanowar Behemoth: `Cost:TapAPermanent`
- Mind Slash: `Action:RevealHandAndPlayerChoosesACardToDiscard`
- Mind Sludge: renders as nothing
- Natural Affinity: `LayerEffect:SetPT`
- Nekrataal: renders "It can't be regenerated" where Oracle says "That creature can't be regenerated"
- Obliterate: `Rule:FromStack`
- Orcish Spy: `Action:LookAtTheTopNumberCardsOfPlayersLibrary`
- Panic Attack: `Action:CreateEachPermanentRuleEffectUntil`
- Plague Wind: `Players:Other`
- Plow Under: `Action:PutEachPermanentOnTheTopOfOwnersLibraryInOrderOfOwnersChoice`
- Puppeteer: `Action:TapOrUntapPermanent`
- Redeem: `Action:CreatePreventDamageUntil`
- Rukh Egg: `Action:CreateFutureTrigger`
- Spiketail Hatchling: `Action:PlayerMayCost`
- Spreading Algae: `Trigger:WhenAPermanentBecomesTapped`
- Story Circle: `ReplacementActionWouldEnter:ChooseAColor`
- Tidal Kraken: `PermanentRule:CantBeBlocked`
- Trade Routes: `Cost:DiscardACardOfType`
- Two-Headed Dragon: `PermanentRule:CanBlockAnAdditionalCreature`
- Underworld Dreams: `Trigger:WhenAPlayerDrawsACard`
- Urza's Armor: `Rule:PreventDamage`
- Urza's Mine: `Action:IfElse`
- Urza's Power Plant: `Action:IfElse`
- Urza's Tower: `Action:IfElse`
- Vexing Arcanix: `Action:PlayerActions`
- Wrath of Marit Lage: `PermanentRule:DoesntUntapDuringControllersUntap`
- Zombify: `Action:PutGraveyardCardOntoBattlefield`

## Needs a capability

Each group is tracked by its issue; its cards are added when it lands. Hardest
first.

- #4844: Thieves' Auction. A card can enter only under its owner's or the
  effect controller's control, and each player here takes a card someone else
  may own, inside a repeated round of choices.
- #5549: Death Pits of Rath, Noble Purpose, Curiosity. Damage triggers watch
  only their own bearer, and the enchanted-creature one can't say whom it
  damaged; the fix is a parameter across several trigger arms that read
  different things.
- #4853: Star Compass. No mana production reads the colours another permanent
  could produce (CR 106.7), which mana-ability enumeration has to answer.
- #5550: Shifting Sky, Distorting Lens. The chosen colour can be added but not
  set, and a colour chosen on resolution isn't locked into the stored effect.
