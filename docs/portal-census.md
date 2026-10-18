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
