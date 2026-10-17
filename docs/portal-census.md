# Portal census

The Portal (POR) cards not yet in the pool, for #5182 unit 6: which can be
written today, from which template, and which wait on a capability. Derived
2026-10-17 from MTGJSON's set list against `data/cards/`. Re-derive the missing
list by writing the set list as a deck (`1 Name` per line) and running `pawl
deck` on it: every unresolved name is reported.

## Expressible today

Each row names the pool card(s) whose file is the closest template. A row
leaves this table when its card is added to `data/cards/`.

| Card | Template card(s) | Note |
|---|---|---|
| Devastation | day-of-judgment | Destroy EachMatching Or(creature, land) |
| Dread Charge | space-beleren | ForbidBeingBlocked UntilEndOfTurn, affected And(black creature, you control), blockers Not black (live Filter) |
| Dread Reaper | thragtusk | SelfEnters LoseLife 5 you; Flying |
| Dry Spell | molten-disaster | DealDamage parts: each creature, each player, 1 |
| Déjà Vu | regrowth | filter HasCardType Sorcery |
| Earthquake | molten-disaster | exact line (drop split second) |
| Ebon Dragon | ravenous-rats + midnight-scavengers | optionality Optional on the discard clause; Flying |
| Elven Cache | regrowth | exact line |
| Final Strike | fling + chandra-fire-artisan | additional cost sacrifice creature; target AnyTarget filter Or(IsPlayer Opponent, Planeswalker) |
| Fire Dragon | skred / koth-fire-of-resistance | SelfEnters, damage = count Mountains you control |
| Fire Imp | electros-bolt | SelfEnters, 2 damage to target creature |
| Fire Snake | endless-cockroaches + vandalize | SelfDies, Destroy target land |
| Fire Tempest | molten-disaster | 6 to each creature and each player |
| Flashfires | boil | HasSubtype Plains |
| Fleet-Footed Monk | chomping-kavu | CantBeBlockedBy blockers power AtLeast 2 |
| Fruition | blessed-reversal | GainLife Count Forests on the battlefield |
| Gift of Estates | oreskos-explorer | ControlsMoreThanYou over players as a clause condition; Search up to 3 Plains, RevealThenHand |
| Gravedigger | midnight-scavengers | drop the mana-value clause of the filter |
| Hand of Death | doom-blade | exact line |
| Harsh Justice | rally-the-troops + false-cure + teysa-envoy-of-ghosts + stuffy-doll | ArmDelayedTrigger UntilEndOfTurn; PermanentDealsCombatDamageToPlayer filter attacking creature, recipient You (binds combatDamager, eventAmount); DealDamage dealer = damager slot, quantity `thatMuch`, ref ControllerOfBound damager. Verify the damager slot's wire name |
| Howling Fury | hatred | +4/+0 literal |
| Hulking Cyclops | villainous-ogre | CantBlock self |
| Hulking Goblin | villainous-ogre | CantBlock self |
| Hurricane | molten-disaster + corrosive-gale | X to each creature with flying and each player |
| Ingenious Thief | the-ravens-warning | SelfEnters, LookAt EachCardInHand of target player; Flying |
| Jungle Lion | villainous-ogre | CantBlock self |
| Lava Axe | goblin-war-strike | PlayersAndPlaneswalkers, 5 |
| Lava Flow | grounded-for-life | Permanents pool filter Or(creature, land) |
| Man-o'-War | unsummon + radiant-fountain | SelfEnters bounce target creature |
| Mercenary Knight | lithophage + selhoff-entomber | SelfEnters; Sacrifice self with payGate IfNotPaid, cost DiscardCards 1 creature card |
| Mind Knives | hymn-to-tourach + duress | RandomCardInHand count 1; target filter IsPlayer Opponent |
| Mobilize | rally-the-troops | exact line |
| Monstrous Growth | giant-growth | +4/+4 |
| Mystic Denial | essence-scatter | filter Or(creature, sorcery) |
| Natural Order | fling + enduring-ideal | additional Sacrifice whichPermanents green creature; Search green creature to Battlefield |
| Natural Spring | braingeyser (target player) + cram-session | GainLife 8 to InSlot target |
| Nature's Cloak | piety-charm | GainKeyword Landwalk(Forest) over EachMatching green creatures you control |
| Nature's Ruin | day-of-judgment | filter green creatures |
| Needle Storm | corrosive-gale | literal 4 |
| Omen | ponder | exact text |
| Owl Familiar | sorcerer-class | SelfEnters Draw 1, Discard Counted 1; Flying |
| Path of Peace | swords-to-plowshares | Destroy; GainLife 4 to OwnerOfBound (timmerian-fiends uses OwnerOfBound) |
| Personal Tutor | mystical-tutor | filter Sorcery, RevealThenTop |
| Phantom Warrior | wormfang-crab | its "can't be blocked" line only |
| Pillaging Horde | browbeat (NoneTaken) + hymn-to-tourach | clause 0 Optional Discard RandomCardInHand you; clause 1 ifTaken NoneTaken[0] Sacrifice self. No pool cost component discards at random, so the "unless" is the optional-clause form |
| Plant Elemental | lithophage | SelfEnters; payGate sacrifice 1 Forest |
| Primeval Force | lithophage + phyrexian-tribute | payGate sacrifice Fixed 3 Forests |
| Prosperity | vision-skeins + braingeyser | Draw AnyPlayer, quantity X |
| Pyroclasm | astral-arena | DealDamage 2 EachMatching creature |
| Rain of Salt | ley-weaver + vandalize | target count least 2 most 2, lands |
| Rain of Tears | vandalize | Destroy target land |
| Renewing Dawn | gideon-jura + blessed-reversal | Times factor 2 over Count Mountains ControlledByBound target |
| Sacred Knight | otarian-juggernaut | CantBeBlockedBy blockers Or(HasColor Black, HasColor Red) |
| Sacred Nectar | cram-session | GainLife 4 |
| Scorching Spear | flame-jab | 1, any target |
| Scorching Winds | rally-the-troops + astral-arena | 1 damage EachMatching attacking creature |
| Seasoned Marshal | sensational-spider-man + midnight-scavengers | SelfAttacks, Optional Tap target creature |
| Serpent Assassin | doom-blade + midnight-scavengers | SelfEnters, Optional Destroy target nonblack |
| Serpent Warrior | thragtusk | SelfEnters LoseLife 3 |
| Sorcerous Sight | the-ravens-warning + duress | LookAt EachCardInHand of target opponent; Draw 1 |
| Soul Shred | parasitic-grasp | nonblack filter instead of Human |
| Spiritual Guardian | thragtusk | GainLife 4 |
| Spitting Earth | skred | count Mountains you control |
| Starlight | gideon-jura + blessed-reversal | Times factor 3 over Count black creatures ControlledByBound target |
| Steadfastness | steeling-stance | +0/+3 |
| Stone Rain | vandalize | Destroy target land |
| Summer Bloom | sea-gate-restoration-sea-gate-reborn + azusa-lost-but-seeking | AffectPlayers UntilEndOfTurn, You, PlayAdditionalLands Additional 3 (landPlaysAllowed reads it live). No pool card yet installs this PlayerEffect from a resolution |
| Sylvan Tutor | mystical-tutor | creature filter |
| Symbol of Unsummoning | unsummon + divination | exact lines |
| Thing from the Deep | lithophage + patron-of-the-akki | SelfAttacks; payGate sacrifice 1 Island |
| Theft of Dreams | winged-portent + gideon-jura | Count And(creature, IsTapped, ControlledByBound target) |
| Thundering Wurm | lithophage + selhoff-entomber | payGate DiscardCards 1 land card |
| Thundermare | rally-the-troops + radiant-fountain | SelfEnters Tap EachMatching And(creature, Not IsSource); Haste |
| Tidal Surge | moonshae-pixie-pixie-dust + a-good-day-to-pie | count least 0 most 3, filter Not Flying, Tap |
| Time Ebb | griptide | exact line |
| Touch of Brilliance | divination | exact line |
| Treetop Defense | rally-the-troops + piety-charm | GainKeyword Reach over creatures you control |
| Undying Beast | endless-cockroaches + griptide | SelfDies, MoveToZone `became` to Library placement Stated Top |
| Untamed Wilds | rampant-growth | destination Battlefield (natures-lore) instead of BattlefieldTapped |
| Valorous Charge | steeling-stance | EachMatching And(creature, HasColor White) (all controllers), +2/+0 |
| Vampiric Feast | parasitic-grasp | AnyTarget, 4 and gain 4 |
| Vampiric Touch | chandra-fire-artisan + parasitic-grasp | opponent-or-planeswalker filter; 2 and gain 2 |
| Venerable Monk | radiant-fountain | exact line |
| Vengeance | gideon-jura | Destroy target creature filter IsTapped |
| Virtue's Ruin | day-of-judgment | filter white creatures |
| Volcanic Hammer | lightning-bolt | exact line |
| Warrior's Charge | steeling-stance | exact line |
| Wicked Pact | fulgent-distraction + doom-blade | count least 2 most 2, nonblack; LoseLife 5 |
| Winter's Grasp | vandalize | Destroy target land |
| Withering Gaze | duress + sudden-impact | as Baleful Stare with Forest / green |
| Wood Elves | natures-lore + radiant-fountain | SelfEnters Search Forest to Battlefield |
| Wrath of God | day-of-judgment + terror | regenerability CantBeRegenerated |

