# Foundations census

The Foundations (FDN) cards not yet in the pool, and which wait on a capability.
Derived 2026-11-02 from MTGJSON's set list against `data/cards/`. Re-derive the
missing list by writing the set list as a deck (`1 Name` per line) and running
`parun deck` on it: every unresolved name is reported.

## Expressible today

These need no new capability, but `parun translate` does not translate them yet.
Each names the mtgish node the translator stops at.

- Battlesong Berserker: `_Trigger:WhenAPlayerAttacks`
- Biogenic Upgrade: `_PutCountersAction:DistributedCounters`
- Bite Down: `_Players:Other`
- Blasphemous Edict: `_Rule:CastEffect`
- Bloodthirsty Conqueror: `_Trigger:WhenAPlayerLosesLife`
- Bloodtithe Collector: `_Players:LostLifeThisTurn`
- Bolt Bend: `_Rule:CastEffect`
- Boros Charm: `_Permanents:IsPermanent`
- Brass's Bounty: `_CreatableToken:TreasureToken`
- Bulk Up: `_Action:DoubleCreaturesPowerUntilEndOfTurn`
- Burnished Hart: `_SearchLibraryAction:FindNumberCardsOfType`
- Bushwhack: `_Players:Other`
- Cackling Prowler: `_Rule:Ward`
- Carnelian Orb of Dragonkind: `_Action:AddManaWithModifiers`
- Cat Collector: `_CreatableToken:FoodToken`
- Celestial Armor: `_Action:AttachPermanentToPermanent`
- Cemetery Recruitment: `_Action:If`
- Cephalid Inkmage: `_Action:Surveil`
- Chandra, Flameshaper: `field: Loyalty` (#5711)
- Charming Prince: `_Permanents:OwnedByAPlayer`
- Chart a Course: `_Action:Unless`
- Circuitous Route: `_SearchLibraryAction:FindNumberCardsOfType`
- Claws Out: `_Rule:Affinity`
- Clinquant Skymage: `_Trigger:WhenAPlayerDrawsACard`
- Consuming Aberration: `_Players:Opponent`
- Corsair Captain: `_CreatableToken:TreasureToken`
- Crawling Barrens: `_LayerEffect:SetPT`
- Crow of Dark Tidings: renders differently from its Oracle text
- Crystal Barricade: `_Rule:PlayerEffect`
- Cultivator's Caravan: `_Rule:Crew`
- Deadly Brew: `_Action:SacrificeAPermanent`
- Deadly Plot: `_Action:PutGraveyardCardOntoBattlefield`
- Deadly Riposte: renders differently from its Oracle text
- Demolition Field: `_Player:ControllerOfDestroyedPermanent`
- Desecration Demon: `_Action:AnyPlayerMayCost`
- Divine Resilience: `_Rule:SpellActions_Kicker`
- Dragonlord's Servant: `_Rule:PlayerEffect`
- Drake Hatcher: `_GameNumber:Trigger_AmountOfDamageDealt`
- Dread Summons: `_Action:CreateTokens`
- Dreadwing Scavenger: `_Trigger:Or`
- Driver of the Dead: `_CardsInGraveyards:ManaValueIs`
- Drogskol Reaver: `_Trigger:WhenAPlayerGainsLife`
- Dropkick Bomber: `_Rule:TriggerA`
- Dryad Militant: `_Rule:ReplaceWouldPutIntoGraveyard`
- Eager Trufflesnout: `_CreatableToken:FoodToken`
- Eaten Alive: `_Rule:CastEffect`
- Eaten by Piranhas: `_StaticLayerEffect:LosesAllAbilities`
- Electroduplicate: `_CreatableToken:TokenCopyOfPermanent`
- Elenda, Saint of Dusk: `_Rule:HexproofFrom`
- Elspeth's Smite: `_Action:CreateReplaceWouldPutIntoGraveyardUntil`
- Elvish Regrower: `_CardsInGraveyards:IsPermanent`
- Etali, Primal Storm: `_Action:Exile`
- Exemplar of Light: `_Trigger:WhenAPlayerGainsLife`
- Exsanguinate: `_GameNumber:LifeLostThisWay`
- Extravagant Replication: `_CreatableToken:TokenCopyOfPermanent`
- Faebloom Trick: `_Action:Reflexive_CreateTokens_WhenYouDo`
- Fake Your Own Death: `_Rule:TriggerA`
- Feed the Swarm: `_GameNumber:ManaValueOfPermanent`
- Feldon's Cane: `_Cost:Exile`
- Felidar Retreat: `_Action:CreatePermanentsList`
- Fiendish Panda: `_Trigger:WhenAPlayerGainsLife`
- Fiery Annihilation: `_Permanents:AttachedToPermanent`
- Finale of Revelation: `_Action:IfElse`
- Firespitter Whelp: renders differently from its Oracle text
- Flamewake Phoenix: `_PermanentRule:MustAttack`
- Fleeting Flight: `_Action:CreatePreventDamageUntil`
- Fumigate: `_GameNumber:NumPermanentsDestroyedThisWay`
- Fynn, the Fangbearer: `_Trigger:WhenACreatureDealsCombatDamageToAPlayer`
- Gate Colossus: `_Rule:Affinity`
- Gatekeeper of Malakir: `_Condition:EnteringPermanentPassesFilter`
- Genesis Wave: `_Action:RevealTheTopNumberCardsOfLibrary`
- Ghalta, Primal Hunger: `_Rule:CastEffect`
- Ghitu Lavarunner: `_Players:NumCardsOfTypeInGraveyardIs`
- Giada, Font of Hope: `_Rule:ReplaceWouldEnter`
- Gleaming Barrier: `_CreatableToken:TreasureToken`
- Gnarlid Colony: `_ReplacementActionWouldEnter:IfPassesFilter`
- Goblin Boarders: `_ReplacementActionWouldEnter:If`
- Goldvein Pick: `_Trigger:WhenACreatureDealsCombatDamageToAPlayer`
- Good-Fortune Unicorn: `_Permanent:Trigger_ThatPermanent`
- Gorehorn Raider: `_Players:AttackedThisTurn`
- Grappling Kraken: `_CounterType:StunCounter`
- Gratuitous Violence: `_Rule:ReplaceWouldDealDamage`
- Grow from the Ashes: `_Rule:SpellActions_Kicker`
- Gutless Plunderer: `_Players:AttackedThisTurn`
- Halana and Alena, Partners: renders differently from its Oracle text
- Hare Apparent: `_Permanents:IsNamed`
- Harmless Offering: `_Action:GainControlOfPermanent`
- Herald of Eternal Dawn: `_Rule:PlayerEffect`
- Heraldic Banner: `_ReplacementActionWouldEnter:ChooseAColor`
- Heroes' Bane: `_ReplacementActionWouldEnter:EntersWithNumberCounters`
- Hidetsugu's Second Rite: `_Action:If`
- High Fae Trickster: `_Rule:PlayerEffect`
- Homunculus Horde: `_Trigger:WhenAPlayerDrawsTheirNthCardEachTurn`
- Immersturm Predator: `_Trigger:WhenAPermanentBecomesTapped`
- Imprisoned in the Moon: `_Permanent:HostPermanent`
- Incinerating Blast: `_Cost:DiscardACard`
- Ingenious Leonin: `_Action:If`
- Inspiration from Beyond: `_Action:PutACardFromGraveyardIntoHand`
- Inspiring Call: `_Permanents:HasACounterOfType`
- Inspiring Paladin: `_Permanents:HasACounterOfType`
- Into the Roil: `_Rule:SpellActions_Kicker`
- Involuntary Employment: `_Action:GainControlOfPermanentUntil`
- Jazal Goldmane: `_LayerEffect:AdjustPTX`
- Joust Through: renders differently from its Oracle text
- Kaito, Cunning Infiltrator: `field: Loyalty` (#5711)
- Kalastria Highborn: `_Trigger:Or`
- Kellan, Planar Trailblazer: `_Action:If`
- Kiora, the Rising Tide: `_CreatableToken:NamedTokenWithPT`
- Koma, World-Eater: `_Rule:FromStack`
- Kykar, Zephyr Awakener: `_Action:CreateFutureTrigger`
- Lathril, Blade of the Elves: `_GameNumber:Trigger_AmountOfDamageDealt`
- Leyline Axe: `_Rule:IfCardIsInOpeningHand`
- Lightshell Duo: `_Action:Surveil`
- Linden, the Steadfast Queen: `_Trigger:WhenACreatureAttacks`
- Loot, Exuberant Explorer: `_Rule:PlayerEffect`
- Lunar Insight: `_GameNumber:NumDifferentManaValuesAmongPermanents`
- Maelstrom Pulse: `_Permanents:SinglePermanent`
- Make Your Move: `_Permanents:PowerIs`
- Marauding Blight-Priest: `_Trigger:WhenAPlayerGainsLife`
- Maze's End: `_Cost:PutPermanentIntoItsOwnersHand`
- Micromancer: `_CardsInLibrary:ManaValueIs`
- Midnight Snack: `_Players:AttackedThisTurn`
- Mild-Mannered Librarian: `_Action:CreatePermanentLayerEffect`
- Mischievous Mystic: `_Trigger:WhenAPlayerDrawsTheirNthCardEachTurn`
- Mocking Sprite: `_Rule:PlayerEffect`
- Mossborn Hydra: `_ReplacementActionWouldEnter:EntersWithACounter`
- Myojin of Night's Reach: `_ReplacementActionWouldEnter:If`
- Mystical Teachings: `_CardsInLibrary:HasAbility`
- Needletooth Pack: `_Condition:ACreatureOrPlaneswalkerDiedThisTurn`
- Nessian Hornbeetle: `_Permanents:PowerIs`
- New Horizons: `_Rule:Activated`
- Nine-Lives Familiar: `_ReplacementActionWouldEnter:If`
- Niv-Mizzet, Visionary: `_Rule:PlayerEffect`
- Nullpriest of Oblivion: `_Condition:EnteringPermanentPassesFilter`
- Obliterating Bolt: `_Action:CreateReplaceWouldPutIntoGraveyardUntil`
- Ordeal of Nylea: `_Trigger:WhenACreatureAttacks`
- Ovika, Enigma Goliath: `_Rule:Ward`
- Painful Quandary: `_Action:PlayerMayCost`
- Perforating Artist: `_Players:AttackedThisTurn`
- Pilfer: `_Action:RevealHandAndPlayerChoosesACardToDiscard`
- Pirate's Cutlass: `_Action:AttachPermanentToPermanent`
- Prayer of Binding: `_Action:Exile`
- Predator Ooze: `_Permanents:WasDealtDamageByPermanentThisTurn`
- Prime Speaker Zegana: `_ReplacementActionWouldEnter:EntersWithNumberCounters`
- Quilled Greatwurm: `_Trigger:If`
- Raise the Past: `_Action:ReturnEachCardFromPlayersGraveyardToBattlefield`
- Ramos, Dragon Engine: `_GameNumber:TheNumberOfColorsSpellIs`
- Ravenous Amulet: `_CounterType:SoulCounter`
- Redcap Gutter-Dweller: `_Rule:PermanentRuleEffect`
- Revenge of the Rats: `_Action:CreateTokens`
- River's Rebuke: renders differently from its Oracle text
- Rune-Sealed Wall: `_Action:Surveil`
- Savage Ventmaw: `_Action:AddManaWithModifiers`
- Scrawling Crawler: `_Trigger:WhenAPlayerDrawsACard`
- Searslicer Goblin: `_Players:AttackedThisTurn`
- Secluded Courtyard: `_ReplacementActionWouldEnter:ChooseACreatureType`
- Seize the Spoils: `_Rule:CastEffect`
- Self-Reflection: `_CreatableToken:TokenCopyOfPermanent`
- Sire of Seven Deaths: `_Rule:Ward`
- Skyknight Squire: `_Permanents:HasNumberCountersOfType`
- Skyship Buccaneer: `_Players:AttackedThisTurn`
- Slumbering Cerberus: `_PermanentRule:DoesntUntapDuringControllersUntap`
- Sorcerous Spyglass: `_ReplacementActionWouldEnter:LookAtAPlayersHand`
- Soul-Guide Lantern: `_Action:Exile`
- Soulstone Sanctuary: `_Action:CreatePermanentLayerEffect`
- Sower of Chaos: `_Action:CreatePermanentRuleEffectUntil`
- Sphinx of Forgotten Lore: `_Action:CreateGraveyardCardEffectUntil`
- Sphinx of the Final Word: `_Rule:FromStack`
- Spinner of Souls:
  `_Action:RevealCardsFromTheTopOfLibraryUntilACardOfTypeIsRevealed`
- Springbloom Druid: `_SearchLibraryAction:FindNumberCardsOfType`
- Squad Rallier: `_Action:LookAtTheTopNumberCardsOfLibrary`
- Starlight Snare: `_PermanentRule:DoesntUntapDuringControllersUntap`
- Stasis Snare: `_Action:Exile`
- Storm Fleet Spy: `_Players:AttackedThisTurn`
- Stromkirk Bloodthief: `_Players:LostLifeThisTurn`
- Strongbox Raider: `_Players:AttackedThisTurn`
- Sun-Blessed Healer: `_Condition:EnteringPermanentPassesFilter`
- Surrak, the Hunt Caller: `_Condition:TotalPowerOfPermanentsIs`
- Suspicious Shambler: `_Rule:FromGraveyard`
- Sylvan Scavenging: `_Action:If`
- Teach by Example: `_Action:CreateFutureTrigger`
- Tempest Djinn: `_StaticLayerEffect:AdjustPTForEach`
- Thousand-Year Storm: `_Action:CopySpellForEachAndMayChooseNewTargets`
- Tolarian Terror: `_Rule:CastEffect`
- Tragic Banshee: `_Action:IfElse`
- Tribute to Hunger: `_Action:SacrificeAPermanent`
- Twinflame Tyrant: `_Rule:ReplaceWouldDealDamage`
- Uncharted Haven: `_ReplacementActionWouldEnter:EntersTapped`
- Uncharted Voyage: `_Player:OwnerOfPermanent`
- Undying Malice: `_Rule:TriggerA`
- Valkyrie's Call: `_Action:ReturnDeadGraveyardCardToBattlefield`
- Valorous Stance: `_Permanents:ToughnessIs`
- Vampire Gourmand: renders differently from its Oracle text
- Vanguard Seraph: `_Trigger:WhenAPlayerGainsLifeForTheFirstTimeEachTurn`
- Vengeful Bloodwitch: `_Trigger:Or`
- Venom Connoisseur: `_Action:If`
- Vile Entomber: `_SearchLibraryAction:PutFoundCardsIntoGraveyard`
- Vizier of the Menagerie: `_Rule:PlayerEffect`
- Wardens of the Cycle: `_Condition:ACreatureOrPlaneswalkerDiedThisTurn`
- Wary Thespian: `_Action:Surveil`
- Wildborn Preserver: `_Action:Reflexive_PayManaAnyX_WhenYouDo`
- Wilt-Leaf Liege: `_Rule:ReplaceWouldDiscard`
- Wishclaw Talisman: `_ReplacementActionWouldEnter:EntersWithNumberCounters`
- Zimone, Paradox Sculptor:
  `_PutCountersAction:DoubleAllCountersOnEachPermanent`
- Zul Ashur, Lich Lord: `_Rule:Ward`

## Needs a capability

Each card is tracked by its issue and is added when that issue lands. Hardest
first.

- #5910: Curator of Destinies. A pile effect shows every card in both piles,
  with no pile face down to its chooser (CR 700.3).
- #5911: Muldrotha, the Gravetide. A graveyard permission has one budget, not
  one per permanent type (CR 110.4b).
- #5912: Tinybones, Bauble Burglar. No standing permission plays exiled cards
  picked out by a counter on them.
- #5913: Liliana, Dreadhorde General. Nothing asks for one choice per permanent
  type and sacrifices the rest (CR 110.4).
- #5914: Fishing Pole. A granted ability's cost can't tap the Equipment that
  granted it (CR 602.2).
- #5915: Steel Hellkite. No filter reads whether an object's controller was
  dealt combat damage by this creature.
- #5916: Goblin Negotiation. No quantity reads the excess damage an effect just
  dealt (CR 120.10).
- #5917: Run Away Together. A target slot judges each object alone, with no
  relation among its targets (CR 115.1).
- #5918: Courageous Goblin; Ruby, Daring Tracker. An intervening "if" checks
  again on resolution, where "attacks while" checks only at the event (CR
  603.4).
