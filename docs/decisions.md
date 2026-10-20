# Decisions

Every behaviour pawl commits to that nothing official forces: a question the
CR leaves undefined, ambiguous, or open to more than one reading, and no
Gatherer ruling or erratum settles. Each entry records the reading chosen so
nobody re-derives it, possibly differently, and names the rules it rests on so
a new CR can be checked against it.

An entry is owed whenever a change picks such a reading. It lands in the same
PR as the code, and the code site cites it by heading. Two things are not
entries: a reading an official ruling settles, which the card's test pins, and
an elision, which is a known gap with an issue rather than a settled answer.

When `docs/rules.txt` is updated, or a ruling lands on a question here,
re-read each entry against the new text. An entry it decides is either
confirmed, and dropped from here, or contradicted, and filed as
`rules-correctness`.

Each entry gives:

- **Question**: what the rules leave open.
- **Rules**: the CR rules read, and the CR date they were read against.
- **Decision**: the reading pawl takes.
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
- **Site**: `Pawl.Engine.Game.componentIsToken`'s `OfSpellCopy` arm, proved by
  `Pawl.MutateSpec`'s "CR 730.2d/608.3f a merged permanent whose topmost
  component is a spell copy is no token".
- **Issue**: none.

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
- **Site**: `Pawl.Engine.Engine.priorityLoop`, the `Concession.Concedes` arm,
  proved by `Pawl.GameSpec`'s "CR 800.4a/117.4 priority after a concede goes
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
- **Site**: `Pawl.Engine.Cost.reductionHalvesOf`, proved by
  `Pawl.PlayerEffectSpec`'s "CR 118.7e a hybrid Phyrexian reduction offers its
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
- **Site**: `Pawl.Engine.Replacement.oneEventPerRecipient`, proved by
  `Pawl.DamageReplacementSpec`'s "CR 120.4 one sentence naming alice twice
  deals her ONE event, of 6".
- **Issue**: #2586.

## Where a name sticker's word goes beside a blank

- **Question**: A name with a blank line (Wolf in _____ Clothing). The blank
  is not a word, so a word placed after k words could go either side of a
  blank that follows word k.
- **Rules**: CR 123.6a, 123.6b, 123.6c; CR of 2026-08-07.
- **Decision**: The blank stays, counts for nothing, and the word goes before
  it: Wolf in Otter _____ Clothing.
- **Rejected**: not recorded.
- **Site**: `Pawl.Engine.NameWords.insertAfter`, proved by
  `Pawl.StickerSpec`'s "CR 123.6a Wolf in _____ Clothing offers four
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
- **Site**: `Pawl.Engine.Count.aggregate`'s `Aggregation.Greatest` arm, proved
  by `Pawl.CountSpec`'s "CR 208.2a Greatest over an EMPTY matched set is
  Nothing, not 0" and "a member whose quantity cannot be determined makes the
  whole maximum Nothing".
- **Issue**: none.

## Who on a winning team takes the ante

- **Question**: CR 407.2 gives the ante to "the winner", but a team win (CR
  104.2c) makes several winners, and CR 805.2's primary player exists only
  under the shared team turns option.
- **Rules**: CR 407.2, 104.2c, 805.2; CR of 2026-08-07.
- **Decision**: The team chooses card by card, and its first seat still
  playing speaks for it. Not asked for a team of one.
- **Rejected**: not recorded.
- **Site**: `Pawl.Engine.Ante.payOut`, proved by the scenario "CR 407.2 /
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
- **Site**: `Pawl.Engine.Expiry`'s `AtEndOfCombatOn` drop arm, proved by
  `Pawl.ExpirySpec`'s "CR 500.5a / 500.8 only a combat PHASE of a later turn
  of that player ends it" and "CR 611.2a a next turn with no combat phase
  takes it at its cleanup".
- **Issue**: #525.

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
- **Site**: `Pawl.Engine.Combat.attackersOn`, proved by
  `Pawl.PlaneswalkerCombatSpec`'s "CR 802.4a once the planeswalker is gone,
  only ITS controller may block the creature attacking nothing".
