# Decisions

Every behaviour parun commits to that nothing official forces: a question the
CR leaves undefined, ambiguous, or open to more than one reading, and no
Gatherer ruling or erratum settles. Each entry records the reading chosen so
nobody re-derives it, possibly differently, and names the rules it rests on so
a new CR can be checked against it.

An entry is owed whenever a change picks such a reading, and only when both
hold: the readings are observable, giving different game states or different
legal choices on some legal board, and nothing official picks one. It lands in
the same PR as the code, and the code site cites it by heading. Three things
are not entries: a reading the CR or an official ruling forces, whose code site
cites that rule or ruling; an implementation choice no legal board can tell
apart from the alternative; and an elision, which is a known gap with an issue
rather than a settled answer.

When `docs/rules.txt` is updated, or a ruling lands on a question here,
re-read each entry against the new text. An entry it decides is either
confirmed, and dropped from here, or contradicted, and filed as
`rules-correctness`.

Each entry gives:

- **Question**: what the rules leave open.
- **Rules**: the CR rules read, and the CR date they were read against.
- **Decision**: the reading parun takes.
- **Rejected**: the other readings, and why each lost.
- **Site**: the code that implements it, and the test that proves it.
- **Issue**: where it was decided.

Entries are ordered by the first rule each cites.

## Whether a merged copy of a mutating spell is a token

- **Question**: A copy of a mutating creature spell merges with its target
  instead of entering. CR 111.13 and 707.10f make the copy a token "as it
  resolves"; CR 608.3f does so only "as it is put onto the battlefield". Is
  the merged component a token?
- **Rules**: CR 111.13, 608.3f, 702.140c, 707.10f, 730.2d; CR of 2026-08-07.
- **Decision**: It is not a token. CR 702.140c's merge never puts it onto the
  battlefield, so CR 608.3f never confers token-ness.
- **Rejected**: Making it a token, on CR 111.13 and 707.10f's unconditional
  "as it resolves".
- **Site**: `Parun.Engine.Game.componentIsToken`'s `OfSpellCopy` arm, proved by
  `Parun.MutateSpec`'s "CR 730.2d/608.3f a merged permanent whose topmost
  component is a spell copy is no token".
- **Issue**: none.

## Who says which new target takes a replaced target's part of a division

- **Question**: CR 115.7f keeps a divided spell's division through a change of
  targets. When two or more replaced targets held different parts, which new
  target takes which part?
- **Rules**: CR 115.7a, 115.7d, 115.7f, 601.2d; CR of 2026-08-07.
- **Decision**: The player changing the targets hands the replaced parts out
  among the new targets, each new target taking exactly one of them; a target
  left unchanged keeps its own. Where the replaced parts are all equal nobody
  is asked.
- **Rejected**: Pairing by some engine order, which makes the changer's choice
  for them; re-dividing the replaced total freely, which changes the division
  CR 115.7f forbids.
- **Site**: Parun.Engine.Resolve.Common's reaimDivisions;
  data/scenarios/divide's Redirect case.
- **Issue**: #5235.

## Whether a concession restarts the pass count

- **Question**: CR 117.4 resolves the top object once all players pass in
  succession "without taking any actions in between". When the priority
  holder concedes and priority moves on (CR 800.4a), do earlier passes still
  count?
- **Rules**: CR 117.4, 104.3a, 117.3d, 800.4a; CR of 2026-08-07.
- **Decision**: No. The pass set empties and priority goes to the next seat
  still playing.
- **Rejected**: Keeping the passes: it can resolve a spell a player would
  have answered after the board changed.
- **Site**: `Parun.Engine.Engine.priorityLoop`, the `Concession.Concedes` arm,
  proved by `Parun.GameSpec`'s "CR 800.4a/117.4 priority after a concede goes
  to the next seat, and the pass cycle restarts".
- **Issue**: #143.

## How a hybrid Phyrexian symbol in a cost reduction reduces

- **Question**: A reduction written `{G/U/P}`. CR 118.7f gives a Phyrexian
  reduction one mana of that symbol's colour, but CR 107.4f makes a hybrid
  Phyrexian symbol both colours. Which colour, and is the 2 life a half?
- **Rules**: CR 118.7f, 107.4f, 118.7e, 601.2f; CR of 2026-08-07.
- **Decision**: The payer picks one of the two colours at CR 601.2f, CR
  118.7e's mechanism. The 2 life is no half.
- **Rejected**: Reducing nothing: matches no reading. The engine picking: the
  choice is the payer's. A life half: no rule reduces a cost by life.
- **Site**: `Parun.Engine.Cost.reductionHalvesOf`, proved by
  `Parun.PlayerEffectSpec`'s "CR 118.7e a hybrid Phyrexian reduction offers its
  two colours" and the `data/scenarios/player-effect/cr-118-7e-*g-u-p*`
  scenarios.
- **Issue**: #1995.

## Whether one instruction naming a recipient twice deals one damage event

- **Question**: Char aimed at its own caster deals 4 and 2 to one player. Is
  that two damage events or one of 6? CR 615.10's per-event floor observes it.
- **Rules**: CR 120.4, 608.2f, 615.7, 615.10, 701.14c; CR of 2026-08-07.
- **Decision**: One event per recipient, source and moment; the amounts sum.
- **Rejected**: Two events, which applies CR 615.10 twice. Merging in
  `applyDamage`: combat and fights have several dealers.
- **Site**: `Parun.Engine.Replacement.oneEventPerRecipient`, proved by
  `Parun.DamageReplacementSpec`'s "CR 120.4 one sentence naming alice twice
  deals her ONE event, of 6".
- **Issue**: #2586.

## Whether "each creature and each planeswalker" reaches a permanent twice

- **Question**: Magmaquake deals X damage "to each creature without flying
  and each planeswalker". A creature planeswalker without flying is in both
  sets: is it dealt X, or 2X as Char's caster is dealt both amounts?
