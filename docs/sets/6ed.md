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
- Balduvian Horde: `Action:MayCost`
- Browse: `Action:LookAtTheTopNumberCardsOfLibrary`
- Call of the Wild: `Action:RevealTopCardOfLibrary`
- Chill: `Rule:EachPlayerEffect`
- Disrupting Scepter: `Rule:ActivatedWithModifiers`
- Dragon Mask: `Action:CreateFutureTrigger`
- Dream Cache: `Action:ChooseAnAction`
- Elven Riders: `Rule:PermanentRuleEffect`
- Enlightened Tutor: `Action:SearchLibrary`
- Evil Eye of Orms-by-Gore: `Rule:EachPermanentRuleEffect`
- Firebreathing: `Permanent:HostPermanent`
- Gaseous Form: `Rule:PreventDamage`
- Goblin Recruiter: `Action:SearchLibrary`
- Gravebane Zombie: `Rule:ReplaceWouldPutIntoGraveyard`
- Hecatomb: `Action:MayCost`
- Light of Day: `Rule:EachPermanentRuleEffect`
- Millstone: `Action:MillNumberCards`
- Mind Warp: `Action:LookAtPlayersHandAndChooseNumCardsToDiscard`
- Phantasmal Terrain: `ReplacementActionWouldEnter:ChooseABasicLandType`
- Polymorph: `Action:RevealCardsFromTheTopOfLibraryUntilACardOfTypeIsRevealed`
- Rag Man: `Rule:ActivatedWithModifiers`
- Recall: `Action:ReturnNumberCardsFromPlayersGraveyardToHand`
- Regeneration: `Permanent:HostPermanent`
- Sage Owl: `Action:LookAtTheTopNumberCardsOfLibrary`
- Soldevi Sage: `Cost:SacrificeNumberPermanents`
- Spirit Link: `Trigger:WhenAPermanentDealsDamage`
- Spitting Drake: `Rule:ActivatedWithModifiers`
- Storm Cauldron: `Rule:EachPlayerEffect`
- Teferi's Puzzle Box: `Action:PlayerActions`
- Thicket Basilisk: `Action:CreateFutureTrigger`
- Wand of Denial: `Action:LookAtTheTopCardOfPlayersLibrary`
- Worldly Tutor: `Action:SearchLibrary`
- Zombie Master: `Rule:Activated`

## Needs a capability

Each group is tracked by its issue; its cards are added when it lands. Hardest
first.

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
- #5524: Derelor. A cost increase of coloured mana.

## Decks

MTGJSON lists two 6ED decks, the preconstructed Deck A and Deck B. Neither is in
`data/decks/` yet. Every card of Deck B is in the pool; Deck A also holds Call
of the Wild and Gravebane Zombie, both expressible today.