- **Issue**: #2899.

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
- **Site**: `Pawl.Engine.Cast.castSpellWith`, the `Event.changeZoneCasting`
  step, proved by `Pawl.CastRestrictionSpec`'s "CR 601.2i a cast redirected
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
- **Site**: `Pawl.Types.TriggerLimit` and `Pawl.Types.TriggerFrequency`;
  `Pawl.SpeedSpec`'s "CR 702.179d an ability gained after the turn's first
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
- **Site**: `Pawl.Engine.Event.mintCard`, reached from
  `Pawl.Engine.Resolve.Effect`'s `Effect.Conjure` arm, proved by
  `Pawl.ConjureSpec`'s "CR 603.6 a conjure into a graveyard is no zone change,
  so a graveyard trigger does not see it".
- **Issue**: #2809.

## What counts as an instruction having happened

- **Question**: CR 603.12's "when you do" and CR 118.12's "if you do" ask
  whether an instruction happened, and the CR does not define the test.
- **Rules**: CR 603.12, 118.12; CR of 2026-08-07.
- **Decision**: It happened if it recorded a game event or changed any state
  but bookkeeping. Bookkeeping is whatever an instruction that did not happen
  can still write (event-log samples, allocators, the last choice, a draw from
  an empty library, exile-link prunes, bound zero amounts, vote tallies), and
  is copied across from the state before.
- **Rejected**: An allow-list of state that counts, the earlier event-log
  reading, which misses every state-only instruction writing a field it does
  not name.
- **Site**: `Pawl.Engine.Resolve.Effect.happenedBetween`. The state half is
  proved by the scenario "CR 603.12 a choice that records no event still arms
  its when you do". Copies proved: `exiledWith` by "CR 603.12 an empty mill
  after a token ceased in exile arms no reflexive", `exilePiles` by "CR 603.12
  an empty mill after a face-down card left exile arms no reflexive",
  `nextTimestamp` by "CR 701.28e / 603.12 an ignored convert arms no
  reflexive", `nextEventGroup` by `Pawl.ResolveSpec`'s "CR 118.12 Victimize
  with no creature to sacrifice returns nothing". The other copies are a
  regression fence: no card in `data/cards/` puts an instruction writing them
  ahead of a "when you do" or "if you do".
- **Issue**: none. Rulings contradict it in two shapes, filed as #5334 (an
  "any number" choice of zero still counts) and #5335 (a numbered instruction
  done only in part does not).

## Whether conjuring into a library is a library move for a mana ability

- **Question**: CR 605.1a disqualifies a mana ability whose effect moves a
  card to or from a library. A conjured card comes from no zone.
- **Rules**: CR 605.1a; no rule names conjure; CR of 2026-08-07.
- **Decision**: The destination decides: conjuring into a library is a
  library move, conjuring anywhere else is not.
- **Rejected**: Nothing moves, since the card was in no zone. It loses
  because a library still gains a card, which is what the clause keeps out
  of mana abilities.
- **Site**: `Pawl.Engine.ManaAbility.movesLibraryCard`'s `Effect.Conjure` arm,
  proved by the scenario "CR 605.1a conjuring into a library keeps an ability
  that adds mana off the mana path" on Synthetic Seeded Grove: no printing
  conjures inside an ability that could add mana.
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
- **Site**: `Pawl.Engine.Event.runEntry`, proved by the scenario "CR 614.12
  a Clone reanimated by a sweep collects its own copy effect from the live
  board".
- **Issue**: none.

## How two only-clauses about spending one mana combine

- **Question**: Two effects each say a mana may be spent "only as though it
  were" a different type. Which types may it be spent as?
- **Rules**: CR 609.4b, 101.2, 613.11; CR of 2026-08-07.
- **Decision**: The union of the clauses' sets, unordered. An "only" clause
  names permitted types rather than saying "can't".
- **Rejected**: Each "only" as a prohibition, which pulls in CR 101.2 and has
  the two clauses forbid each other's types.
- **Site**: `Pawl.Engine.Mana.spendableAs`, proved by the scenario "CR 609.4b
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
- **Site**: `Pawl.Engine.Condition.holds`, proved by the scenario "CR
  702.100c a Raptor One with the Stars made an enchantment keeps evolve and
  does not evolve", where CR 702.100c agrees with this reading.
- **Issue**: none.

## Which timestamp the suspected designation's abilities have

- **Question**: CR 701.60c's menace and "can't block" come from the rules, so
  neither CR 613.7a nor 613.7b names their timestamp. It matters against an
  ability removal.
