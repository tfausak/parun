# Sixth Edition census

The Sixth Edition (6ED) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-22 from MTGJSON's set list against `data/cards/`.
Re-derive the missing list by writing the set list as a deck (`1 Name` per
line) and running `pawl deck` on it: every unresolved name is reported.

## Expressible today

These need no new capability. They are left for the mtgish translator (#5478)
rather than written by hand; no Sixth Edition card's whole text is keywords, so
`script/ingest` adds none of them.

- Abduction
- Abyssal Hunter
- Abyssal Specter
- Adarkar Wastes
- Aladdin's Ring
- Anaba Shaman
- Animate Wall
- Ankh of Mishra
- Ashen Powder
- Balduvian Horde
- Blight
- Blighted Shaman
- Bog Rats
- Boomerang
- Bottle of Suleiman
- Browse
- Brushland
- Burrowing
- Call of the Wild
- Castle
- Charcoal Diamond
- Chill
- Circle of Protection: Black
- Circle of Protection: Blue
- Circle of Protection: Green
- Circle of Protection: Red
- Circle of Protection: White
- City of Brass
- Conquer
- Creeping Mold
- Crusade
- Crystal Rod
- Crystal Vein
- Cursed Totem
- D'Avenant Archer
- Daraja Griffin
- Daring Apprentice
- Derelor
- Dingus Egg
- Disrupting Scepter
- Divine Transformation
- Dragon Engine
- Dragon Mask
- Dread of Night
- Dream Cache
- Dwarven Ruins
- Early Harvest
- Ebon Stronghold
- Elder Druid
- Elven Riders
- Enfeeblement
- Enlightened Tutor
- Ethereal Champion
- Evil Eye of Orms-by-Gore
- Exile
- Fallen Angel
- Fallow Earth
- Fear
- Feast of the Unicorn
- Femeref Archers
- Fervor
- Fire Diamond
- Firebreathing
- Fit of Rage
- Flying Carpet
- Fog Elemental
- Forget
- Fountain of Youth
- Fyndhorn Brownie
- Fyndhorn Elder
- Gaseous Form
- Giant Strength
- Glasses of Urza
- Goblin Digging Team
- Goblin Elite Infantry
- Goblin King
- Goblin Recruiter
- Goblin Warrens
- Gorilla Chieftain
- Gravebane Zombie
- Hammer of Bogardan
- Harmattan Efreet
- Havenwood Battleground
- Healing Salve
- Heavy Ballista
- Hecatomb
- Howl from Beyond
- Howling Mine
- Icatian Town
- Infantry Veteran
- Inferno
- Insight
- Iron Star
- Ivory Cup
- Jalum Tome
- Jayemdae Tome
- Jokulhaups
- Karplusan Forest
- Kjeldoran Dead
- Lead Golem
- Leshrac's Rite
- Light of Day
- Lightning Blast
- Living Lands
- Mana Prism
- Manabarbs
- Marble Diamond
- Maro
- Mesa Falcon
- Millstone
- Mind Warp
- Mischievous Poltergeist
- Moss Diamond
- Necrosavant
- Orcish Artillery
- Order of the Sacred Torch
- Painful Memories
- Patagia Golem
- Pearl Dragon
- Pentagram of the Ages
- Perish
- Pestilence
- Phantasmal Terrain
- Phyrexian Vault
- Pillage
- Polymorph
- Pradesh Gypsies
- Psychic Venom
- Radjan Spirit
- Rag Man
- Recall
- Reckless Embermage
- Regeneration
- Resistance Fighter
- River Boa
- Ruins of Trokair
- Sage Owl
- Sea Monster
- Sengir Autocrat
- Serenity
- Serra's Blessing
- Shatter
- Shatterstorm
- Sibilant Spirit
- Skull Catapult
- Sky Diamond
- Snake Basket
- Soldevi Sage
- Spell Blast
- Spirit Link
- Spitting Drake
- Staunch Defenders
- Storm Cauldron
- Strands of Night
- Stream of Life
- Stromgald Cabal
- Stupor
- Sulfurous Springs
- Svyelunite Temple
- Teferi's Puzzle Box
- The Hive
- Thicket Basilisk
- Throne of Bone
- Tranquil Grove
- Tranquility
- Uktabi Orangutan
- Uktabi Wildcats
- Underground River
- Unseen Walker
- Unyaro Griffin
- Verduran Enchantress
- Vertigo
- Vitalize
- Volcanic Geyser
- Waiting in the Weeds
- Wall of Fire
- Wand of Denial
- Warmth
- Warrior's Honor
- Wooden Sphere
- Worldly Tutor
- Wyluli Wolf
- Zombie Master

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
expressible today: Call of the Wild, Creeping Mold, Enfeeblement, Gravebane
Zombie, Healing Salve, Mischievous Poltergeist and Warrior's Honor (Deck A), and
Boomerang, Castle, D'Avenant Archer, Fit of Rage, Lightning Blast, Mana Prism,
Sibilant Spirit and Wall of Fire (Deck B).
