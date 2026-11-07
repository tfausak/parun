# Reality Fracture census

The Reality Fracture (FRA) cards not yet in the pool, and which wait on a
capability. Derived 2026-11-06 from MTGJSON's set list against `data/cards/`.
Re-derive the missing list by writing the set list as a deck (`1 Name` per line)
and running `parun deck` on it: every unresolved name is reported.

## Expressible today

These need no new capability, but `parun translate` does not translate them yet.
Each names the mtgish node the translator stops at; "verify" marks a clause the
census did not settle.






















































































































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

### #6560: no effect removes up to N counters of any kind

- Mabel, Bitter Recluse: "remove up to three counters" from its target takes
  any kinds; the mixed-kind removal prompt has no cap.

### #6546: no cost exiles a card from its owner's hand

- Emrakul, the Exigent Doom: its hand ability's cost, its "until this card is
  cast from exile" and its cast permission all name the card the cost exiled.

### #6556: no effect counts the opponents whose discard fell short

- Garruk, Veiled Butcher: the −3 draws per opponent who didn't discard two
  nonland cards this way; the discard binds every opponent's cards together.