- **Rules**: CR 613.7a, 613.1f, 613.7b, 701.60b, 701.60c; CR of 2026-08-07.
- **Decision**: The permanent's own timestamp, for both halves.
- **Rejected**: The moment it became suspected.
- **Site**: `Pawl.Engine.Projection.designationGathered` and
  `Pawl.Engine.CombatRestriction.gathered`'s designation rows, proved by
  `Pawl.FaceDownSpec`'s "CR 613.7f turning face down restamps the permanent
  after a removal that had wiped its grant" and its face-up twin.
- **Issue**: PR #1607.

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
- **Site**: `Pawl.Engine.Setup.applyCrossings`, proved by `Pawl.SetupSpec`'s
  "CR 702.26b a phased-out permanent a subgame takes leaves the main game and
  triggers nothing".
- **Issue**: #2468.

## Whether a cipher trigger finds its card after the creature leaves

- **Question**: An encoded creature's trigger is on the stack, then the
  creature leaves and CR 702.99c ends the encoding. Does "copy the encoded
  card" still find the card?
- **Rules**: CR 702.99c, 608.2h, 702.99a, 702.99b; CR of 2026-08-07.
- **Decision**: Yes. The relation is keyed on the source's id alone, so the
  trigger still finds the exiled card.
- **Rejected**: Finding nothing, since CR 702.99c ends the encoding when the
  creature leaves. CR 608.2h reads a departed source as it last existed, and
  the card was encoded on it then.
- **Site**: `Pawl.Engine.Resolve.Slots.objectRefObjects`'s
  `ObjectRef.EachCardEncodedOnSource` arm, proved by the scenario "CR 702.99c
  a Piker killed with its cipher trigger on the stack still casts the
  copy".
- **Issue**: none.

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
- **Site**: `Pawl.Engine.Game.isFrontFaceUp`, proved by `Pawl.MutateSpec`'s
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
- **Site**: `Pawl.Engine.Speed.maxSpeed`, proved by `Pawl.SpeedSpec`'s "CR
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
- **Site**: `Pawl.Types.ActivationRestriction.DuringDieRoll`, gated in
  `Pawl.Engine.ActivationRestriction`, and
  `Pawl.Engine.Resolve.Effect.throwDice`'s `windowCandidates`, proved by
  `Pawl.DiceSpec`'s "CR 706.2b Goblin Bookie rerolls another player's die"
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
- **Site**: `Pawl.Engine.Event.eligible`, proved by
  `Pawl.OutsideTheGameSpec`'s "CR 708.2/729.4 a manifested main-game sorcery
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
- **Site**: `Pawl.Engine.Card.merge2` and its `definedBox`, reached through
  `combined`. `Pawl.CardSpec`'s SplitBox group proves the disjoint and
  one-half cases, and "CR 709.4 the left half answers for a box both halves
  print or define" the power and toughness boxes on Synthetic Rival Golem //
  Synthetic Rival Giant: no split printing has a creature half. Loyalty,
  defense and intensity boxes on both halves are untested (#5339).
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
- **Site**: `Pawl.Engine.Event.perpetuate` and its call in `meld`, proved by
  `Pawl.MeldSpec`'s "CR 712.21c a perpetual grant on a melded permanent
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
- **Site**: `Pawl.Engine.Monarch.reassignOnDeparture`, proved by
  `Pawl.DepartureSpec`'s "CR 725.4 the crown skips a seat that can't become
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
- **Site**: `Pawl.Engine.Game.heirOnDeparture`, proved by the scenario "CR
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
- **Site**: `Pawl.Types.MergeComponent.OfMeld` and
  `Pawl.Engine.Event.mergeComponents`, proved by `Pawl.MutateSpec`'s "CR
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
- **Site**: `Pawl.Engine.Fragmented.forbidden` and `lapIsRead`, proved by
  `Pawl.FragmentedSpec`'s "an activation is refused as announced, not as a
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
- **Site**: `Pawl.Engine.Departure.controlEffectsEnd` and
  `givesControlOnEntryTo`, proved by `Pawl.ReplacementSpec`'s "CR 616.1b a
  departed player's row is not a candidate, so carol is not asked" and the
  scenario "CR 800.4a a departing player's shield is not a control effect, so
  it stays".
- **Issue**: #592.