- **Rules**: CR 120.1, 120.3c, 120.3e, 120.4, 608.2f; CR of 2026-08-07.
- **Decision**: X. One damage instruction over a union of descriptions
  ("each Y and each Z") deals its amount once to each object matching either
  or both; two instructions ("Deal X to each Y. Deal X to each Z.") deal it
  twice. This governs every "damage to each creature and each planeswalker"
  card (Hour of Devastation, Storm's Wrath, Star of Extinction). No ruling
  forces it; the counting rulings read a union the same way: Asari Captain ("A
  creature that is both a Samurai and a Warrior is only counted once"), Aysen
  Crusader ("A permanent with both creature types is counted only once"),
  Chaotic Backlash and Kithkin Zealot ("Each permanent is counted only once"),
  Royal Decree (once per permanent "even if that permanent meets multiple
  criteria").
- **Rejected**: 2X, one amount per description summed per recipient: Char
  names its recipients by two different amounts, where one amount over a
  union names each member once. War Report's "Each artifact creature on the
  battlefield is counted twice" is the contrast: there two counts are added.
- **Site**: `data/cards/magmaquake.json`, one damage part over an `Or`
  filter. The scenario "CR 120.3c/120.3e: Magmaquake deals a creature
  planeswalker without flying X once, not once per description" proves it on
  a Chandra Nalaar that Liquimetal Coating and March of the Machines animate.
- **Issue**: none.

## Where a name sticker's word goes beside a blank

- **Question**: A name with a blank line (Wolf in _____ Clothing). The blank
  is not a word, so a word placed after k words could go either side of a
  blank that follows word k.
- **Rules**: CR 123.6a, 123.6b, 123.6c; CR of 2026-08-07.
- **Decision**: The blank stays, counts for nothing, and the word goes before
  it: Wolf in Otter _____ Clothing.
- **Rejected**: not recorded.
- **Site**: `Parun.Engine.NameWords.insertAfter`, proved by
  `Parun.StickerSpec`'s "CR 123.6a Wolf in _____ Clothing offers four
  positions, and the word goes before a following blank".
- **Issue**: #4900.

## What the greatest value is over an empty or undeterminable set

- **Question**: What is "the greatest X among ..." over an empty set, or when
  some member's value cannot be determined?
- **Rules**: CR 208.2a, 608.2h, 714.2d; CR of 2026-08-07.
- **Decision**: Undetermined in both cases. Wherever a number is consumed,
  CR 208.2a's characteristic-defining ability among them, that becomes 0, so
  only a condition sees the difference. A total over an empty set is 0.
- **Rejected**: 0 for an empty set: no rule gives a maximum over nothing a
  value, and the CR legislates 0 case by case (CR 714.2d). Dropping
  undeterminable members: that is the maximum of a set the card never named.
- **Site**: `Parun.Engine.Count.aggregate`'s `Aggregation.Greatest` arm, proved
  by `Parun.CountSpec`'s "CR 208.2a Greatest over an EMPTY matched set is
  Nothing, not 0" and "a member whose quantity cannot be determined makes the
  whole maximum Nothing".
- **Issue**: none.

## When a target drawn out of a face-down pile is revealed, and for how long

- **Question**: CR 406.4 says a card drawn at random out of a face-down pile
  while casting a spell or activating an ability "isn't revealed until after
  that cost is fully paid". No rule orders the reveal, and CR 701.20a gives it
  no duration.
- **Rules**: CR 406.4, 406.3, 601.2h, 601.2i, 602.2b, 608.2b, 701.20a; CR of
  2026-08-07.
- **Decision**: Once the cost is paid and the spell becomes cast (CR 601.2i),
  or the ability becomes activated (CR 602.2b), the caster reveals the drawn
  card to every player. It stays revealed until the spell or ability leaves
  the stack, CR 701.20a's duration for a card revealed as part of casting or
  activating, so the table can check the target as it resolves (CR 608.2b).
  Until then nobody sees it, the caster included.
- **Rejected**: No reveal at all, reading the sentence as forbidding only an
  early one (owner, 2026-10-21). A momentary reveal, the `Revealed` event
  alone: the reveal lets the table follow the target, which matters until it
  resolves. Revealed until it leaves exile, as CR 406.3's lasting look: a
  reveal is not an instruction letting a player look, and the card would stay
  public after the spell is gone.
- **Site**: `Parun.Engine.Cast.castProposed` and
  `Parun.Engine.Activate.activateAbilityWith`, revealing what
  `Parun.Engine.Target.chooseTargets` drew; proved by `Parun.ExileSpec`'s "CR
  406.4 the card drawn for a spell's target is hidden while it is paid for,
  and revealed to both seats once cast" and its activation twin.
- **Issue**: #2568.

## Who on a winning team takes the ante

- **Question**: CR 407.2 gives the ante to "the winner", but a team win (CR
  104.2c) makes several winners, and CR 805.2's primary player exists only
  under the shared team turns option.
- **Rules**: CR 407.2, 104.2c, 805.2; CR of 2026-08-07.
- **Decision**: The team chooses card by card, and its first seat still
  playing speaks for it. Not asked for a team of one.
- **Rejected**: not recorded.
- **Site**: `Parun.Engine.Ante.payOut`, proved by the scenario "CR 407.2 /
  104.2c the winning team's primary player shares out the ante".
- **Issue**: none.

## Which combat phase ends a duration until combat on your next turn

- **Question**: Brazen Cannonade's "until end of combat on your next turn",
  when CR 500.8 allows a turn several combat phases or none.
- **Rules**: CR 500.8, 500.5a, 511.2, 611.2a, 800.4m; CR of 2026-08-07.
- **Decision**: The first combat phase to end on that player's next turn;
  with none, that turn's cleanup.
- **Rejected**: The first combat phase anywhere, an opponent's included.
  Carrying it to a later turn of theirs.
- **Site**: `Parun.Engine.Expiry`'s `AtEndOfCombatOn` drop arm, proved by
  `Parun.ExpirySpec`'s "CR 500.5a / 500.8 only a combat PHASE of a later turn
  of that player ends it" and "CR 611.2a a next turn with no combat phase
  takes it at its cleanup".
- **Issue**: #525.

## An untap cap leaves tapped only what it must

- **Question**: Static Orb says players "can't untap more than two
  permanents during their untap steps". May the active player untap fewer
  than the caps allow? And does a stunned permanent they choose count
  against a cap, though its stun counter takes the untap?
- **Rules**: CR 502.3, 101.2, 122.1d, 614.6; CR of 2026-08-07.
- **Decision**: The answer must be maximal. Every tapped permanent the caps
  still allow, given the others chosen, untaps. A permanent stays tapped
  only when an effect keeps it tapped, which CR 502.3 makes the default for
  the rest. A stunned permanent chosen to untap counts against the cap. The
  cap limits CR 502.3's determination, and CR 122.1d's replacement applies to
  the untap that determination produces (CR 614.6).
- **Rejected**: Letting the player untap fewer, which would make a cap
  read as "may untap up to two". Leaving a stunned permanent out of the
  count, which would let the player untap more than the cap names by
  choosing one.
- **Site**: `Parun.Engine.UntapRestriction.settle`, called from
  `Parun.Engine.Engine.untapAll`. The Static Orb and Winter Orb scenarios
  under `data/scenarios/untap-restriction/` prove it.
- **Issue**: #5531.

## Which draw is the first one drawn in a draw step

- **Question**: Chains of Mephistopheles and Alhammarret's Archive except
  "the first one [they/you] draw in each of [their/your] draw steps". Chains'
  ruling exempts "a player's normal card draw on their turn"; Archive has no
  such ruling. Does Archive's identical wording read the same? And is the
  draw Zur's Weirding leaves its drawer when nobody pays ("Otherwise, that
  player draws a card") still the normal draw?
- **Rules**: CR 504.1, 121.1, 614.5, 614.6; CR of 2026-08-07.
- **Decision**: The exempt draw is the drawer's own CR 504.1 draw, on both
  cards. Zur's Weirding's unpaid draw is that same draw left standing (its
  ruling lets a dredger replace it), so it stays exempt. A dredged normal
  draw still uses the exemption up.
- **Rejected**: Counting the cards actually drawn, which Archive's text alone
  would allow: alice dredges her normal draw and Howling Mine's draw is then
  the first she draws, drawing one card where parun draws two; and wording
  Wizards ruled on for one card is read differently on its twin. Making Zur's
  unpaid draw a new draw, which would let Chains take a normal draw nobody
  paid to stop.
- **Site**: `Parun.Engine.Replacement.matchesPrinted`'s `DrawR` arm and
  `Parun.Engine.Event.apply`'s `OthersMayPayLife` arm. The scenarios
  `cr-504-1-chains-of-mephistopheles-takes-alice-s-think-twice-draw-after-she-dredged-her-normal-draw`
  and
  `cr-504-1-zur-s-weirding-s-unpaid-draw-is-alice-s-normal-draw-so-chains-of-mephistopheles-spares-it`
  prove it.
- **Issue**: #4781.

## Who may block a creature attacking nothing

- **Question**: CR 506.4c's creature, its planeswalker or battle removed from
  combat, attacks nothing but "may be blocked". CR 802.4a lets a player block
  only creatures attacking them, their planeswalker or their battle. With
  several defending players, which may block it?
- **Rules**: CR 506.4c, 509.1a, 802.2a, 802.4a, 802.4b; CR of 2026-08-07.
- **Decision**: Only the player it attacked before the removal: the
  planeswalker's controller or the battle's protector, extending CR 802.2a's
  "before it was removed from combat" by analogy.
- **Rejected**: Every defending player: under CR 802.4b's separate judging,
  two players could block it at once. Nobody: contradicts CR 506.4c.
- **Site**: `Parun.Engine.Combat.attackersOn`, proved by
  `Parun.PlaneswalkerCombatSpec`'s "CR 802.4a once the planeswalker is gone,
  only ITS controller may block the creature attacking nothing".
- **Issue**: #2899.

## Which creatures could have attacked

- **Question**: Season of the Witch spares "creatures that couldn't attack";
  its ruling reads that as could not have been declared as an attacker in
  that turn's declare attackers step. Is a creature that could attack only by
  paying a cost to attack, payable or not, one that couldn't?
- **Rules**: CR 508.1, 508.1c, 508.1d, 508.1h, 508.1j; CR of 2026-08-07.
- **Decision**: No. A creature could have attacked when some declaration
  obeying CR 508.1a-d contains it, costs aside: CR 508.1d excuses the cost
  without forbidding the attack, and CR 508.1h asks for it only after the
  creature is chosen. Asked as each declaration begins, over every declare
  attackers step of the turn.
- **Rejected**: Counting a creature as unable when its cost is unpayable:
  payability turns on mana abilities CR 508.1i offers only after the
  creatures are chosen. Counting every taxed creature as unable: CR 508.1d
  makes paying optional, not impossible.
- **Site**: `Parun.Engine.Combat.couldAttack`, proved by data/scenarios/combat's
  "CR 508.1d Season of the Witch destroys creatures that could have attacked
  only by paying a cost".
- **Issue**: #5441.

## When a face-down creature Illusionary Mask cast turns face up in combat

- **Question**: Illusionary Mask turns its face-down creature face up when it
  "would assign" combat damage. CR 510.1 has the attacking player announce
  every attacker's assignment before the defending player announces the
  blockers'. Does a face-down blocker turn up before the attackers assign, so
  a trampler must assign lethal damage to the face-up creature?
- **Rules**: CR 510.1, 510.1c, 510.1d, 614.1a, 702.19b; CR of 2026-08-07.
- **Decision**: As its own assignment comes up, in CR 510.1's order. An
  attacker blocked by a face-down creature assigns against the 2/2; the
  blocker turns face up when its controller announces, and assigns as the
  face-up creature.
- **Rejected**: Turning every such creature face up when the combat damage
  step begins: the event replaced is the creature's own assignment, which has
  not happened while the attackers assign.
- **Site**: `Parun.Engine.Damage.turnUpToAssign`, proved by
  data/scenarios/face-down's "CR 510.1 a Craw Wurm Illusionary Mask cast face
  down turns face up to assign its 6 as it blocks". The trampler half is a
  regression fence: no board drives it.
- **Issue**: #5440.

## Whether Cunning Giant attacking nothing may still assign to a creature

- **Question**: Cunning Giant, unblocked, "may ... assign its combat damage to
  a creature defending player controls". Attacking a planeswalker that has
  left, it attacks nothing and CR 510.1b gives it no recipient. Is the option
  still open, and does Illusionary Mask's "would assign" count a creature
  whose option could give it a recipient?
- **Rules**: CR 510.1b, 506.4c, 508.5, 614.1a; CR of 2026-08-07.
- **Decision**: Yes to both. The option names its own recipient, and CR
  508.5's second sentence still names the defending player, so it stands
  apart from what the creature is attacking. A creature whose option could
  give it a recipient is one that would assign, its controller having yet to
  decline.
- **Rejected**: Closing the option with CR 510.1b: the text is a permission
  to assign elsewhere, not a reading of what the creature attacks. Leaving
  the Mask's creature face down: a later "yes" would then have it assign as
  the face-down 2/2.
- **Site**: `Parun.Engine.Damage.attackerAssignment` and `wouldAssign`. Both
  halves are regression fences: no board drives either.
- **Issue**: #5437.

## Whether a cast redirected off the stack is still a cast

- **Question**: A CR 614 replacement sends a card being cast somewhere other
  than the stack (Synthetic Stack Interdiction). Does the cast rewind, stop,
  or complete?
- **Rules**: CR 601.2i, 601.2a, 601.2e, 614.6, 709.3a, 709.4; CR of
  2026-08-07.
- **Decision**: Only the arrival is replaced. CR 601.2b-i run on: targets
  chosen, costs paid, and the spell becomes cast, so "whenever you cast"
  triggers fire. The card shows CR 709.4's combined view where it lands.
- **Rejected**: Rewinding: CR 601.2e covers only illegal casts. Stopping
  partway: no rule ends a cast midway.
- **Site**: `Parun.Engine.Cast.castSpellWith`, the `Event.changeZoneCasting`
  step, proved by `Parun.CastRestrictionSpec`'s "CR 601.2i a cast redirected
  off the stack is still a cast" and "CR 709.4 a cast redirected off the stack
  keeps both halves".
- **Issue**: none; #781 settled the face ordering beside it.

## Whether a trigger limit differs from a first-time-each-turn trigger

- **Question**: Neither "this ability triggers only once each turn" nor "for
  the first time each turn" has a rule. Does an ability gained after the
  turn's first matching event still trigger?
- **Rules**: CR 603.2c, 603.2h, 702.179d; CR of 2026-08-07.
- **Decision**: "Triggers only once each turn" (`TriggerLimit`) counts the
  ability's own triggerings, so a late-gained ability still triggers once.
  "For the first time each turn" (`TriggerFrequency`) narrows the event, so
  it never does.
- **Rejected**: Reading them as synonyms: the gained-late case tells them
  apart.
- **Site**: `Parun.Types.TriggerLimit` and `Parun.Types.TriggerFrequency`;
  `Parun.SpeedSpec`'s "CR 702.179d an ability gained after the turn's first
  life loss still triggers once" proves the gained-late case.
- **Issue**: none.

## Whether conjuring a card is a zone change

- **Question**: Alchemy's conjure creates a card in a zone, and no CR rule
  covers it. Is that arrival a zone change, so that a "put into a graveyard
  from anywhere" trigger or a replacement sees a card conjured into a
  graveyard?
- **Rules**: CR 603.6, 111.2, 400.6, 400.11, 400.11c, 603.6a, 603.6c, 616.1;
  no rule names conjure; CR of 2026-08-07.
- **Decision**: It is not a zone change. The card is minted straight into the
  zone, the way a wish brings in a card from outside the game. An arrival on
  the battlefield is still an entry, by analogy with a token: it runs the CR
  616.1 loop and the CR 603.6a scan.
- **Rejected**: A zone change, which needs a `from` zone a creation lacks and
  would announce a departure from a zone the card was never in.
- **Site**: `Parun.Engine.Event.mintCard`, reached from
  `Parun.Engine.Resolve.Arms.Objects`'s `Effect.Conjure` arm, proved by
  `Parun.ConjureSpec`'s "CR 603.6 a conjure into a graveyard is no zone change,
  so a graveyard trigger does not see it".
- **Issue**: #2809.

## What counts as an instruction having happened

- **Question**: CR 603.12's "when you do" and CR 118.12's "if you do" ask
  whether an instruction happened, and the CR does not define the test.
- **Rules**: CR 603.12, 118.12; CR of 2026-08-07.
- **Decision**: It happened if it recorded a game event or changed any state
  but bookkeeping. Bookkeeping is whatever an instruction that did not happen
  can still write (event-log samples, allocators, the last choice, a draw from
  an empty library, a shortfall, exile-link prunes, bound zero amounts, vote
  tallies), and is copied across from the state before. Not covered, because
  rulings settle them for CR 603.12: an "any number" choice, which happened
  even at zero, and a draw or mill finding too few cards, which did not.
- **Rejected**: An allow-list of state that counts, the earlier event-log
  reading, which misses every state-only instruction writing a field it does
  not name.
- **Site**: `Parun.Engine.Resolve.Common.happenedBetween`, with the two ruled
  shapes in `applyClauseEffects`'s `instructionDone`. The state half is
  proved by the scenario "CR 603.12 a choice that records no event still arms
  its when you do". Copies proved: `exiledWith` by "CR 603.12 an empty mill
  after a token ceased in exile arms no reflexive", `exilePiles` by "CR 603.12
  an empty mill after a face-down card left exile arms no reflexive",
  `nextTimestamp` by "CR 701.28e / 603.12 an ignored convert arms no
  reflexive", `nextEventGroup` by `Parun.ResolveSpec`'s "CR 118.12 Victimize
  with no creature to sacrifice returns nothing". The other copies are a
  regression fence.
- **Issue**: none.

## Whether an ability a merge grafts is still characteristic-defining

- **Question**: CR 702.140e gives a mutated permanent every component's
  abilities. Is a component's characteristic-defining ability, such as
  Tarmogoyf's power and toughness, still one on the merged permanent (layer
  7a), or a plain static ability (layer 7b, in timestamp order)?
- **Rules**: CR 604.3a, 613.2a, 613.4a, 613.4b, 613.7a, 702.140e, 730.2a; CR
  of 2026-08-07.
- **Decision**: It stays characteristic-defining. CR 604.3a(2)'s copy-effect
  clause is read as reaching CR 730.2a's merge, which is a copiable effect
  applied beside copy effects in layer 1a (CR 613.2a); the ability is also
  printed on a card that represents the permanent.
- **Rejected**: A plain static ability, on CR 604.3a(2) naming only a copy
  effect and the card the ability affects. It would apply in layer 7b with
  CR 613.7a's timestamp, so an earlier base-setting effect would lose to it.
  It would also split a grafted P/T ability from a grafted changeling or
  devoid, which parun already treats as characteristic-defining.
- **Site**: `Parun.Engine.Projection.View.withMergedAbilities`, proved by
  `Parun.MutateSpec`'s "CR 702.140e a Cubwarden merged over or under
  Tarmogoyf keeps its power and toughness ability" and fenced by "CR
  604.3a/613.4a Harmonious Archon's 3/3 outranks the Tarmogoyf ability
  merged under a Cubwarden".
- **Issue**: #5323.

## Whether conjuring into a library is a library move for a mana ability

- **Question**: CR 605.1a disqualifies a mana ability whose effect moves a
  card to or from a library. A conjured card comes from no zone.
- **Rules**: CR 605.1a; no rule names conjure; CR of 2026-08-07.
- **Decision**: The destination decides: conjuring into a library is a
  library move, conjuring anywhere else is not.
- **Rejected**: Nothing moves, since the card was in no zone. It loses
  because a library still gains a card, which is what the clause keeps out
  of mana abilities.
- **Site**: `Parun.Engine.ManaAbility.movesLibraryCard`'s `Effect.Conjure` arm,
  proved by the scenario "CR 605.1a conjuring into a library keeps an ability
  that adds mana off the mana path" on Synthetic Seeded Grove: no printing
  conjures inside an ability that could add mana.
- **Issue**: none.

## When Thieves' Auction's repeated process ends

- **Question**: Thieves' Auction repeats "until all cards exiled this way have
  been chosen". Its 2005 ruling keeps a chosen Aura with nothing to enchant in
  exile, choosable again, and has the rest stay exiled once only such Auras
  are left; its 2004 ruling forbids choosing one at all. When does the
  process stop?
- **Rules**: CR 608.2c, 303.4g; CR of 2026-08-07.
- **Decision**: After a round in which no card is put onto the battlefield.
  Any Aura is offered, per the newer ruling.
- **Rejected**: Repeating while any exiled card is still in exile, which never
  ends once only Auras with nothing to enchant are left. Filtering those Auras
  out of the choice, the 2004 ruling, which the 2005 one supersedes. The
  reading taken ends early in one case: every player in a round choosing an
  Aura with nothing to enchant while a card that could enter is left.
- **Site**: `data/cards/thieves-auction.json`'s RepeatIf condition, proved by
  the scenario "CR 303.4g / Thieves' Auction's 2005 ruling: an Aura chosen
  while there is nothing it can enchant stays exiled".
- **Issue**: none.

## Which board an entry inside a batch collects replacement effects from

- **Question**: When an entry is contained in a CR 608.2f batch, does its CR
  616.1 loop collect from the board as it was before the batch, or from the
  live board?
- **Rules**: CR 608.2f, 614.12, 616.1g; CR of 2026-08-07.
- **Decision**: The live board. The entering object is not on the pre-batch
  board, and a contained event keeps its own footing.
- **Rejected**: The pre-batch board that the batch's other members are judged
  against. CR 616.1g speaks only to the order the two events' effects are
  chosen in, not to which board each collects from.
- **Site**: `Parun.Engine.Event.runEntry`, proved by the scenario "CR 614.12
  a Clone reanimated by a sweep collects its own copy effect from the live
  board".
- **Issue**: none.

## What a spell or ability causes

- **Question**: Sacred Ground, Spiritual Focus and Obstinate Baloth watch for
  "a spell or ability an opponent controls causes" a move or a discard. Does a
  cost paid for it count, a CR 118.12 cost paid as it resolves (Professor
  Onyx's "each opponent may discard a card. If they don't, ..."), or the
  state-based action that follows its damage?
- **Rules**: CR 609.1, 118.12, 601.2h, 602.2b, 704.3; CR of 2026-08-07.
- **Decision**: Only an effect (CR 609.1) of a spell or ability counts, with
  that spell or ability's controller as the effect is performed. A cost,
  CR 118.12's included, a state-based action, a turn-based action and the
  cast itself cause nothing. Guerrilla Tactics' ruling says the cost half for
  a discard: "Only discarding as an effect will trigger the ability." Library
  of Leng's says it of any cost: "costs aren't effects".
- **Rejected**: Counting a cost paid for the spell or ability, which would
  make a stolen land sacrificed to its controller's cost count; crediting
  a state-based action to the spell whose damage led to it, which CR 704.3
  performs on its own when a player would receive priority; and counting
  CR 118.12's resolution cost on the strength of Guerrilla Tactics' other
  ruling, "The second ability will trigger even on an optional discard caused
  by an opponent". An optional discard that is an effect satisfies that
  ruling without the cost reading -- Flux's "discards any number of cards" has
  no "if they do" clause -- and CR 118.12 names the action a cost outright.
- **Site**: `Parun.Engine.Event.causedBy`, `Parun.Engine.Game.causeNow`,
  `Parun.Engine.Resolve.Effect.applyEffectWith` and
  `Parun.Engine.Cost.payComponent`, proved by the `sacred-ground-*` and
  `spiritual-focus-*` scenarios. The `obstinate-baloth-*` scenarios prove
  only whose spell or ability caused the discard.
- **Issue**: #5530.

## Whether "if you can't" holds after doing part of an instruction

- **Question**: Lich's "sacrifice that many nontoken permanents. If you can't,
  you lose the game": does a player who sacrificed some but fewer than that
  many lose? The CR defines no "if you can't", and no ruling on Lich says.
- **Rules**: CR 609.3, 608.2c; CR of 2026-08-07.
- **Decision**: Yes. "If you can't" holds when the named instruction did
  fewer than it named, including none. A sacrifice falling short counts as
  not done for CR 603.12's "when you do" too, as a short draw or mill does.
- **Rejected**: Holding only when nothing was sacrificed, CR 118.12's "started
  to pay" test: "that many" is the instruction, and CR 609.3's "as much as
  possible" is not all of it.
- **Site**: `Parun.Engine.Resolve.ifTakenHolds` and `recordTaken`, fed by
  `Parun.Engine.Resolve.Arms.Zones`'s PlayerSacrifices arm. Proved by the
  scenarios "CR 609.3 Lich sacrificing two of three loses alice the game" and
  "CR 609.3 Lich sacrificing three of three keeps alice in".
- **Issue**: #5442.

## How two only-clauses about spending one mana combine

- **Question**: Two effects each say a mana may be spent "only as though it
  were" a different type. Which types may it be spent as?
- **Rules**: CR 609.4b, 101.2, 613.11; CR of 2026-08-07.
- **Decision**: The union of the clauses' sets, unordered. An "only" clause
  names permitted types rather than saying "can't".
- **Rejected**: Each "only" as a prohibition, which pulls in CR 101.2 and has
  the two clauses forbid each other's types.
- **Site**: `Parun.Engine.Mana.spendableAs`, proved by the scenario "CR 609.4b
  two only-clauses about one red mana each permit their own type" on
  Celestial Dawn and Synthetic Verdant Prism: Celestial Dawn is the one
  printing with such a clause.
- **Issue**: none.

## Whether a condition that cannot be evaluated holds

- **Question**: When a condition's quantity cannot be determined, is it true,
  false or pending?
- **Rules**: CR 611.2b, 208.2a, 603.4, 604.2; CR of 2026-08-07.
- **Decision**: False, CR 611.2b's conservative direction: such a "for as
  long as" ends rather than persists. Each conjunct and disjunct collapses its
  own, so an `All` with an unevaluable conjunct is false.
- **Rejected**: Substituting 0: CR 208.2a is scoped to characteristic-defining
  abilities, which a condition is not.
- **Site**: `Parun.Engine.Condition.holds`, proved by the scenario "CR
  702.100c a Raptor One with the Stars made an enchantment keeps evolve and
  does not evolve", where CR 702.100c agrees with this reading.
- **Issue**: none.

## Which creatures are "those creatures" after a forced attack on a class

- **Question**: Maddening Imp makes "non-Wall creatures the active player
  controls" attack, a rules change that CR 611.2c keeps live over the turn,
  then destroys "each of those creatures that didn't attack this turn". Is
  that the set as the ability resolved, or the class as the end step reads it?
- **Rules**: CR 611.2c, 508.1d, 603.7c, 805.9; CR of 2026-08-07.
- **Decision**: Both: every creature that was in the class as the ability
  resolved, together with every creature in it at the end step, that did not
  attack. A creature the requirement reached at either moment is one of
  "those creatures". "The active player" is the one named as the ability
  resolved (CR 805.9), so the end-step class reads that player, not whoever is
  active then.
- **Rejected**: The set alone spares a creature that came under the active
  player's control later, though the requirement reached it. The class alone
  spares a creature the Imp's controller took after it failed to attack.
- **Site**: `data/cards/maddening-imp.json`'s delayed ability, proved by the
  scenario "CR 611.2c Maddening Imp: alice's non-Wall creatures must attack,
  and each of them that did not is destroyed at the end step, even one bob has
  since taken".
- **Issue**: #5445.

## Colour words a text change reaches

- **Question**: CR 612.2 changes "a Magic color word being used as a color
  word" but lists no positions. Which of a card's colours are such words?
- **Rules**: CR 612.1, 612.2, 105.1, 105.2, 105.4, 107.4, 202.2e, 700.5; CR
  of 2026-08-07.
- **Decision**: Every colour a card writes in words: a filter's colour
  ("black creature", the "black" in "nonblack", protection or hexproof from
  black), a set or added colour ("becomes black", a copy "except it's
  white"), a token's defining colour ("a 1/1 black Rat token"), devotion's
  colour, Drought's "black mana symbol", and mana a card names in words
  ("white mana", "spent as though it were red mana", "unspent green mana").
  Never a mana symbol, so mana an effect produces and every cost keep their
  colour, and never the object's own colour, which comes from its mana cost
  and colour indicator (CR 105.2, 202.2e) rather than from text. "Colorless"
  is no colour (CR 105.4) and so no colour word. Neither is a colour a card
  reaches without naming it: "mana of any color" (CR 609.4b, stored as all
  five, which only that phrase writes) and "protection from each color" (CR
  702.16h, stored under `Filter.Unwritten`) keep every colour.
- **Rejected**: Reaching mana symbols too, on CR 612.1's "words or symbols":
  CR 612.2 limits a colour-word change to words, and the cards' own rulings
  ("It only changes what is printed on the card") describe text. Leaving
  written mana types alone as if they were symbols: Oracle writes them as
  words.
- **Site**: `Parun.Engine.Filter.rewrite`'s HasColor arm and
  `Parun.Engine.Projection.Rewrite`'s rewriteModification, rewriteFace,
  rewriteManaFilter, rewriteCostScale and Devotion arm; proved by the
  `data/scenarios/text-change/` scenarios.
- **Issue**: #4819.

## What a text change reaches inside a keyword

- **Question**: Rule 702 defines what a keyword ability does, and its words
  (afterlife's "white and black Spirit", mobilize's "red Warrior", Aura
  swap's "Aura card") appear on the card only as reminder text. Does CR 612's
  text change reach them?
- **Rules**: CR 612.1, 612.2, 207.2, 207.2a, 702.14a, 702.135a, 702.181a; CR
  of 2026-08-07.
- **Decision**: Only a word the keyword is WRITTEN with: a payload rule 702
  states as a variable, such as landwalk's "[type]", cycling's "[type]",
  protection's and hexproof's quality, champion's object, gift's creature type
  ("Gift a tapped Fish"). Those are rewritten at layer 3 in the keyword
  itself. What the rule writes for itself is untouched, so an evolved
  Ministrant of Obligation still leaves Spirits and a Sleighted Dalkovan
  Packbeasts still makes red Warriors.
- **Rejected**: Rewriting the whole ability as it is minted, the earlier
  reading: CR 612.1 reaches "words or symbols printed on that object", and
  CR 207.2 gives reminder text no game function, so the rule's own words are
  not the card's.
- **Site**: `Parun.Engine.Projection.mintedTriggeredAbilitiesOf` and
  `Parun.Engine.Count.abilitiesOf`, which mint without a swap; proved by the
  scenarios "CR 207.2a / 612.2 a Sleight of Mind on Dalkovan Packbeasts
  leaves its mobilized Warriors red" and "CR 207.2a / 612.2 an evolved
  Ministrant of Obligation still leaves Spirits". Gift's word is
  `Parun.Engine.Filter.rewriteKeyword`'s, proved by `Parun.CounterspellSpec`'s
  "CR 612.2a an Evolution swapping Fish for Elf on a promised Into the Flood
  Maw gives bob a tapped 1/1 blue Elf Token".
- **Issue**: #4819, #5457.

## Which timestamp the suspected designation's abilities have

- **Question**: CR 701.60c's menace and "can't block" come from the rules, so
  neither CR 613.7a nor 613.7b names their timestamp. It matters against an
  ability removal.
- **Rules**: CR 613.7a, 613.1f, 613.7b, 701.60b, 701.60c; CR of 2026-08-07.
- **Decision**: The permanent's own timestamp, for both halves.
- **Rejected**: The moment it became suspected.
- **Site**: `Parun.Engine.Projection.designationGathered` and
  `Parun.Engine.CombatRestriction.gathered`'s designation rows, proved by
  `Parun.FaceDownSpec`'s "CR 613.7f turning face down restamps the permanent
  after a removal that had wiped its grant" and its face-up twin.
- **Issue**: PR #1607.

## Whether a minted object an entry redirect takes changes zones

- **Question**: Hallowed Moonlight exiles a creature token, or a card
  conjured onto the battlefield, that would enter (ruling 2015-06-22). Is its
  arrival in exile a zone change? Stonebinder's Familiar triggers on one: under
  Moonlight, it would see Furgul, Quag Nurturer's conjured Slimy Dualleech.
- **Rules**: CR 614.6, 111.7, 603.6; no rule names conjure; CR of 2026-08-07.
- **Decision**: No zone change, so the Familiar does not trigger. The object
  is put straight into the redirect's zone, as "Whether conjuring a card is a
  zone change" (#2809) puts a conjured card; a token there ceases to exist by
  CR 111.7.
- **Rejected**: A zone change, which would announce a departure from a zone
  the object was never in, as #2809's entry rejects.
- **Site**: `Parun.Engine.Event.placeDiverted`. Proved by the scenario
  hallowed-moonlight-exiles-a-card-conjured-onto-the-battlefield.
- **Issue**: #5764.

## Whether a phased-out permanent a subgame takes leaves visibly

- **Question**: A wish brings a phased-out permanent into a Shahrazad
  subgame. CR 729.4a fires main-game leave triggers; CR 702.26b treats the
  permanent as though it doesn't exist.
- **Rules**: CR 702.26b, 702.26d, 702.26k, 729.1a, 729.4, 729.4a; CR of
  2026-08-07.
- **Decision**: It crosses, but no event is recorded and nothing in the main
  game triggers.
- **Rejected**: Recording the leave: CR 702.26b overrides rules that don't
  name phasing. Leaving it unreachable: the wish belongs to a separate game
  (CR 729.1a).
- **Site**: `Parun.Engine.Setup.applyCrossings`, proved by `Parun.SetupSpec`'s
  "CR 702.26b a phased-out permanent a subgame takes leaves the main game and
  triggers nothing".
- **Issue**: #2468.

## Which component of a merged permanent answers for day and night

- **Question**: Daybound and nightbound transform a permanent that is front or
  back face up. A merged permanent whose double-faced components show
  different faces is neither, by any rule.
- **Rules**: CR 702.145b/c/e/f, 730.2e, 730.2i, 701.27g; CR of 2026-08-07.
- **Decision**: The topmost double-faced component decides. Every printed pile
  holds at most one double-faced component, since no mutate card is
  double-faced, and there all readings agree.
- **Rejected**: The topmost component, by analogy with CR 730.2e's face-down
  status, stops Cubwarden over a nightbound Werewolf turning at day. "Any
  component back face up" leaves a mixed pile with nightbound back face up
  after every transform, so it transforms again on every check.
- **Site**: `Parun.Engine.Game.isFrontFaceUp`, proved by `Parun.MutateSpec`'s
  "CR 730.2i/702.145c a Cubwarden over a nightbound Werewolf turns with the day
  and back with the night".
- **Issue**: #5037.

## Whether speed can pass 4

- **Question**: CR 702.179e says a player has max speed "if their speed is
  4". No rule caps speed, and none says what a speed above 4 is.
- **Rules**: CR 702.179e, 702.178a, 702.179b, 702.179c, 702.179d, 702.179f;
  CR of 2026-08-07.
- **Decision**: An effect may push speed past 4, and a player at 4 or more has
  max speed. Every max speed gate is written as `AtLeast 4`. Gomif, Fast
  Racer, an un-set printing, says "Your speed can increase beyond 4. (You're
  still at max speed at 4 or greater.)", which supports the max speed half.
- **Rejected**: Reading "is 4" literally (`Exactly 4`), which switches off a
  max speed ability at 5. Capping speed at 4: no rule states it, and CR
  702.179d's "less than 4" limits only its own climb, though Gomif's need to
  grant the excess implies a cap otherwise.
- **Site**: `Parun.Engine.Speed.maxSpeed`, proved by `Parun.SpeedSpec`'s "CR
  702.178a past 4 the Raceway keeps its max speed ability" and "CR 702.178a
  past max speed the Surveyor's ability is still offered", both through
  Synthetic Speed Boost.
- **Issue**: #809.

## When Goblin Bookie can be activated

- **Question**: Goblin Bookie (Unglued): "{R}, {T}: Reflip any coin or reroll
  any die. (Activate only any time it makes sense.)" Priority (CR 117.1b)
  never falls inside a roll, and CR 706.2 has no activated modifier.
- **Rules**: CR 706.2, 117.1b, 117.3b, 602.2b, 605.3b, 706.2a, 706.2b; CR of
  2026-08-07.
- **Decision**: Activatable only inside CR 706.2's modification step while a
  die is being rolled, never at priority. It goes through the ordinary
  activation gate (summoning sickness, prohibitions, records) and resolves at
  once with no stack object, as CR 605.3b's mana ability does. Offers come in
  APNAP order, then object order within a player, behind the static
  modifiers, and compete in the roller's pick.
- **Rejected**: An ordinary activation at priority: by then the roll is over,
  so the reroll reaches no die. A static modifier carrying the printed cost:
  it dodges summoning sickness and prohibitions.
- **Site**: `Parun.Types.ActivationRestriction.DuringDieRoll`, gated in
  `Parun.Engine.ActivationRestriction`, and
  `Parun.Engine.Resolve.Effect.throwDice`'s `windowCandidates`, proved by
  `Parun.DiceSpec`'s "CR 706.2b Goblin Bookie rerolls another player's die"
  and "CR 117.1b the Bookie cannot be activated at priority".
- **Issue**: PR #4020.

## How a subgame's wish sees a face-down main-game object

- **Question**: CR 729.1b gives main-game effects no meaning in a subgame. A
  subgame's wish is offered a face-down main-game permanent, such as a
  manifested sorcery. Is it matched as its printed card or as its face-down
  2/2?
- **Rules**: CR 708.2, 708.2a, 729.1b, 729.4; CR of 2026-08-07.
- **Decision**: As the face-down 2/2 with no name. Its listed values are
  copiable values, not a main-game effect, so CR 729.1b does not reach them.
  Living Wish can fetch a manifested sorcery and Burning Wish cannot.
- **Rejected**: Reading every entry through its printed face. That turns CR
  729.1b's bar on effects into a bar on what the object is, and it lets the
  wish name a card by a face the object does not have.
- **Site**: `Parun.Engine.Event.eligible`, proved by
  `Parun.OutsideTheGameSpec`'s "CR 708.2/729.4 a manifested main-game sorcery
  is offered to a subgame's wish as a creature and not as a sorcery".
- **Issue**: none.

## Which half of a split card answers for a box both halves have

- **Question**: CR 709.4 combines a split card's halves, but a power,
  toughness, loyalty, defense, intensity or vanguard box can be had only
  once. Which half answers when both print one, or when both halves'
  characteristic-defining abilities define it?
- **Rules**: CR 709.4, 208.1, 208.5, 604.3, 613.4, 613.4a, 613.7a, 613.8,
  709.4a, 709.4b, 709.4c; CR of 2026-08-07.
- **Decision**: The left half's printed box, and for two
  characteristic-defining abilities on one box, the left half's ability.
  Disjoint boxes take each half's own.
- **Rejected**: Summing, generalising CR 709.4b: that rule concatenates
  symbols, states no arithmetic, and summing doubles a characteristic both
  halves share. Ordering the two abilities by CR 613: they tie on timestamp
  (CR 613.7a), neither changes the other, and CR 613.8 falls back to
  timestamp.
- **Site**: `Parun.Engine.Card.merge2` and its `definedBox`, reached through
  `combined`. `Parun.CardSpec`'s SplitBox group proves the disjoint and
  one-half cases, and "CR 709.4 the left half answers for a box both halves
  print or define" the power and toughness boxes on Synthetic Rival Golem //
  Synthetic Rival Giant: no split printing has a creature half. "CR 709.4
  the left half answers for a loyalty both halves print", and its defense
  and starting intensity siblings, prove the `firstJust` boxes on the other
  Synthetic Rival pairs.
- **Issue**: #658, #2019.

## How perpetual effects follow a meld

- **Question**: Alchemy's "perpetually" follows an object across zone
  changes. When two cards meld into one permanent, or a melded permanent
  leaves, which object or objects does the effect follow?
- **Rules**: CR 712.21c, 400.7, 611.2c, 701.42a, 712.21a, 712.21e; no rule
  names perpetually; CR of 2026-08-07.
- **Decision**: It follows every component in both directions. Each half's
  effect moves onto the melded permanent, and the melded permanent's effect
  moves onto both cards as it leaves. Following an object counts as finding
  what it became under CR 712.21c. Only continuous effects are re-anchored,
  not replacement rows.
- **Rejected**: Ending the effect at the meld, CR 400.7's default, which
  would override the perpetual reading at this one zone change and no other.
  Following only the leading card, as `carryOver` does, because a spell melds
  into nothing. A game-long object id: a second identity model.
- **Site**: `Parun.Engine.Event.perpetuate` and its call in `meld`, proved by
  `Parun.MeldSpec`'s "CR 712.21c a perpetual grant on a melded permanent
  follows both cards it becomes" and "a perpetual grant naming a meld
  component follows onto the permanent the pair melds into".
- **Issue**: #2657.

## Whether an ineligible active player takes the crown

- **Question**: The monarch leaves the game and the active player can't
  become the monarch (Jared Carthalion). CR 725.4's first sentence crowns the
  active player with no eligibility gate.
- **Rules**: CR 725.4, 101.2, 726.4; CR of 2026-08-07.
- **Decision**: The "can become the monarch" test covers the active player
  too, so an ineligible one is skipped and the crown goes to the next
  eligible seat in turn order.
- **Rejected**: The literal reading: an ineligible active player blocks
  sentence 1, fails sentence 2's departure condition, and the crown never
  moves, which makes sentence 3 unreachable.
- **Site**: `Parun.Engine.Monarch.reassignOnDeparture`, proved by
  `Parun.DepartureSpec`'s "CR 725.4 the crown skips a seat that can't become
  the monarch".
- **Issue**: #178.

## Which active player takes the monarch or initiative under shared team turns

- **Question**: CR 725.4 and 726.4 give the crown or the initiative to "the
  active player" when the holder leaves. With shared team turns there are
  several, and CR 805.9 covers only abilities.
- **Rules**: CR 725.4, 726.4, 805.2, 805.9; CR of 2026-08-07.
- **Decision**: The active team decides; its primary player chooses among the
  eligible active players.
- **Rejected**: Always the seat the turn began with.
- **Site**: `Parun.Engine.Game.heirOnDeparture`, proved by the scenario "CR
  725.4 the active team's primary player names the new monarch" and its two
  controls.
- **Issue**: #4142.

## Whether a melded permanent is one mutate component or two

- **Question**: A mutating spell merges with a melded permanent. CR 701.42a
  gives the pair's two cards no order, and CR 730.2a needs one topmost
  component.
- **Rules**: CR 730.2a, 701.42a, 712.8g, 730.2, 730.2c; CR of 2026-08-07.
- **Decision**: The melded pair is one component (`OfMeld`), showing the
  combined back face, expanded into its cards only on departure.
- **Rejected**: One component per card: "topmost" gets two heads and no
  tie-break. Refusing the merge: the CR states no exclusion.
- **Site**: `Parun.Types.MergeComponent.OfMeld` and
  `Parun.Engine.Event.mergeComponents`, proved by `Parun.MutateSpec`'s "CR
  730.2a/712.8g Cubwarden merges with a melded permanent, over and under".
- **Issue**: PR #3456.

## What a fragmented loop forbids, and who is involved

- **Question**: CR 732.3 says the active player, or the first involved
  player, "must then make a different game choice". Who counts as involved,
  which choices count as the same one, and when does a state count as
  recurring?
- **Rules**: CR 732.3, 732.1, 732.5; CR of 2026-08-07.
- **Decision**:
  - The involved players are those who took any action other than passing
    since the state first occurred.
  - Every choice that player made at any earlier occurrence is forbidden, not
    only the last one, so A, B, A, B is refused too.
  - An action with no choices in it is forbidden outright. An activation is
    forbidden as it was completed, meaning announced and paid. Choices made
    later at resolution are separate choices.
  - A state counts as recurring only if nothing in the game reads the history
    the lap appended.
  - Where detection is uncertain, the engine errs towards seeing no loop.
- **Rejected**: Forbidding only the last occurrence's choice. Letting a
  shorter loop nested inside a longer one hide the longer loop's players.
- **Site**: `Parun.Engine.Fragmented.forbidden` and `lapIsRead`, proved by
  `Parun.FragmentedSpec`'s "an activation is refused as announced, not as a
  whole", "an activation is refused as paid, not as announced", "a choice the
  resolution offers does not make a repeated activation a new one" and their
  siblings.
- **Issue**: none.

## Whether a player leaving ends a control-on-entry replacement

- **Question**: CR 800.4a ends "any effects which give that player control
  of any objects" when they leave. Does that reach a floating replacement
  making permanents enter under their control (Gather Specimens), for objects
  that do not exist yet?
- **Rules**: CR 800.4a, 109.5, 616.1b, 800.4b; CR of 2026-08-07.
- **Decision**: Yes. The departing player's control-on-entry rows end; their
  other rows, such as shields, stay. CR 800.4b stays the backstop for other
  entries naming a departed player.
- **Rejected**: Leaving the row for CR 800.4b to catch each entry: its
  "remains in its current zone" cannot be expressed once the entrant is
  materialised, and a surviving row stays a CR 616.1b candidate beside live
  ones.
- **Site**: `Parun.Engine.Departure.controlEffectsEnd` and
  `givesControlOnEntryTo`, proved by `Parun.ReplacementSpec`'s "CR 616.1b a
  departed player's row is not a candidate, so carol is not asked" and the
  scenario "CR 800.4a a departing player's shield is not a control effect, so
  it stays".
- **Issue**: #592.

## A silenced entry silences its departure

- **Question**: Hushwing Gryff's "creatures entering don't cause abilities to
  trigger" names the entry. A creature card returned from a graveyard to the
  battlefield is one zone change, which a "whenever a card leaves your
  graveyard" ability (Spirit Mascot, Kishla Skimmer) also watches. Does that
  ability trigger?
- **Rules**: CR 603.6a, 603.6c, 603.10a, 613.11; CR of 2026-08-07. Rulings:
  Hushwing Gryff, Torpor Orb and Tocatli Honor Guard ("the trigger event
  doesn't have to specify 'creatures' entering"), Hushbringer 2019-10-04 (a
  "leaves the battlefield" trigger does not trigger on a creature dying).
- **Decision**: No. Every trigger the entering zone change satisfies is
  silenced, whichever side of the move its condition names.
- **Rejected**: Silencing only the CR 603.6a enters abilities. The entry rulings
  say the event need not be phrased as creatures entering, and Hushbringer's
  ruling silences the other-side wording ("leaves the battlefield") of a
  silenced dying. Reading the entry half by that mirror leaves no ground for
  sparing the departure half.
- **Site**: `Parun.Engine.Event.Match.entryTriggers`. Proved by the scenarios
  "Hushwing Gryff silences a leaves-your-graveyard trigger on a reanimated
  creature" (Spirit Mascot) and "Hushwing Gryff silences a reanimated card's
  own leaves-your-graveyard trigger" (Oglor's grant).
- **Issue**: #5713.

## A paid flash permission is offered at sorcery timing too

- **Question**: Harbinger of the Tides lets itself be cast "as though it had
  flash if you pay {2} more". At a time its caster could cast a sorcery
  anyway, may they still use the permission and pay the {2}?
- **Rules**: CR 601.2b, 601.2f, 601.3c, 702.8a; CR of 2026-08-07. No ruling.
- **Decision**: Yes. The permission's cost is a candidate beside the printed
  one wherever the card may be cast, and the caster picks.
- **Rejected**: Withholding it where the card's own window is open. Nothing
  in the card or CR 601.3c confines the permission to the moments it is
  needed, and the engine does not make the caster's choice.
- **Site**: `Parun.Engine.Cost.withFlashPermission`. Proved by the scenario
  harbinger-of-the-tides-cast-in-a-main-phase-may-pay-two-more.
- **Issue**: #5765.