## Needs a capability

Each group is tracked by its issue; its cards are added when it lands.

### Activation window "during your turn, before attackers are declared" (#5234)
ActivationRestriction has DuringPhase (one PhaseSelector), DuringTurn,
BeforeCombatDamage, BeforeEndStep and so on; its list is a conjunction, so it
can't say "beginning phase, precombat main or beginning of combat, on your turn".
No pool card prints the rider (grepped oracleText for "before attackers are
declared").
- Capricious Sorcerer: "{T}: deals 1 damage to any target. Activate only during your turn, before attackers are declared."
- King's Assassin: "{T}: Destroy target tapped creature. Activate only ..." (gideon-jura has the tapped filter)
- Stern Marshal: "{T}: Target creature gets +2/+2 until end of turn. Activate only ..."

### A creature can't be blocked by more than one creature (CR 509.1b) (#4790)
CombatRestriction's CantBeBlockedBy takes a blocker Filter; CantBlockMoreThan
bounds the whole declaration. Nothing bounds blockers per attacker.
- Charging Rhino, Stalking Tiger: "This creature can't be blocked by more than one creature."

### Damage divided among targets at announcement (CR 601.2d) (#5235)
DealDamage parts take fixed quantities per ref. No pool card divides damage
(grepped oracleText "divided"). CounterSpread/DistributeCounters divide counters only.
- Forked Lightning: "deals 4 damage divided as you choose among one, two, or three target creatures."

### Tutor to the top without revealing (#5236)
SearchDestination has RevealThenTop (Mystical Tutor) and no unrevealed
shuffle-then-top arm (Vampiric Tutor's shape, not in the pool).
- Cruel Tutor: "Search your library for a card, then shuffle and put that card on top. You lose 2 life."

### Skip all combat phases of target player's NEXT TURN (#5237)
SkipNextPhase (stonehorn-dignitary) skips the player's next combat phase. That
diverges when False Peace targets its caster before their own combat (it skips
this turn's combat, not next turn's), and when a turn has extra combats.
- False Peace: "Target player skips all combat phases of their next turn."

### "Each opponent discards a card" without targeting (#5238)
Discard.Counted (CountedDiscard) names ONE player slot. PlayerSacrifices takes
`players` Relative Opponent, but Discard has no group arm. No pool card prints
"each opponent discards a card".
- Noxious Toad: "When this creature dies, each opponent discards a card."

### A per-player "may draw up to N" with a per-player follow-up (#5239)
ChooseNumber has no chooser, and Repeat/ForEach/ForEachNumber don't loop over
players with each one choosing.
- Temporary Truce: "Each player may draw up to two cards. For each card less than two a player draws this way, that player gains 2 life."

### "That many" after cards are shuffled away (#5240)
ShuffleIntoLibrary has no slot for the moved cards (fields `library`, `refs`),
and a Count read after the shuffle sees an empty hand. timetwister draws a
literal 7, and flux binds `discarded`, which a shuffle can't.
- Winds of Change: "Each player shuffles the cards from their hand into their library, then draws that many cards."

### A spell's rules-modifying effect over a live set of objects (CR 611.2c second sentence) (#5241)
The resolution-created carriers take an ObjectRef, which freezes the set when
the spell resolves. CR 611.2c says an effect that doesn't modify
characteristics can affect objects that arrive later. RequireAttack has a
RestrictedCreatures.Matching arm for this; RequireBlock and DoesNotUntapNext
don't (every pool use of DoesNotUntapNext is InSlot).
- Alluring Scent: "All creatures able to block target creature this turn do so." RequireBlock (lineprancers) needs a Matching blocker side. BlockRequirement's haddock already names Alluring Scent as the "Nothing subject" shape, but that is the static carrier.
- Exhaustion: "Creatures and lands target opponent controls don't untap during their next untap step." DoesNotUntapNext needs a filter arm (ControlledByBound target, Or(creature, land)). Freezing at resolution misses a permanent that comes under that player's control before their untap step.

### The caster orders another player's library cards (#5243)
ArrangeInLibrary asks the cards' owner (CR 401.4), but "in any order" on a
spell that reorders an opponent's library is the caster's choice (Portent's
ruling). Ponder and Tome of the Infinite only reorder their caster's own.
- Cruel Fate: "Look at the top five cards of target opponent's library. Put one of those cards into that player's graveyard and the rest on top of their library in any order."
