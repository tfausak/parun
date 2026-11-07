# Reality Fracture census

The Reality Fracture (FRA) cards not yet in the pool, and which wait on a
capability. Derived 2026-11-06 from MTGJSON's set list against `data/cards/`.
Re-derive the missing list by writing the set list as a deck (`1 Name` per line)
and running `parun deck` on it: every unresolved name is reported.

## Expressible today

These need no new capability, but `parun translate` does not translate them yet.
Each names the mtgish node the translator stops at; "verify" marks a clause the
census did not settle.















































- Fblthp, Impossibly Lost: `_Trigger:If`

- Ferocity of the Hunt: `_Trigger:WhenAPermanentDies`

- Flickering Hound: `_Action:PutExiledCardOntoBattlefield`

- Flourishing Grapple: `_LayerEffect:LosesAllAbilities`


- Fulminous Forte: renders differently from its Oracle text

- Gallia, Tragic Host: `_Rule:FromGraveyard`

- Gallia, the Merrymaker: `_Permanents:HasACounterOfType`

- Gardenize: `_CounterType:ChargeCounter`

- Garruk, Curse Breaker: `field: Loyalty`; verify the −4's "those creatures"

- Garruk, Veiled Butcher: `field: Loyalty`; verify "for each opponent who didn't
  discard two nonland cards"

- Geist of Saint Thalia: `_Rule:PlayerEffect`

- Generous Revival: `_CardsInGraveyards:ManaValueIs`

- Germinate Recruits: `_GameNumber:LifeGainedByPlayerThisTurn`

- Ghalta the Immovable: `_Rule:CastEffect`

- Ghalta the Unstoppable: `_Rule:CastEffect`

- Gideon the Oathless: `_Rule:Ward`

- Gideon's Memorial: `_Action:AddManaWithModifiers`

- Graft Surgeon: `_ReplacementActionWouldEnter:EntersWithACounter`

- Grim Repriser: `_Rule:FromGraveyard`

- Guiding Hydra: `_ReplacementActionWouldEnter:EntersWithNumberCounters`

- Hallway Heckler: `_Cost:DiscardACard`; shares Vicious Verse

- Hapatra, the Desert Fang: `_Target:UptoOneTargetPermanentEachPlayerControls`

- Hapatra, the Desert Frost: `_Target:UptoOneTargetPermanentEachPlayerControls`


- Heartstring Puller: `_CreatableToken:NamedTokenWithPT`

- Heartwood Crafter: `_Action:AddManaWithModifiers`; shares Soul Tether

- Hexhaven Battalion: `_CreatableToken:NamedTokenWithPT`

- Hexhaven Dueling Arena: `_Permanents:AttackedThisTurn`

- Hexhaven Invigorator: `_Trigger:WhenAPermanentIsDealtDamage`

- Hungering Puppetbeast: `_CreatableToken:HeartwoodToken`

- Hunter's Axe: `_Rule:TriggerA`

- Icy Reception: `_Player:ControllerOfSpell`

- Identity Echo:
  `_Action:RevealCardsFromTheTopOfLibraryUntilACardOfTypeIsRevealed`

- Ingris Stingerquill: `_Trigger:WhenACreatureAttacks`


- Inspired Tethermage:
  `_Trigger:WhenAPlayerPutsAnyNumberOfCountersOfTypeOnAPermanent`

- Jace's Machinations: `_Action:CreatePlayerEffectUntil`

- Jace, Reality Sculptor: `field: Loyalty`

- Jiang Yanggu, Alone: `_Trigger:WhenACreatureAttacksAPlayerAlone`

- Jiang Yanggu, Never Alone: `_CreatableToken:NamedTokenWithPT`

- Karn, Argent Defender:
  `_Rule:PermanentsEnteringTheBattlefieldDontCauseAbilitiesToTrigger`

- Karn, Gilded Guardian: `_GameNumber:NumColorsAmongPermanents`


- Kindred Judgment: `_Action:ChooseACreatureType`

- Kiora of Fire and Ashes: renders differently from its Oracle text

- Kiora of Salt and Sand: `_Trigger:WhenAPlayerAttacks`


- Konstrari Charm: `_Actions:Modal_ChooseOne`

- Konstrari Improviser: `_CreatableToken:HeartwoodToken`; shares Soul Tether

- Koth, the Geomancer: `_Action:If`

- Kwia Vigorbloom: `_Rule:Ward`

