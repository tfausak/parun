# Sixth Edition census

The Sixth Edition (6ED) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-22 from MTGJSON's set list against `data/cards/`.
Re-derive the missing list by writing the set list as a deck (`1 Name` per
line) and running `pawl deck` on it: every unresolved name is reported.

## Expressible today

These need no new capability, but `pawl translate` does not translate them yet.
Each names the mtgish node the translator stops at, or what its rendering gets
wrong. No Sixth Edition card's whole text is keywords, so `script/ingest` adds
none of them.

- Abduction: `Permanent:HostPermanent`
- Animate Wall: `Rule:PermanentRuleEffect`
- Ankh of Mishra: `Permanent:Trigger_ThatPermanent`
- Ashen Powder: `Action:PutGraveyardCardOntoBattlefield`
- Balduvian Horde: `Action:MayCost`
- Blight: `Trigger:WhenAPermanentBecomesTapped`
- Bog Rats: `Rule:PermanentRuleEffect`
- Bottle of Suleiman: `Action:FlipACoin_OnWinAndLose`
- Browse: `Action:LookAtTheTopNumberCardsOfLibrary`
- Call of the Wild: `Action:RevealTopCardOfLibrary`
- Chill: `Rule:EachPlayerEffect`
- Circle of Protection: Black: `Action:ChooseADamageSource`
- Circle of Protection: Blue: `Action:ChooseADamageSource`
- Circle of Protection: Green: `Action:ChooseADamageSource`
- Circle of Protection: Red: `Action:ChooseADamageSource`
- Circle of Protection: White: `Action:ChooseADamageSource`
- City of Brass: `Trigger:WhenAPermanentBecomesTapped`
- Conquer: `StaticLayerEffect:SetController`
- Cursed Totem: `Rule:ActivatedAbilityEffect`
- Derelor: `Rule:PlayerEffect`
- Dingus Egg: `Trigger:WhenAPermanentIsPutIntoAPlayersGraveyard`
- Disrupting Scepter: `Rule:ActivatedWithModifiers`
- Dragon Mask: `Action:CreateFutureTrigger`
- Dream Cache: `Action:ChooseAnAction`
- Early Harvest: `Action:UntapEachPermanent`
- Elder Druid: `Action:TapOrUntapPermanent`
- Elven Riders: `Rule:PermanentRuleEffect`
- Enlightened Tutor: `Action:SearchLibrary`
- Ethereal Champion: `Action:CreateFuturePreventDamage`
- Evil Eye of Orms-by-Gore: `Rule:EachPermanentRuleEffect`
- Exile: renders as one sentence, "attacking nonwhite"
- Firebreathing: `Permanent:HostPermanent`
- Fog Elemental: `Action:CreateFutureTrigger`
- Forget: `Action:PlayerActions`
- Gaseous Form: `Rule:PreventDamage`
- Glasses of Urza: `Action:LookAtPlayersHand`
- Goblin Elite Infantry: renders "blocks or becomes blocked" as two triggers
- Goblin Recruiter: `Action:SearchLibrary`
- Goblin Warrens: `Cost:SacrificeNumberPermanents`
- Gravebane Zombie: `Rule:ReplaceWouldPutIntoGraveyard`
- Hammer of Bogardan: `Rule:FromGraveyard`
- Healing Salve: `Action:CreateFuturePreventDamage`
- Hecatomb: `Action:MayCost`
- Howl from Beyond: `LayerEffect:AdjustPTX`
- Howling Mine: `Condition:PermanentPassesFilter`
- Insight: renders "you draw a card" as "draw a card"
- Kjeldoran Dead: `Action:SacrificeAPermanent`
- Lead Golem: `Action:PermanentDoesntUntapDuringControllersNextUntap`
- Light of Day: `Rule:EachPermanentRuleEffect`
- Living Lands: `StaticLayerEffect:SetPT`
- Manabarbs: `Trigger:WhenAPlayerTapsAPermanentForMana`
- Millstone: `Action:MillNumberCards`
- Mind Warp: `Action:LookAtPlayersHandAndChooseNumCardsToDiscard`
- Necrosavant: `Rule:FromGraveyard`
- Orcish Artillery: `Action:PermanentDealsMultipleDamage`
- Painful Memories: `Action:LookAtPlayersHand`
- Pentagram of the Ages: `Action:ChooseADamageSource`
- Phantasmal Terrain: `ReplacementActionWouldEnter:ChooseABasicLandType`
- Polymorph: `Action:RevealCardsFromTheTopOfLibraryUntilACardOfTypeIsRevealed`
- Psychic Venom: `Trigger:WhenAPermanentBecomesTapped`
- Radjan Spirit: `LayerEffect:LosesAbility`
- Rag Man: `Rule:ActivatedWithModifiers`
- Recall: `Action:ReturnNumberCardsFromPlayersGraveyardToHand`
- Reckless Embermage: `Action:PermanentDealsMultipleDamage`
- Regeneration: `Permanent:HostPermanent`
- Resistance Fighter: `Action:CreatePreventDamageUntil`
- Sage Owl: `Action:LookAtTheTopNumberCardsOfLibrary`
- Sea Monster: `Rule:PermanentRuleEffect`
- Sengir Autocrat: `Trigger:WhenAPermanentLeavesTheBattlefield`
- Sibilant Spirit: `Action:PlayerMayAction`
- Snake Basket: `Rule:ActivatedWithModifiers`
- Soldevi Sage: `Cost:SacrificeNumberPermanents`
- Spell Blast: `Spells:AnySpell`
- Spirit Link: `Trigger:WhenAPermanentDealsDamage`
- Spitting Drake: `Rule:ActivatedWithModifiers`
- Storm Cauldron: `Rule:EachPlayerEffect`
- Strands of Night: `Action:PutGraveyardCardOntoBattlefield`
- Stupor: `Action:PlayerActions`
- Teferi's Puzzle Box: `Action:PlayerActions`
- The Hive: `CreatableToken:NamedTokenWithPT`
- Thicket Basilisk: `Action:CreateFutureTrigger`
- Vertigo: `LayerEffect:LosesAbility`
- Waiting in the Weeds: `Action:EachPlayerCreatesTokens`
- Wand of Denial: `Action:LookAtTheTopCardOfPlayersLibrary`
- Worldly Tutor: `Action:SearchLibrary`
- Zombie Master: `Rule:Activated`

