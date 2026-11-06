# Reality Fracture census

The Reality Fracture (FRA) cards not yet in the pool, and which wait on a
capability. Derived 2026-11-06 from MTGJSON's set list against `data/cards/`.
Re-derive the missing list by writing the set list as a deck (`1 Name` per line)
and running `parun deck` on it: every unresolved name is reported.

## Expressible today

These need no new capability, but `parun translate` does not translate them yet.
Each names the mtgish node the translator stops at; "verify" marks a clause the
census did not settle.

- Afterthought Sentry: `_Target:UptoOneTargetGraveyardCard`

- Ajani Resolute: `field: Loyalty`

- Ajani Unrelenting: `field: Loyalty`

- Apex Witchstalker: `_Rule:TypeCycling`

- Arcane Amphisbaena: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Arni, Renowned Champion: `_LayerEffect:AdjustPTX`

- Avatar of Burgeoning Echoes: not yet run through `parun translate` since
  empower Jace landed (#6507)

- Awaken the Inferno: `_Rule:TypeCycling`

- Blazing Crescendo: `_Action:Exile`

- Blessed Ghoul: `_Rule:FromGraveyard`

- Bloodline Recollector // Ancestral Craving: translate skips preparation cards

- Bloombrute: `_Rule:TriggerOnceEachTurn`

- Blossom-Blessed Angel: translate skips preparation cards; verify the clauses
  besides "enters prepared"

- Budding Insurgent: `_Action:If`

- Carnivorous Cultivator: translate skips preparation cards; verify the clauses
  besides "enters prepared"

- Chandra, Torch of Defiance: `field: Loyalty`

- Clash of Elements: `_Action:PlayerMayCost`

- Compel Brutality: `_GameNumber:LoyaltyOfPermanent`

- Countersculpt: not yet run through `parun translate` since empower Jace landed
  (#6507)

- Craftwork Crusher: `_Actions:Modal_ChooseTwo`

- Craterclaw Colossus: `_LayerEffect:AdjustPTX`

- Cruel Calculations:
  `_GameNumber:TheNumberOfCardsPutIntoAPlayersGraveyardFromTheirLibraryThisTurn`;
  verify a history count by owner

- Cryotheory Adept: `_Rule:FromGraveyard`

- Curse-Marred Demon: `_Action:DiscardACardAtRandom`

- Danitha, Spear of Agony: `_Spells:TargetsAPlayer`

- Danitha, Sword of Hope: `_Rule:TriggerOnceEachTurn`

- Dark Matter Manipulator: `_StaticLayerEffect:AdjustPTForEach`

- Darklight Phoenix: `_Rule:FromGraveyard`

- Dedicated Commons: `_ReplacementActionWouldEnter:Unless`

- Denzilore Fatehold: `_Trigger:Or`

- Deserted Beach: `_ReplacementActionWouldEnter:Unless`

- Diviner of Victory: translate skips preparation cards; verify the clauses
  besides "enters prepared"

- Divining Duelist: `_Actions:Modal_ChooseOne`

- Eardrum Rattler: `_Permanents:PowerIs`

- Edgar, Ancient Bloodlord: renders differently from its Oracle text

- Edgar, Moonlit Sovereign: `_Players:HasntCastASpellThisTurn`

- Emergency Phytomedic: translate skips preparation cards; verify the clauses
  besides "enters prepared"

- Emrakul, the Exigent Doom: `_Rule:FromStack`; verify "until this card is cast
  from exile" over a `SpellCast` duration and the exile-from-hand cost

- Essence Burn: `_Action:CreateReplaceWouldPutIntoGraveyardUntil`

- Eye of Jace: `_Action:Surveil`

- Face Yourself: `_CreatableToken:TokenCopyOfEachPermanent`

- Fatehold Annex: `_ReplacementActionWouldEnter:Unless`

- Fatehold Charm: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Fatehold Chronologist: translate skips preparation cards; verify the clauses
  besides "enters prepared"

- Fateshaper Aspirant: `_Actions:Modal_ChooseOne`

- Fblthp, Impossibly Lost: `_Trigger:If`

- Ferocity of the Hunt: `_Trigger:WhenAPermanentDies`

- Flickering Hound: `_Action:PutExiledCardOntoBattlefield`

- Flourishing Grapple: `_LayerEffect:LosesAllAbilities`

- Formidable Commons: `_ReplacementActionWouldEnter:Unless`

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

- Hallway Heckler: translate skips preparation cards; verify the clauses besides
  "enters prepared"

- Hapatra, the Desert Fang: `_Target:UptoOneTargetPermanentEachPlayerControls`

- Hapatra, the Desert Frost: `_Target:UptoOneTargetPermanentEachPlayerControls`

- Haunted Ridge: `_ReplacementActionWouldEnter:Unless`

- Heartstring Puller: `_CreatableToken:NamedTokenWithPT`

- Hexhaven Battalion: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Hexhaven Dueling Arena: `_Permanents:AttackedThisTurn`

- Hexhaven Invigorator: `_Trigger:WhenAPermanentIsDealtDamage`

- Hunter's Axe: `_Rule:TriggerA`

- Icy Reception: `_Player:ControllerOfSpell`

- Identity Echo:
  `_Action:RevealCardsFromTheTopOfLibraryUntilACardOfTypeIsRevealed`

- Ingris Stingerquill: `_Trigger:WhenACreatureAttacks`

- Innovative Commons: `_ReplacementActionWouldEnter:Unless`

- Inspired Tethermage: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Jace's Machinations: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Jace, Reality Sculptor: not yet run through `parun translate` since empower
  Jace landed (#6507)

- Jiang Yanggu, Alone: `_Trigger:WhenACreatureAttacksAPlayerAlone`

- Jiang Yanggu, Never Alone: `_CreatableToken:NamedTokenWithPT`

- Karn, Argent Defender:
  `_Rule:PermanentsEnteringTheBattlefieldDontCauseAbilitiesToTrigger`

- Karn, Gilded Guardian: `_GameNumber:NumColorsAmongPermanents`

- Keeper of the Quiet Hour: not yet run through `parun translate` since empower
  Jace landed (#6507)

- Kindred Judgment: `_Action:ChooseACreatureType`

- Kiora of Fire and Ashes: renders differently from its Oracle text

- Kiora of Salt and Sand: `_Trigger:WhenAPlayerAttacks`

- Konstrari Annex: `_ReplacementActionWouldEnter:Unless`

- Konstrari Charm: `_Actions:Modal_ChooseOne`

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

- Meticulous Commons: `_ReplacementActionWouldEnter:Unless`

- Mind Meanderer: `_Permanents:IsPlaneswalkerType`

- Mindseeker Oculus: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Multiply by Zero: `_LayerEffect:SetPT`

- Murmuring Volume: `_Cost:DiscardACard`

- No Admittance: not yet run through `parun translate` since empower Jace landed
  (#6507)

- Null Summoner: `_Condition:EnteringPermanentPassesFilter`

- Omnipresence: `_Rule:PlayerEffect`

- Overgrown Farmland: `_ReplacementActionWouldEnter:Unless`

- Overwrite the Multiverse: not yet run through `parun translate` since empower
  Jace landed (#6507)

- Paradox Shaper // Omit Variables: translate skips preparation cards

- Perfected Theory: `_LayerEffect:SetPT`

- Pia, Aether Ascetic: `_Cost:DiscardACard`

- Pia, Determined Rebuilder: `_LayerEffect:AdjustPTX`

- Plan for All Outcomes: not yet run through `parun translate` since empower
  Jace landed (#6507)

- Primal Witchstalker: `_Action:Reflexive_Mill_WhenYouDo`

- Proft, Consulting Detective: `_Trigger:Or`

- Proft, Sinister Mastermind: `_Rule:CastEffect`

- Prophesied End: `_Action:If`

- Protege's Awakening: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Prudent Fateseer: translate skips preparation cards; verify the clauses
  besides "enters prepared"

- Puppet Crafting: `_Permanents:IsNonEnchantmentType`

- Pyre Rhymer: translate skips preparation cards; verify the clauses besides
  "enters prepared"

- Recursive Recruitment: `_CreatableToken:NamedTokenWithPT`

- Refute Destiny: `_Action:Surveil`

- Repurposed Enforcer: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Restore with Empathy: `_CardsInGraveyards:IsPermanent`

- Return to the Light Realms:
  `_Action:ReturnEachCardFromPlayersGraveyardToBattlefield`

- Rewrite Regrets: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Rise of the Deathbringer: `_GameNumber:TheGreatestPowerAmongPermanents`

- Rockfall Vale: `_ReplacementActionWouldEnter:Unless`

- Roiling Canopy: `_Permanent:Trigger_ThatPermanent`

- Room of Refuge: `_ReplacementActionWouldEnter:EntersTapped`

- Ruric Thar, Biomagus:
  `_Trigger:WhenAPermanentBecomesTheTargetOfASpellOrAbility`

- Ruric Thar, Magecrusher: `_Rule:FromStack`

- Saheeli, Consul of Oversight: `_Rule:TriggerOnceEachTurn`

- Samut, Tyrant of Naktamun: `_Rule:StackSpellsEffect`

- Sanctum Lurker: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Seasoned Cryomancer:
  `_Action:Reflexive_Discard_WhenYouDiscardOneOrMoreCardsOfTypeThisWay`

- Semester Foreseer: translate skips preparation cards; verify the clauses
  besides "enters prepared"

- Shipwreck Marsh: `_ReplacementActionWouldEnter:Unless`

- Silence the Echo: `_Rule:CastEffect`

- Solarium Sentry: `_Spells:ManaValueIs`

- Solitary Cell: `_Permanents:ManaValueIs`

- Solve for Disappointment: not yet run through `parun translate` since empower
  Jace landed (#6507)

- Something Worth Saving: `_Action:PutACardFromGraveyardIntoHand`

- Sphinx of False Conclusions: `_Permanent:Trigger_ThatPermanent`

- Sphinx's Approach: `_Cost:Exile`; verify the optional "exile this spell and
  four cards named" step

- Stingcaster Mage: `_Action:CreateGraveyardCardEffectUntil`

- Stingerquill Annex: `_ReplacementActionWouldEnter:Unless`

- Stingerquill Charm: `_CreatableToken:NamedTokenWithPT`

- Stingerquill Voxmancer // Vicious Verse: translate skips preparation cards

- Stinging Vitriol: `_Action:RevealHandAndPlayerChoosesACardToDiscard`

- Sureshot Sower: `_Rule:FromHand`

- Surgical Precision: `_Permanents:ToughnessIs`

- Tam's Resistance: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Tether Technician: `_Action:Reflexive_Discard_WhenYouDo`

- Tetsuko Umezawa, Fugitive: `_Permanents:PowerIs`

- Tetsuko Umezawa, Pursuer: `_Trigger:WhenACreatureBlocks`

- Teyo, Diamondblade Mage: `_Action:If`

- Teyo, Lightshield Expert: `_Action:If`

- The Echoverse Fulcrum: `_Cost:Exile`

- Theoretical Necromancer: `_Rule:FromGraveyard`

- Theorist's Proxy: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Theorist's Sanctum: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Theorix Annex: `_ReplacementActionWouldEnter:Unless`

- Theorix Charm: `_Player:ControllerOfSpell`

- Theorix Metamage: translate skips preparation cards; verify the clauses
  besides "enters prepared"

- Tinybones, Pocket Nuisance: `_Trigger:WhenAPlayerDiscardsAnyNumberOfCards`

- Titanbones, Towering Heart: `_Trigger:WhenAPlayerGainsLife`

- Tomik, Izzet Sparkmage: `_Rule:ReplaceWouldDealDamage`

- Transformative Commons: `_ReplacementActionWouldEnter:Unless`

- Traxos, Academy Guardian: `_Rule:CastEffect`

- Traxos, Scourge Eternal: `_PermanentRule:DoesntUntapDuringControllersUntap`

- Twinned Vision: `_Action:IfElse`

- Twisted Fates: renders differently from its Oracle text

- Uldaros Theorix: `_Condition:EnteringPermanentPassesFilter`; verify "up to one
  target nonland card of each card type"

- Undulating Witness: `_Rule:TypeCycling`

- Unflinching Hortimancer: `_Rule:Ward`

- Variable Chaser: translate skips preparation cards; verify the clauses besides
  "enters prepared"

- Verdant Kraken: renders differently from its Oracle text

- Vigorbloom Annex: `_ReplacementActionWouldEnter:Unless`

- Vigorbloom Charm: `_Action:Fight`

- Vigorbloom Vanguard: translate skips preparation cards; verify the clauses
  besides "enters prepared"

- Vindictive Triumph: `_Action:If`

- Vinelasher Adept: `_Rule:TypeCycling`

- Violent Echoes: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Void Extrapolator: translate skips preparation cards; verify the clauses
  besides "enters prepared"

- Vraska's Final Mercy: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Vraska, Soul of Stone: `_Rule:Activated`

- Vraska, the Cutting Glare: `_Permanents:IsPermanent`

- Warrior's Blades: `_Rule:EquipWithModifiers`; verify a reduction counting
  counters on the target (Dwarven Mauler shows targets reach it)

- Way of the Cryomancer: not yet run through `parun translate` since empower
  Jace landed (#6507)

- Way of the Deathbringer: not yet run through `parun translate` since empower
  Jace landed (#6507)

- Way of the Healer: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Way of the Mind Sculptor: not yet run through `parun translate` since empower
  Jace landed (#6507)

- Way of the Necromancer: not yet run through `parun translate` since empower
  Jace landed (#6507)

- Way of the Paradox: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Way of the Pyromancer: not yet run through `parun translate` since empower
  Jace landed (#6507)

- Way of the Warlord: not yet run through `parun translate` since empower Jace
  landed (#6507)

- Way of the Wildspeaker: not yet run through `parun translate` since empower
  Jace landed (#6507)

- Whiplash Wordsmith: translate skips preparation cards; verify the clauses
  besides "enters prepared"

- Winter, Tormented Loner: `_Action:Reflexive_Sacrifice_WhenYouDo`

- Wrath of the Bloodmane: `_Rule:CastEffect`

- Wrecking Gecko: `_Rule:Ward`

- Yoshimaru, Beloved Companion: `_Rule:ReplaceWouldPutCounters`

- Yoshimaru, Scrappy Stray: `_Action:Fight`

- Your Fate Ends Here: `_Permanents:ManaValueIs`

- Yuriko, Blade of the Mighty: `_Condition:IsDuringCombat`

- Yuriko, Hope from the Shadows: `_LayerEffect:AdjustPTX`

## Needs a capability

Each card is tracked by its issue and is added when that issue lands. Hardest
first.

- #6526: Aerid Konstrari; Heartwood Crafter // Soul Tether; Hungering
  Puppetbeast; Konstrari Improviser // Soul Tether; Tenured Tethermage; Woodwork
  Prodigy // Soul Tether. No Heartwood artifact type in `Parun.Types.Subtype`
  (CR 205.3g, 111.10x); besides it, Aerid Konstrari stops at
  `_CreatableToken:HeartwoodToken`, Tenured Tethermage at
  `_Action:CreateTokens`, and translate skips the three preparation cards
  (verify the clauses besides "enters prepared").