- Lich's Relic: `_Action:Reflexive_PayMana_WhenYouDo`

- Liliana the Faultless: renders differently from its Oracle text

- Liliana the Repentant: `_Action:PutGraveyardCardOntoBattlefield`

- Living Library: `_Action:ShufflePermanentIntoLibrary`

- Lyra, Archangel of Dawn: `_Trigger:WhenAPlayerGainsLife`

- Lyra, Tolarian Archangel: `_Players:NumCardsDrawnThisTurnIs`

- Mabel, Bitter Recluse: `_Action:RemoveCounters`

- Mabel, Valley Hero: `_Trigger:Or`

- Massacre Girl, Most Wanted: `_Trigger:WhenAPlayerIsDealtNoncombatDamage`

- Master of Barbs: `_Trigger:WhenAnyNumberOfPlayersAreDealtNoncombatDamage`

- Medic's Kitesail: `_Rule:TriggerA`

- Memory Trap: `_Action:Exile`


- Mind Meanderer: `_Permanents:IsPlaneswalkerType`


- Multiply by Zero: `_LayerEffect:SetPT`

- Murmuring Volume: `_Cost:DiscardACard`

- No Admittance: renders differently from its Oracle text

- Null Summoner: `_Condition:EnteringPermanentPassesFilter`

- Omnipresence: `_Rule:PlayerEffect`


- Overwrite the Multiverse: `_Action:Exile`

- Paradox Shaper // Omit Variables: `_Permanents:IsntPrepared`; shares Omit
  Variables

- Perfected Theory: `_LayerEffect:SetPT`

- Pia, Aether Ascetic: `_Cost:DiscardACard`

- Pia, Determined Rebuilder: `_LayerEffect:AdjustPTX`

- Plan for All Outcomes: `_Permanents:IsPermanent`

- Primal Witchstalker: `_Action:Reflexive_Mill_WhenYouDo`

- Proft, Consulting Detective: `_Trigger:Or`

- Proft, Sinister Mastermind: `_Rule:CastEffect`

- Prophesied End: `_Action:If`


- Prudent Fateseer: `_Rule:TriggerOnceEachTurn`; shares Peer Review

- Puppet Crafting: `_Permanents:IsNonEnchantmentType`

- Pyre Rhymer: `_Action:CreateTriggerUntil`

- Recursive Recruitment: `_CreatableToken:NamedTokenWithPT`

- Refute Destiny: `_Action:Surveil`

- Repurposed Enforcer: renders differently from its Oracle text

- Restore with Empathy: `_CardsInGraveyards:IsPermanent`

- Return to the Light Realms:
  `_Action:ReturnEachCardFromPlayersGraveyardToBattlefield`

- Rewrite Regrets: `_CardsInGraveyards:ManaValueIs`

- Rise of the Deathbringer: `_GameNumber:TheGreatestPowerAmongPermanents`


- Roiling Canopy: `_Permanent:Trigger_ThatPermanent`

- Room of Refuge: `_ReplacementActionWouldEnter:EntersTapped`

- Ruric Thar, Biomagus:
  `_Trigger:WhenAPermanentBecomesTheTargetOfASpellOrAbility`

- Ruric Thar, Magecrusher: `_Rule:FromStack`

- Saheeli, Consul of Oversight: `_Rule:TriggerOnceEachTurn`

- Samut, Tyrant of Naktamun: `_Rule:StackSpellsEffect`

- Sanctum Lurker: `_PermanentRule:ArentPutIntoGraveyardForHaving0Loyalty`

- Seasoned Cryomancer:
  `_Action:Reflexive_Discard_WhenYouDiscardOneOrMoreCardsOfTypeThisWay`

- Semester Foreseer: `_Action:Surveil`; shares Peer Review


- Silence the Echo: `_Rule:CastEffect`

- Solarium Sentry: `_Spells:ManaValueIs`

- Solitary Cell: `_Permanents:ManaValueIs`

- Solve for Disappointment: `_Action:RevealHandAndPlayerChoosesACardToDiscard`

- Something Worth Saving: `_Action:PutACardFromGraveyardIntoHand`

- Sphinx of False Conclusions: `_Permanent:Trigger_ThatPermanent`

- Sphinx's Approach: `_Cost:Exile`; verify the optional "exile this spell and
  four cards named" step

- Stingcaster Mage: `_Action:CreateGraveyardCardEffectUntil`


- Stingerquill Charm: `_CreatableToken:NamedTokenWithPT`