## Needs a capability

Each group is tracked by its issue; its cards are added when it lands. Hardest
first.

- #5311: Juxtapose. "The greatest mana value among" outside an edict, then a
  swap of each player's pick.
- #5310: Tariff. A payment priced at the mana cost of the creature a player
  just picked.
- #5405: Library of Lat-Nam. An opponent chooses the mode.
- #5495: Jade Monolith and Kjeldoran Royal Guard. Two missing parameters on the
  damage redirection: the next hit only, and sources described rather than
  chosen.
- #5496: Syphon Soul. The amount of damage an instruction dealt; "each other
  player" is also related to #5404.
- #5497: Mana Short and Power Sink. Emptying a mana pool, Drain Power's move
  with no recipient.
- #5498: Mystic Compass. A basic land type chosen as an ability resolves.
- #5499: Dense Foliage. A targeting restriction for spells only, from any
  player.
- #5500: Primal Clay. A creature type among an enters-as choice's values.
- #5501: Crimson Hellkite. An activation paid only with mana of a printed
  colour.

## Decks

MTGJSON lists two 6ED decks, the preconstructed Deck A and Deck B. Neither is in
`data/decks/` yet, since each holds cards the pool lacks, all of them
expressible today: Call of the Wild, Gravebane Zombie and Healing Salve (Deck
A), and Sibilant Spirit (Deck B).
