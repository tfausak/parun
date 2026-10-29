# Magic Origins census

The Magic Origins (ORI) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-29 from MTGJSON's set list against `data/cards/`.
Re-derive the missing list by writing the set list as a deck (`1 Name` per
line) and running `parun deck` on it: every unresolved name is reported.

## Expressible today

These need no new capability, but `parun translate` does not translate them yet.
Each names the mtgish node the translator stops at.

- Gnarlroot Trapper: `_Action:AddManaWithModifiers`
- Goblin Glory Chaser: `_Permanents:IsRenowned`
- Goblin Piledriver: `_LayerEffect:AdjustPTForEach`
- Grasp of the Hieromancer: `_Rule:TriggerA`
- Hallowed Moonlight: `_Action:CreateReplaceWouldEnterUntil`
- Hangarback Walker: `_ReplacementActionWouldEnter:EntersWithNumberCounters`
- Harbinger of the Tides: `_Rule:CastEffect`
- Helm of the Gods: `_StaticLayerEffect:AdjustPTForEach`
- Herald of the Pantheon: `_Rule:PlayerEffect`
- Hixus, Prison Warden: `_Trigger:WhenACreatureDealsCombatDamageToAPlayer`
- Honored Hierarch: `_Permanents:IsRenowned`
- Infectious Bloodlust: `_PermanentRule:MustAttack`
- Infernal Scarring: `_Rule:TriggerA`
- Infinite Obliteration: `_Action:ChooseACardName`
- Jace's Sanctum: `_Rule:PlayerEffect`
- Jace, Vryn's Prodigy // Jace, Telepath Unbound:
  double-faced, so not a `parun translate` candidate
- Knight of the White Orchid: `_Players:ControlsMorePermanentThanPlayer`
- Kothophed, Soul Hoarder: `_Trigger:WhenAPermanentIsPutIntoAPlayersGraveyard`
- Kytheon's Tactics: `_Action:IfElse`
- Liliana, Heretical Healer // Liliana, Defiant Necromancer:
  double-faced, so not a `parun translate` candidate
- Llanowar Empath: `_Action:RevealTopCardOfLibrary`
- Macabre Waltz: `_Target:UptoNumberTargetGraveyardCards`
- Mage-Ring Bully: `_PermanentRule:MustAttack`
- Mage-Ring Network: `_CounterType:StorageCounter`
- Mage-Ring Responder: `_PermanentRule:DoesntUntapDuringControllersUntap`
- Might of the Masses: `_LayerEffect:AdjustPTForEach`
- Mizzium Meddler: `_Target:TargetSpellOrAbility`
- Molten Vortex: `_Cost:DiscardACardOfType`
- Murder Investigation: `_Trigger:WhenAPermanentDies`
- Necromantic Summons: `_CardsInGraveyards:IsCardtype`
- Nightsnare: `_Action:RevealHand`
- Nissa's Pilgrimage: `_Action:IfElse`
- Nissa's Revelation: `_Action:RevealTopCardOfLibrary`
- Nissa, Vastwood Seer // Nissa, Sage Animist:
  double-faced, so not a `parun translate` candidate
- Orbs of Warding: `_Rule:PlayerEffect`
- Orchard Spirit: renders differently from its Oracle text
- Patron of the Valiant: `_Permanents:HasACounterOfType`
- Possessed Skaab: `_Rule:ReplaceWouldPutIntoGraveyard`
- Prism Ring: `_ReplacementActionWouldEnter:ChooseAColor`
- Psychic Rebuttal: `_Spells:TargetsPlayer`
- Ramroller: `_PermanentRule:MustAttack`
- Ravaging Blaze: `_Action:If`
- Reave Soul: `_Permanents:PowerIs`
- Reclusive Artificer: `_Action:HavePermanentDealDamage`
- Relic Seeker: `_Trigger:WhenACreatureBecomesRenowned`
- Scab-Clan Berserker: `_Permanents:IsRenowned`
- Scrapskin Drake: `_PermanentRule:CanBlockOnly`
- Seismic Elemental: `_Action:CreateEachPermanentRuleEffectUntil`
- Send to Sleep: `_Action:If`
- Sentinel of the Eternal Watch: `_Player:Trigger_ThatPlayer`
- Shadows of the Past: `_Players:NumCardsOfTypeInGraveyardIs`
- Sigil of Valor: `_Trigger:WhenACreatureAttacksAlone`
- Skaab Goliath: `_Rule:CastEffect`
- Smash to Smithereens: `_DamageRecipient:Player`
- Somberwald Alpha: `_Trigger:WhenACreatureBecomesBlocked`
- Sphinx's Tutelage: `_Trigger:WhenAPlayerDrawsACard`
- Starfield of Nyx: `_Action:PutGraveyardCardOntoBattlefield`
- Stratus Walk: `_PermanentRule:CanBlockOnly`
- Subterranean Scout: `_Permanents:PowerIs`
- Suppression Bonds: `_Permanent:HostPermanent`
- Swift Reckoning: `_Rule:CastEffect`
- Sword of the Animist: `_Trigger:WhenACreatureAttacks`
- Sylvan Messenger: `_Action:RevealTheTopNumberCardsOfLibrary`
- Talent of the Telepath: `_Action:IfElse`
- The Great Aurora: `_Action:ShuffleHandAndPermanentsIntoLibrary`
- Thopter Spy Network:
  `_Trigger:WhenAnyNumberOfCreaturesDealCombatDamageToAPlayer`
- Thornbow Archer: `_Players:And`
- Throwing Knife: `_Trigger:WhenACreatureAttacks`
- Tormented Thoughts: `_Rule:CastEffect`
- Touch of Moonglove: `_Action:CreateTriggerUntil`
- Tower Geist: `_Action:LookAtTheTopNumberCardsOfLibrary`
- Tragic Arrogance:
  `_Action:ChooseMultiplePermanentsAmoungPermanentsForEachPlayer`
- Undead Servant: `_CardsInGraveyards:IsNamed`
- Unholy Hunger: `_Action:If`
- Vine Snare: `_Action:CreatePreventDamageUntil`
- Whirler Rogue: `_Cost:TapNumberPermanents`
- Wild Instincts: `_Action:Fight`
- Willbreaker: `_Trigger:WhenAPermanentBecomesTheTargetOfASpellOrAbility`
- Woodland Bellower: `_CardsInLibrary:IsNonSupertype`

## Needs a capability

Each card is tracked by its issue and is added when that issue lands. Hardest
first.

- #5395: Demonic Pact. Nothing remembers which modes an object has already
  chosen, so "choose one that hasn't been chosen" has no reading.
- #4781: Alhammarret's Archive. No draw replacement can spare the first draw in
  a draw step, and none rewrites a draw as two.
- #5756: Alhammarret, High Arbiter. No as-enters step reveals the opponents'
  hands, and a name choice can't be confined to the cards revealed.
- #5758, #5759: Chandra, Fire of Kaladesh // Chandra, Roaring Flame. Nothing
  totals the damage a source dealt this turn, and a damage instruction can't
  bind the players it damaged.
- #5757: Archangel of Tithes. Attack and block costs carry no condition, so
  "as long as this creature is untapped" can't switch them.
- #5762: Exquisite Firecraft. A card's own "can't be countered" carries no
  condition, so spell mastery can't switch it.
- #5754: Tainted Remedy. `LifeGainRewrite` cannot turn a gain into a loss of
  that much life.