- Stingerquill Voxmancer // Vicious Verse: `_Permanents:IsntPrepared`; shares
  Vicious Verse

- Stinging Vitriol: `_Action:RevealHandAndPlayerChoosesACardToDiscard`

- Sureshot Sower: `_Rule:FromHand`

- Surgical Precision: `_Permanents:ToughnessIs`


- Tenured Tethermage: `_Action:CreateTokens`

- Tether Technician: `_Action:Reflexive_Discard_WhenYouDo`

- Tetsuko Umezawa, Fugitive: `_Permanents:PowerIs`

- Tetsuko Umezawa, Pursuer: `_Trigger:WhenACreatureBlocks`

- Teyo, Diamondblade Mage: `_Action:If`

- Teyo, Lightshield Expert: `_Action:If`

- The Echoverse Fulcrum: `_Cost:Exile`

- Theoretical Necromancer: `_Rule:FromGraveyard`

- Theorist's Proxy: `_Action:CreateFutureSpellEffect`

- Theorist's Sanctum: `_ReplacementActionWouldEnter:MayCost`


- Theorix Charm: `_Player:ControllerOfSpell`


- Tinybones, Pocket Nuisance: `_Trigger:WhenAPlayerDiscardsAnyNumberOfCards`

- Titanbones, Towering Heart: `_Trigger:WhenAPlayerGainsLife`

- Tomik, Izzet Sparkmage: `_Rule:ReplaceWouldDealDamage`


- Traxos, Academy Guardian: `_Rule:CastEffect`

- Traxos, Scourge Eternal: `_PermanentRule:DoesntUntapDuringControllersUntap`

- Twinned Vision: `_Action:IfElse`

- Twisted Fates: renders differently from its Oracle text

- Uldaros Theorix: `_Condition:EnteringPermanentPassesFilter`; verify "up to one
  target nonland card of each card type"

- Undulating Witness: `_Rule:TypeCycling`

- Unflinching Hortimancer: `_Rule:Ward`

- Variable Chaser: `_Action:EachPlayerMayActions`

- Verdant Kraken: renders differently from its Oracle text


- Vigorbloom Charm: `_Action:Fight`

- Vigorbloom Vanguard: `_Permanents:HasACounterOfType`; shares Seed Suture

- Vindictive Triumph: `_Action:If`

- Vinelasher Adept: `_Rule:TypeCycling`

- Violent Echoes: `_Action:If`



- Vraska, Soul of Stone: `_Rule:Activated`

- Vraska, the Cutting Glare: `_Permanents:IsPermanent`

- Warrior's Blades: `_Rule:EquipWithModifiers`; verify a reduction counting
  counters on the target (Dwarven Mauler shows targets reach it)

- Way of the Cryomancer: `_Rule:Activated`

- Way of the Deathbringer: `_Rule:Activated`

- Way of the Healer: `_Rule:Activated`

- Way of the Mind Sculptor: `_Trigger:WhenAPlayerActivatesAnAbility`

- Way of the Necromancer: `_CounterType:LoyaltyCounter`

- Way of the Paradox: `_Trigger:WhenAPlayerActivatesAnAbility`

- Way of the Pyromancer: `_Rule:Activated`

- Way of the Warlord: `_Rule:Activated`

- Way of the Wildspeaker: `_Rule:Activated`

- Whiplash Wordsmith: `_Players:WasDealtNoncombatDamageThisTurn`; shares Vicious
  Verse

- Winter, Tormented Loner: `_Action:Reflexive_Sacrifice_WhenYouDo`

- Woodwork Prodigy // Soul Tether: `_Permanents:IsntPrepared`; shares Soul
  Tether

- Wrath of the Bloodmane: `_Rule:CastEffect`

- Wrecking Gecko: `_Rule:Ward`

- Yoshimaru, Beloved Companion: `_Rule:ReplaceWouldPutCounters`

- Yoshimaru, Scrappy Stray: `_Action:Fight`

- Your Fate Ends Here: `_Permanents:ManaValueIs`

- Yuriko, Blade of the Mighty: `_Condition:IsDuringCombat`

- Yuriko, Hope from the Shadows: `_LayerEffect:AdjustPTX`

## Needs a capability

### #6546: no cost exiles a card from its owner's hand

- Emrakul, the Exigent Doom: its hand ability's cost, its "until this card is
  cast from exile" and its cast permission all name the card the cost exiled.
