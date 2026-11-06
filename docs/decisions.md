# Decisions

Every behaviour parun commits to that nothing official forces: a question the
CR leaves undefined, ambiguous, or open to more than one reading, and no
Gatherer ruling or erratum settles. Each entry records the reading chosen so
nobody re-derives it, possibly differently, and names the rules it rests on so
a new CR can be checked against it.

An entry is owed whenever a change picks such a reading, and only when both
hold: the readings are observable, giving different game states or different
legal choices on a board printed cards can build, and nothing official picks
one. It lands in the same PR as the code, and the code site cites it by heading.
Four things are not entries: a reading the CR or an official ruling forces, whose
code site cites that rule or ruling; an implementation choice no legal board can
tell apart from the alternative; a reading only a synthetic card can observe,
which goes in `docs/synthetic-readings.md`; and an elision, which is a known gap
with an issue rather than a settled answer.

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

## Whether a mulligan-time action can be repeated before declaring

- **Question**: CR 103.5b ends "If the player performs the action, they then
  declare". May a player take another such action first?
- **Rules**: CR 103.5, 103.5b; CR of 2026-09-25.
- **Decision**: Yes, until they decline. Each moment before the declaration is
  still "a time they would declare".
- **Rejected**: One action per declaration: "then" orders the declaration after
  the action without saying nothing may come between. Serum Powder's rulings
  and No-Regrets Egret's reminder text fit either reading.
- **Site**: `Parun.Engine.Mulligan.handWindow`, proved by
  `Parun.MulliganSpec`'s "CR 103.5b: an action that leaves its card in hand is
  offered again".
- **Issue**: none.

## A rider ability regained from one granter stays spent

- **Question**: A permanent loses a "triggers only once each turn" or "activate
  only once" ability a granter gave it, then gets it back from the SAME granter
  (Well Rested moved off and back by Aura Graft). Is it a new ability, unspent?
  The rulings on Tyvar the Bellicose, Dionus and Cursed Wombat settle only a
  new granter's grant, and only for a triggered ability.
- **Rules**: CR 113.2c, 400.7, 602.5b, 613.7e; CR of 2026-09-25.
- **Decision**: The same ability, still spent: a grant is named for its
  granter object (`Binding.acquiredFrom`), not for its timestamp. A new
  granter, including one that left and returned (CR 400.7), gives a new
  ability. The activated side reads the same, CR 113.2c being all that speaks
  to it.
- **Rejected**: A new ability on each re-grant, keyed by the grant's
  timestamp: CR 613.7e re-stamps a moved Aura without changing which object
  grants, and the rulings speak of the granting object.
- **Site**: `Parun.Engine.Projection`'s `GainAbility` arm;
  `data/scenarios/well-rested-moved-back-by-aura-graft-stays-spent.json`
  proves it.
- **Issue**: #4627.

## Whether a concession restarts the pass count

- **Question**: CR 117.4 resolves the top object once all players pass in
  succession "without taking any actions in between". When the priority
  holder concedes and priority moves on (CR 800.4a), do earlier passes still
  count?
- **Rules**: CR 117.4, 104.3a, 117.1, 117.3d, 800.4a; the glossary's Pass in
  Succession; CR of 2026-09-25.
- **Decision**: No. The pass set empties and priority goes to the next seat
  still playing.
- **Rejected**: Keeping the passes, which the glossary's "each player in the
  game ... opts not to take an action" allows if a concession is no action: it
  can resolve a spell a player would have answered after the board changed.
- **Site**: `Parun.Engine.Engine.priorityLoop`, the `Concession.Concedes` arm,
  proved by `Parun.GameSpec`'s "CR 800.4a/117.4 priority after a concede goes
  to the next seat, and the pass cycle restarts".
- **Issue**: #143.

## Whether one instruction naming a recipient twice deals one damage event

- **Question**: Char aimed at its own caster deals 4 and 2 to one player. Is
  that two damage events or one of 6? CR 615.10's per-event floor observes it.
- **Rules**: CR 120.4, 608.2f, 614.5, 615.7, 615.10, 701.14c; adjacent,
  Dragonborn Champion's ruling of 2021-07-23 and Savage Alliance's of
  2016-07-13; CR of 2026-09-25.
- **Decision**: One event per recipient, source and moment; the amounts sum,
  over an instruction's aims and over a whole batch's survivors, since a
  redirect can land two proposals of one source together. A counted redirect
  aimed back at its recipient splits nothing, so a flat bonus such as
  Pyromancer's Gauntlet's applies to the one event once (CR 614.5). Parts
  redirects land on one recipient join before its replacements apply, carrying
  every effect that applied to any part, so the bonus applies once there too.
- **Rejected**: Two events, which applies CR 615.10 twice; Savage Alliance's two
  events come from two instructions, which agrees with this. A key without the
  source: combat and fights have several dealers.
- **Site**: `Parun.Engine.Replacement.oneEventPerRecipient`, proved by
  `Parun.DamageReplacementSpec`'s "CR 120.4 one sentence naming alice twice
  deals her ONE event, of 6" and the scenario
  `harms-way-onto-another-recipient-of-its-source-is-one-event`; absorb's
  ceiling spans the event at `Parun.Engine.Replacement.ceilingLeft`, proved by
  `lymph-sliver-absorbs-1-of-earthquake-once-though-pariah-adds-to-it`;
  CR 615.10's floor at `Parun.Engine.Replacement.floorLeft`, proved by
  `temple-altisaur-lets-1-of-earthquake-through-once-though-pariah-adds-to-it`;
  the redirect aimed back at its recipient at
  `Parun.Engine.Event.chooseAndApply`, proved by the scenarios
  `harms-way-back-onto-its-recipient-takes-pyromancers-gauntlet-once-*`; the
  join before replacements at `Parun.Engine.Event.settleThreads`, proved by
  `harms-way-twice-onto-one-recipient-takes-pyromancers-gauntlet-once`.
- **Issue**: #2586, #6251, #6267.

## Whether damage a replacement adds joins a division already owed

- **Question**: Eye for an Eye adds a damage event as it applies, of an amount
  CR 616.1's choices fix. Bob, active, owes a CR 615.7 division over two hits,
  and alice's Eye would add a third. Does his division span it? Lifelink
  observes it. And if alice has a second effect on her event, and so a choice,
  whose question comes first? Harm's Way moving damage onto the shielded
  recipient asks the same.
- **Rules**: CR 101.4, 101.4b, 615.7, 616.1, 616.1f; CR of 2026-09-25.
- **Decision**: A row that adds or moves damage and is its event's only effect
  asks no one anything, so it applies first and the division spans what it
  adds or moves. A row beside another effect is its chooser's choice, which
  takes its APNAP turn: earlier seats' questions and CR 616.1 choices come
  first and cannot see what it may add, and whatever of a shield they leave is
  divided afterwards. A player with neither waits, keeping a shield for the
  added damage.
- **Rejected**: Every seat answering first over what exists: bob's shield could
  never meet damage no one had any say in. Every adding row first: bob, the
  nonactive player, would spend a shared shield ahead of alice by a choice
  nothing puts first. Expanding the batch up front: the amount depends on the
  choices.
- **Site**: `Parun.Engine.Event.settlesFirst`, proved by the scenarios
  `eye-for-an-eye-damage-back-joins-a-division-over-two-hits`,
  `eye-for-an-eye-waits-its-apnap-turn-behind-a-shared-shield` and
  `eye-for-an-eye-waits-behind-an-earlier-seats-own-choice`; for a move,
  `harms-way-onto-a-shielded-creature-joins-the-shields-division` and
  `harms-way-onto-a-shielded-player-joins-a-division-already-owed`.
- **Issue**: #5991, #6047.

## Whether "each creature and each planeswalker" reaches a permanent twice

- **Question**: Magmaquake deals X damage "to each creature without flying
  and each planeswalker". A creature planeswalker without flying is in both
  sets: is it dealt X, or 2X as Char's caster is dealt both amounts?
- **Rules**: CR 120.1, 120.3c, 120.3e, 120.4, 608.2f; CR of 2026-09-25.
- **Decision**: X. One damage instruction over a union of descriptions
  ("each Y and each Z") deals its amount once to each object matching either
  or both; two instructions ("Deal X to each Y. Deal X to each Z.") deal it
  twice. This governs any card dealing one amount to a union of descriptions,
  such as Sarkhan's Unsealing, and any later card of this wording (Storm's
  Wrath, Star of Extinction). No ruling
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

## How a life floor treats a loss in the same damage event

- **Question**: CR 120.4d's Worship example judges a floor on what the whole event
  leaves, counting a gain. A damage event's results can also include a loss that
  is not damage, as when Tainted Remedy replaces a lifelink gain. Bob at 8 with
  Elderscale Wurm is dealt 5 and loses 2. How much does the damage take?
- **Rules**: CR 119.3, 120.4c, 120.4d; Elderscale Wurm's ruling of 2012-07-01,
  "doesn't affect the loss or payment of life"; Worship's of 2004-10-04; CR of
  2026-09-25.
- **Decision**: The event's other results count first, as the example counts a
  gain, and the damage may take the total no lower than the floor. A total already
  below it takes nothing. Bob ends at 6.
- **Rejected**: 5, flooring the damage alone and then taking the loss, which
  ignores the event's other results as the example does not. 7, flooring the whole
  event, which affects a loss the rulings say it doesn't.
- **Site**: `Parun.Engine.Replacement.breaches` and `Parun.Engine.Event`'s
  `LeaveAtLeast` arm, proved by the scenario
  `cr-120-4c-elderscale-wurm-reads-the-life-before-tainted-remedy-s-loss-from-the-same-damage`.
- **Issue**: #5809.

## Whether infect and toxic from one source give poison once

- **Question**: CR 120.3b and 702.164c each give poison counters for one source's
  damage to a player. Tainted Strike on a toxic creature gives both. Is that one
  placement of the sum, or two?
- **Rules**: CR 120.3b, 120.3g, 702.164c, 616.1; CR of 2026-09-25.
- **Decision**: One placement of the sum.
- **Rejected**: Two placements, a CR 616.1 loop each, which under an opponent's
  Vorinclex, Monstrous Raider halves 3 infect and 1 toxic to 1 rather than 2.
  Neither rule says.
- **Site**: `Parun.Engine.Damage`'s `counterResults`. `Parun.DamageSpec`'s "CR
  120.3b/120.3g infect and toxic stack: poison is amount plus N, and no life is
  lost" proves the sum; no test tells one placement from two.
- **Issue**: none.

## Whether a card a restart leaves in exile keeps its stickers

- **Question**: CR 727.5 exempts a card from the restart, so it never moves and
  CR 123.5 has nothing to say. Karn Liberated's ruling has it that no action
  taken in the restarted game applies to the new one, and putting on a sticker
  was one.
- **Rules**: CR 123.5, 727.1, 727.5; Karn Liberated's ruling, "No actions taken
  in the game that was restarted apply to the new game"; adjacent, Tug of War's
  ruling of 2022-10-07, "removes all stickers from it", on a commander going
  into a subgame; CR of 2026-09-25.
- **Decision**: It keeps them. It stays the same object, as its CR 727.4 "those
  cards" read needs. Every other card's stickers come off.
- **Rejected**: it loses them under the ruling, whose example is an effect
  carrying over rather than a change to a card that stays where it was.
- **Site**: `Parun.Engine.Setup.restartGame`, proved by `Parun.StickerSpec`'s
  "CR 727.5/123.2c a card left in exile keeps its stickers, one off an undrawn
  sheet still applying and one off a drawn sheet still used".
- **Issue**: #4887.

## Where a name sticker's word goes in an object with several names

- **Question**: CR 123.6b speaks of one name, but a split card off the stack and
  a creature with Spy Kit have several, which may differ in length.
- **Rules**: CR 123.6b, 123.6c, 612.7, 709.4; It Came from Planet Glurg's ruling
  of 2022-10-07, "it looks at all its names ... it has six words in its name";
  Solaflora's of 2022-10-07 is per position and does not settle this; CR of
  2026-09-25.
- **Decision**: One position, offered up to the longest name's word count, and
  the word goes into every name: after that many words, or at the end of a
  shorter name as CR 123.6c has it.
- **Rejected**: one position per name, since CR 123.6b has the controller choose
  one position and a Spy Kit host's names cannot be asked one by one; capping at
  the shortest name, which refuses positions CR 123.6b allows in a longer one;
  the names as one concatenated list, which CR 123.6b's position in a name does
  not describe. Offering up to the total word count, as CR 123.6b's "any number
  of the other words that are currently in its name" reads under Glurg's ruling,
  was not taken; the cap refuses those positions, which shows only if a name
  later lengthens (CR 123.6c).
- **Site**: `Parun.Engine.Sticker.namePosition` and
  `Parun.Engine.Projection.applyModification`'s `InsertNameWords` arm, proved by
  `Parun.StickerSpec`'s "CR 123.6b/612.7 positions run to the longest name and a
  shorter name takes the word at its end".
- **Issue**: #4901.

## Whether a reversed cast turns a face-down card back down

- **Question**: CR 406.3a turns a face-down exiled card up "just before" the
  announcement. Does CR 733.1 undo that when the cast is reversed?
- **Rules**: CR 406.3a, 601.2, 733.1; CR of 2026-09-25.
- **Decision**: No. The turn precedes the action reversed, so the card stays up,
  and Riftsweeper may now target it.
- **Rejected**: Turning it back down, because CR 733.1's list of the irreversible
  omits it. The 2026-11-04 audit preferred this, moderate confidence, on that
  closed list.
- **Site**: `Parun.Engine.Cast.castSpellWith`, the `turnedUpForPlay` step ahead of
  `before`. No test names it.
- **Issue**: none.

## Who on a winning team takes the ante

- **Question**: CR 407.2 gives the ante to "the winner", but a team win (CR
  104.2c) makes several winners, and CR 805.2's primary player exists only
  under the shared team turns option.
- **Rules**: CR 407.2, 104.2c, 805.2; CR of 2026-09-25.
- **Decision**: The team chooses card by card, and its first seat still
  playing speaks for it. Not asked for a team of one.
- **Rejected**: One winner taking all: CR 407.2's "the winner" has several (CR
  104.2c). The card's owner keeping it.
- **Site**: `Parun.Engine.Ante.payOut`, proved by the scenario "CR 407.2 /
  104.2c the winning team's primary player shares out the ante".
- **Issue**: none.

## What ends a duration until combat on your next turn when it has no combat phase

- **Question**: Brazen Cannonade's "until end of combat on your next turn", when
  False Peace leaves that turn no combat phase. The stated endpoint never comes.
  (With a combat phase, CR 500.5 and 500.5a end it at the first to end, and "your
  next turn" excludes an opponent's.)
- **Rules**: CR 500.5, 500.5a, 500.8, 511.2, 611.2a, 800.4m; CR of 2026-09-25.
- **Decision**: That turn's cleanup.
- **Rejected**: The point combat would have ended, before the postcombat main.
  Carrying it to a later turn of theirs. CR 800.4m's "neither expire immediately
  nor last indefinitely" is for a departed player only, and Brazen Cannonade's
  rulings of 2022-12-02 are silent.
- **Site**: `Parun.Engine.Expiry`'s `AtEndOfCombatOn` drop arm, proved by
  `Parun.ExpirySpec`'s "CR 500.5a / 500.8 only a combat PHASE of a later turn
  of that player ends it" and "CR 611.2a a next turn with no combat phase
  takes it at its cleanup".
- **Issue**: #525.

## Which draw is the first one drawn in a draw step

- **Question**: Chains of Mephistopheles and Alhammarret's Archive except "the
  first one [they/you] draw in each of [their/your] draw steps". When a replacement
  took the drawer's CR 504.1 draw (dredge, a paid Zur's Weirding), is the next draw
  of that step the exempt one?
- **Rules**: CR 504.1, 121.1, 614.6; Chains' rulings of 2004-10-04 and 2007-09-16;
  CR of 2026-09-25.
- **Decision**: No. The exempt draw is the drawer's own CR 504.1 draw, on every
  card with this wording, so a replaced normal draw still uses the exemption up.
- **Rejected**: Counting the cards actually drawn, which the Oracle text, CR 614.6
  and Chains' 2004 ruling all allow: alice dredges her normal draw and Think
  Twice's draw is then the first she draws. It lost to Chains' 2007 ruling, "All
  other draws will be affected", which never mentions a replaced draw and so
  doesn't settle it.
- **Site**: `Parun.Engine.Replacement.matchesPrinted`'s `DrawR` arm. The scenario
  `cr-504-1-chains-of-mephistopheles-takes-alice-s-think-twice-draw-after-she-dredged-her-normal-draw`
  proves it.
- **Issue**: #4781.

## The seat of a departed attacker's planeswalker

- **Question**: Mangara, the Diplomat rechecks, as its trigger resolves, how
  many of "those creatures" are attacking you and/or planeswalkers you control.
  Its ruling reads an attacker that has left by "the player or planeswalker they
  were attacking before they left". Is "you control" read of that planeswalker
  as the attacker left, or now, when the planeswalker has since changed
  controllers? Bob attacks alice's planeswalker with two creatures, both die,
  bob takes the planeswalker: a draw, or none? Carol attacks alice with one and
  bob's planeswalker with another, that one dies, alice takes the planeswalker:
  does it make two?
- **Rules**: CR 506.4, 506.4c, 508.1b, 603.4, 608.2h; Mangara's ruling of
  2020-06-23; CR of 2026-09-25.
- **Decision**: As it left. The attacker's last known information is what it
  was attacking under whom, so the first board draws and the second counts one.
- **Rejected**: Now. CR 608.2h gives it a footing, current information of a
  planeswalker still on the battlefield, but only by reading "you control" as a
  question about the planeswalker rather than about the attack. It answers with
  a state no attacker can be in: CR 506.4 ends an attack on a planeswalker whose
  controller changes, so a creature still attacking would read as attacking
  nothing, and one that left a moment earlier would read as attacking the new
  controller, on the second board a player it never attacked.
- **Site**: `Parun.Engine.Count.lastKnownView`, reading
  `Combat.removedDefending`. Proved by turns 12 and 17 of the scenario
  mangara-draws-when-two-attack-you-or-your-planeswalkers-and-for-an-opponents-second-spell.
- **Issue**: #5890.

## Whether a myriad token attacks an opponent who is not a defending player

- **Question**: CR 702.116a's token is "attacking that player or a planeswalker
  they control", for each opponent other than defending player. Where CR 506.2a
  has the attacking player choose one defending player, the others are not. CR
  508.4 lets an effect say what a creature attacks, and CR 508.4a speaks of a
  player no longer in the game.
- **Rules**: CR 506.2a, 508.4, 508.4a, 702.116a; Warchief Giant's rulings of
  2015-11-04 are silent; CR of 2026-09-25.
- **Decision**: The token enters, not attacking, by analogy with CR 508.4a.
- **Rejected**: Attacking that player as written: it makes an attack on a player
  CR 506.2a left out of combat.
- **Site**: `Parun.Engine.Keyword`'s `myriad` and
  `Parun.Engine.Combat.putOntoBattlefieldAttacking`'s narrowing. No test yet: the
  myriad tests run under CR 802's option.
- **Issue**: none.

## Who may block a creature attacking nothing

- **Question**: CR 506.4c's creature, its planeswalker or battle removed from
  combat, attacks nothing but "may be blocked". CR 802.4a lets a player block
  only creatures attacking them, their planeswalker or their battle. With
  several defending players, which may block it?
- **Rules**: CR 506.4c, 509.1a, 802.2a, 802.4a, 802.4b; CR of 2026-09-25.
- **Decision**: Only the player it attacked before the removal: the
  planeswalker's controller or the battle's protector, extending CR 802.2a's
  "before it was removed from combat" by analogy.
- **Rejected**: Every defending player: it has no tie to the attack, and CR
  802.4b would then judge each player's block separately, so two players could
  block it at once. Nobody: contradicts CR 506.4c.
- **Site**: `Parun.Engine.Combat.attackersOn`, proved by
  `Parun.PlaneswalkerCombatSpec`'s "CR 802.4a once the planeswalker is gone,
  only ITS controller may block the creature attacking nothing".
- **Issue**: #2899.

## Attacks alone after a sacrificed co-attacker

- **Question**: CR 506.5 and CR 508.3a/508.3d read "declared as an attacker",
  and CR 508.1k makes attacking only a chosen creature still controlled once
  the costs are paid. Is a chosen creature sacrificed to pay a cost to attack
  (Exalted Dragon's land, an Ashnod's Altar under Ghostly Prison) declared? Its
  co-attacker attacks alone, exalted triggers, and "whenever you attack" fires,
  or not.
- **Rules**: CR 506.5, 508.1a, 508.1k, 508.3a, 508.3d, 509.1g; CR of
  2026-09-25.
- **Decision**: No. A creature is declared as an attacker when the declaration
  makes it attacking at CR 508.1k, so it is left out of the count, the
  attack triggers and Combat.declaredAttackers. The blocking side reads CR
  509.1g the same way, the attacker staying blocked by CR 509.1h's own text.
- **Rejected**: Counting every creature chosen at CR 508.1a: a creature that
  never attacked would trigger "whenever a creature attacks" from the
  graveyard and make its co-attacker share an attack it never made.
- **Site**: `Parun.Engine.Combat.attemptAttackDeclaration`'s `survivors`,
  proved by data/scenarios/combat-cost's "CR 506.5 / 508.1k a co-attacker
  sacrificed to Exalted Dragon leaves the Dragon attacking alone".
- **Issue**: #6245.

## Which defending player Cunning Giant attacking nothing reads

- **Question**: With several defending players, whose creature may Cunning Giant
  assign to once the planeswalker or battle it attacked has left combat? CR
  802.2a's sentences name no one for a creature still attacking but attacking
  nothing.
- **Rules**: CR 506.4c, 508.5, 802.2a; CR of 2026-09-25.
- **Decision**: The player it attacked before the removal, as in "Who may block a
  creature attacking nothing".
- **Rejected**: Its controller choosing among all of them, under CR 802.2a's last
  sentence: that has no tie to the attack.
- **Site**: `Parun.Engine.Damage.attackerAssignment`. No test yet.
- **Issue**: #5437.

## Who sends a trampler's excess past a banding blocker

- **Question**: A creature with trample is blocked by a creature with banding. CR
  702.22j gives the defending player the division "among any creatures blocking
  it". May they also assign the excess to what the creature attacks?
- **Rules**: CR 510.1c, 702.19b, 702.22j; CR of 2026-09-25.
- **Decision**: Yes. The defending player makes the whole assignment under CR
  702.19b's thresholds.
- **Rejected**: Blockers only, which is the rule's second sentence and the reminder
  text read as a limit. Thorn Elemental's and Lone Wolf's 2018-04-27 ruling has the
  defending player decide on sending damage past the blockers, which that sentence
  doesn't name either.
- **Site**: `Parun.Engine.Damage`, the `banded` chooser. No test yet: War Elephant
  blocked by Benalish Hero is the board.
- **Issue**: none.

## Whether conjuring a card is a zone change

- **Question**: Alchemy's conjure creates a card in a zone, and no CR rule
  covers it. Is that arrival a zone change, so that a "put into a graveyard
  from anywhere" trigger or a replacement sees a card conjured into a
  graveyard?
- **Rules**: CR 603.6, 111.2, 400.6, 400.11, 400.11c, 603.6a, 603.6c, 616.1;
  no rule names conjure; Toralf's Disciple's rulings of 2024-11-08, which say how
  to represent a conjured card and name no origin; CR of 2026-09-25.
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

## Whether an ability a merge grafts is still characteristic-defining

- **Question**: CR 702.140e gives a mutated permanent every component's
  abilities. Is a component's characteristic-defining ability, such as
  Tarmogoyf's power and toughness, still one on the merged permanent (layer
  7a), or a plain static ability (layer 7b, in timestamp order)?
- **Rules**: CR 604.3a, 613.2a, 613.4a, 613.4b, 613.7a, 702.140e, 730.2a; CR
  of 2026-09-25.
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

## Whether Thieves' Auction offers an Aura with nothing to enchant

- **Question**: Its 2005 ruling keeps a chosen Aura with nothing to enchant in
  exile, choosable again; its 2004 ruling forbids choosing one. May a player
  choose one?
- **Rules**: CR 303.4f, 303.4g; CR of 2026-09-25.
- **Decision**: Yes, on the later and more specific ruling. Choosing one passes
  that player's pick. The auction goes on while an exiled card could enter, so
  only such Auras are left exiled, as that ruling says.
- **Rejected**: Filtering those Auras out, the 2004 ruling, which the 2005 one's
  "can still be chosen by you or another player later" contradicts.
- **Site**: `data/cards/thieves-auction.json`'s chooser filter and repeat
  condition, proved by the scenarios
  `thieves-auction-keeps-an-aura-with-nothing-to-enchant-choosable` and
  `thieves-auction-goes-on-for-an-aura-that-can-enter-and-ends-on-one-that-cannot`.
- **Issue**: #6179.

## Which board an entry inside a batch collects replacement effects from

- **Question**: When an entry is contained in a CR 608.2f batch, does its CR
  616.1 loop collect from the board as it was before the batch, or from the
  live board?
- **Rules**: CR 608.2f, 614.12, 616.1g; CR of 2026-09-25.
- **Decision**: The live board. The entering object is not on the pre-batch
  board, and a contained event keeps its own footing.
- **Rejected**: The pre-batch board that the batch's other members are judged
  against. CR 616.1g speaks only to the order the two events' effects are
  chosen in, not to which board each collects from.
- **Site**: `Parun.Engine.Event.runEntry`, proved by the scenario "CR 614.12
  a Clone reanimated by a sweep collects its own copy effect from the live
  board".
- **Issue**: none.

## How a mana of any type rider combines with an only-clause

- **Question**: Celestial Dawn lets other mana be spent "only as though it were
  colorless"; a cast permission says "mana of any type can be spent". May red
  mana pay that spell's {B}?
- **Rules**: CR 118.14, 609.4a, 609.4b, 101.2, 613.11; CR of 2026-09-25.
- **Decision**: Yes. Both permissions apply (CR 609.4a). An only-clause names
  what it permits rather than saying "can't", so CR 101.2 is not engaged.
- **Rejected**: The only-clause overriding the rider under CR 101.2: it does not
  say "can't". The later of the two winning by timestamp under CR 613.11: two
  permissions do not conflict, so there is nothing to order. Mycosynth Lattice's
  2004-12-01 ruling, "it doesn't remove restrictions on the mana", is the closest
  official text against this reading; its example restricts what the mana pays
  for, not what it is spent as.
- **Site**: `Parun.Engine.Mana.relax`, proved by the scenario "CR 118.14 / 609.4a
  Tinybones, Bauble Burglar under Celestial Dawn"; Dire Fleet Daredevil shares it.
  A static clause reaches the same reading through `Parun.Engine.Mana.spendableAs`
  (scenario vizier-of-the-menagerie-under-celestial-dawn-spends-colorless-as-white).
- **Issue**: none.

## What moved a madness card

- **Question**: CR 400.7k follows a madness card that "wasn't cast and was moved
  to a public zone". Does that include a move by something else ahead of the
  madness trigger's resolution, Pull from Eternity's?
- **Rules**: CR 400.7, 400.7k, 702.35a, 702.35c; CR of 2026-09-25.
- **Decision**: No, only the card the resolving trigger itself found in exile:
  the exception is to CR 400.7 and is worded around that resolution.
- **Rejected**: Any earlier move, which fits "was moved" alone but makes an
  unrelated effect's move a madness outcome.
- **Site**: `Parun.Engine.Stack.afterMadness`, proved by the scenario "CR 400.7k
  Tinybones, Bauble Burglar: a madness card another effect moved".
- **Issue**: none.

## Whether a lingering static effect's set is fixed as its permanent leaves

- **Question**: Titania's Song: "If this enchantment leaves the battlefield, this
  effect continues until end of turn." CR 611.2c fixes the set only for an effect
  "generated by the resolution of a spell or ability", and this one is a static
  ability's. Is an artifact entering after the Song has gone animated?
- **Rules**: CR 604.2, 611.2c; the card's one ruling is on attacking; CR of
  2026-09-25.
- **Decision**: No. The set is fixed as the permanent leaves, by analogy with CR
  611.2c.
- **Rejected**: Reading "each noncreature artifact" live until end of turn: the
  words allow it, but the stored effect then has no permanent to read it from.
- **Site**: `Parun.Engine.Event`'s departure handover and
  `Parun.Engine.Projection.frozenStaticParts`, proved by `Parun.ExpirySpec`'s "CR
  611.2a whole card: the animation outlives Titania's Song and ends at cleanup".
- **Issue**: none.

## Which creatures are "those creatures" after a forced attack on a class

- **Question**: Maddening Imp makes "non-Wall creatures the active player
  controls" attack, a rules change that CR 611.2c keeps live over the turn,
  then destroys "each of those creatures that didn't attack this turn". Is
  that the set as the ability resolved, or the class as the end step reads it?
- **Rules**: CR 611.2c, 508.1d, 603.7c, 805.9; CR of 2026-09-25.
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

## What a gift does after a text change swaps its creature type

- **Question**: "Gift a tapped Fish" prints a creature type a text change reaches.
  CR 702.174f and 702.174i define Fish and Octopus; no rule defines "Gift a tapped
  Elf". What does it do?
- **Rules**: CR 612.2a, 702.174a, 702.174b, 702.174f, 702.174i; CR of 2026-09-25.
- **Decision**: The defined effect with the word swapped: a tapped 1/1 blue Elf. CR
  612.2a treats a word that names a token as its type and name.
- **Rejected**: No effect, since CR 702.174b defines the effect by the [something]
  listed and nothing defines this one: it makes a legal text change disarm the
  keyword.
- **Site**: `Parun.Engine.Filter.rewriteKeyword`'s Gift arms, proved by
  `Parun.CounterspellSpec`'s "CR 612.2a an Evolution swapping Fish for Elf on a
  promised Into the Flood Maw gives bob a tapped 1/1 blue Elf Token".
- **Issue**: #4819.

## Which timestamp the suspected designation's abilities have

- **Question**: CR 701.60c's menace and "can't block" come from the rules, so
  neither CR 613.7a nor 613.7b names their timestamp. It matters against an
  ability removal.
- **Rules**: CR 613.7a, 613.1f, 613.7b, 701.60b, 701.60c; CR of 2026-09-25.
- **Decision**: The permanent's own timestamp, for both halves.
- **Rejected**: The moment it became suspected: CR 701.60c states the abilities
  as what a suspected permanent has, and no effect creates them, so CR 613.7b has
  nothing to stamp. The MKM rulings' "It gains menace" lean this way, but say
  nothing of order.
- **Site**: `Parun.Engine.Projection.designationGathered` and
  `Parun.Engine.CombatRestriction.gathered`'s designation rows, proved by
  `Parun.FaceDownSpec`'s "CR 613.7f turning face down restamps the permanent
  after a removal that had wiped its grant" and its face-up twin.
- **Issue**: PR #1607.

## How many times a prevention's additional effect runs

- **Question**: One application of a shield stops damage from two sources at once.
  Divine Deflection's "deals that much damage" names no source. Does it throw one
  lot or one per source?
- **Rules**: CR 615.5, 615.7, 615.13; CR of 2026-09-25.
- **Decision**: Once per source the application covered, with that source's share,
  for every rider. A shield spanning a 2 and a 1 throws a 2 and a 1, so an enrage
  target triggers twice. The CR 615.13 trigger still fires once for the
  application. Comeuppance's "that creature" needs the split, and it is one rule
  for all riders. Owner's reading, PR `#4738`.
- **Rejected**: One summed lot, which leaves Comeuppance nothing to aim at. One lot
  where the rider reads no source, which fits CR 615.7's "the number of events or
  sources ... doesn't matter" but gives two riders of one shape different counts;
  the 2026-11-04 audit preferred it, moderate confidence. No ruling picks one.
- **Site**: `Parun.Engine.Resolve.Effect.runPreventionRider`, proved by
  `Parun.DamageReplacementSpec`'s Divine Deflection case.
- **Issue**: #2287.

## Whether an ability's own "prevent" is a self-replacement

- **Question**: Power Leak deals 2 damage, then says "prevent X of that damage".
  It is the resolving ability's own effect, as CR 614.15 describes, and it uses
  "prevent", as CR 615.1a describes. Does it apply first with no choice, or does
  its victim order it against Furnace of Rath or Reverse Damage?
- **Rules**: CR 614.15, 608.2c, 615.1, 615.1a, 616.1a, 616.1e; CR of 2026-09-25.
  CR 614.15 opens "Some replacement effects", CR 615.1 makes a prevention effect
  continuous, and neither Power Leak nor Errant Minion has a ruling.
- **Decision**: A self-replacement. It applies first, so Furnace of Rath doubles
  what is left, and Reverse Damage prevents only that.
- **Rejected**: A continuous prevention effect under CR 616.1e, which lets the
  victim take 3 rather than 2 under Furnace of Rath. The sentence qualifies the
  one before it, as CR 608.2c lets later text do.
- **Site**: `data/cards/power-leak.json`'s `origin`, proved by the scenario
  "power-leak-prevents-before-furnace-of-rath-doubles".
- **Issue**: #6128.

## Whether a phased-out permanent exiled with its departed controller leaves visibly

- **Question**: CR 800.4a or 800.4c exiles a phased-out permanent (CR
  702.26n). Does a leaves-the-battlefield or put-into-exile trigger see it go?
- **Rules**: CR 702.26b, 702.26d, 702.26k, 702.26n, 800.4a, 800.4c; CR of
  2026-09-25.
- **Decision**: It is exiled, but nothing triggers. The exile records only an
  arrival no trigger reads, so CR 903.9a still offers a commander back.
- **Rejected**: Recording the leave: CR 702.26b overrides rules that don't
  name phasing, and CR 702.26k says as much for the road beside it.
- **Site**: `Parun.Engine.Departure.exilePhasedOut`, proved by
  `Parun.PhasingSpec`'s "CR 702.26n a phased-out permanent its departed
  controller doesn't own is exiled at once".
- **Issue**: #2468, #6254, #6263.

## Which component of a merged permanent answers for day and night

- **Question**: A merged permanent with one double-faced component under a
  single-faced top: is it front or back face up for CR 702.145?
- **Rules**: CR 702.145b/c/e/f, 730.2e, 730.2i, 701.27g; CR of 2026-09-25.
- **Decision**: The topmost double-faced component decides. Every printed pile
  holds at most one double-faced component, since no mutate card is
  double-faced.
- **Rejected**: The topmost component, by analogy with CR 730.2e's face-down
  status, stops Cubwarden over a nightbound Werewolf turning at day. Neither front
  nor back face up, reading CR 730.2i with 701.27g, does the same. A pile with two
  double-faced components has no printing.
- **Site**: `Parun.Engine.Game.isFrontFaceUp`, proved by `Parun.MutateSpec`'s
  "CR 730.2i/702.145c a Cubwarden over a nightbound Werewolf turns with the day
  and back with the night".
- **Issue**: #5037.

## Whether speed can pass 4

- **Question**: CR 702.179e says a player has max speed "if their speed is
  4". No rule caps speed, and none says what a speed above 4 is.
- **Rules**: CR 702.179e, 702.178a, 702.179b, 702.179c, 702.179d, 702.179f; the
  reminder "Max speed is 4", Hazoret, Godseeker's rulings of 2025-02-07; CR of
  2026-09-25.
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
  Synthetic Speed Boost. On regular printings speed never passes 4; Gomif is the
  only printed producer.
- **Issue**: #809.

## Whether Goblin Bookie can be activated with nothing to reroll

- **Question**: "(Activate only any time it makes sense.)" is parenthetical, and
  no rule defines "makes sense". With no die being rolled and no Die creature,
  can the Bookie be activated at priority, tapping it and rerolling nothing?
- **Rules**: CR 117.1b, 207.2, 207.2a, 602.1b, 609.3; Pippa, Duchess of Dice's
  rulings of 2020-02-29 settle a die that exists and not this; CR of 2026-09-25.
- **Decision**: No. The sentence is an activation instruction (CR 602.1b), and
  with nothing to reroll the ability is not offered.
- **Rejected**: Reading the parenthetical as text with no game function (CR
  207.2), so CR 117.1b lets it be activated at any priority: CR 207.2a's reminder
  text summarizes a rule, and no rule says this.
- **Site**: `Parun.Types.ActivationRestriction.DuringDieRoll`, gated in
  `Parun.Engine.ActivationRestriction`, proved by `Parun.DiceSpec`'s "CR 117.1b
  the Bookie cannot be activated at priority".
- **Issue**: PR #4020.

## Whether a reroll reaches a die before the lowest roll is ignored

- **Question**: Under Pixie Guide, does a reroll modify a die before the lowest roll
  is ignored, or only a die that survived? CR 706.6's "no effects apply to that
  roll" points one way, its "results tied for the lowest" and CR 706.2 the other.
- **Rules**: CR 706.2, 706.2b, 706.6; CR of 2026-09-25.
- **Decision**: Rerolls first. Valiant Endeavor with Clam-I-Am on 3, 5, 5: the 3
  may be rerolled, and a 6 gives results 6 and 5.
- **Rejected**: Ignoring first, so the 3 "never happened" and the results are 5 and
  5. The 2026-11-04 audit preferred this, moderate confidence: it is the printed
  order and CR 706.6's plainer sentence.
- **Site**: `Parun.Engine.Resolve.Effect.throwDice`, pinned by the scenario
  `cr-706-2b-pixie-guide-adds-a-die-to-clam-i-am-s-reroll`.
- **Issue**: none.

## How a subgame's wish sees a face-down main-game object

- **Question**: CR 729.1b gives main-game effects no meaning in a subgame. A
  subgame's wish is offered a face-down main-game permanent, such as a
  manifested sorcery. Is it matched as its printed card or as its face-down
  2/2?
- **Rules**: CR 110.5, 701.40a, 708.2, 708.2a, 729.1b, 729.4; CR of 2026-09-25.
- **Decision**: As the face-down 2/2 with no name. CR 701.40a's defining effect
  has no meaning here (CR 729.1b), but CR 708.2a itself gives a face-down
  permanent these values, and face down is a status (CR 110.5).
  Living Wish can fetch a manifested sorcery and Burning Wish cannot.
- **Rejected**: Reading every entry through its printed face. That turns CR
  729.1b's bar on effects into a bar on what the object is, and it lets the
  wish name a card by a face the object does not have.
- **Site**: `Parun.Engine.Event.eligible`, proved by
  `Parun.OutsideTheGameSpec`'s "CR 708.2/729.4 a manifested main-game sorcery
  is offered to a subgame's wish as a creature and not as a sorcery".
- **Issue**: none.

## Whether a subgame of a Commander game is one

- **Question**: CR 903.11 limits what comes in from outside "a Commander
  game". Does that cover a subgame of one (Shahrazad), whose main-game cards
  are outside it?
- **Rules**: CR 729.2, 729.2c, 729.4, 903.11, 903.11a; CR of 2026-09-25.
- **Decision**: Yes. CR 729.2c moves the commander into the subgame's command
  zone, so the subgame is played as a Commander game: a wish there reaches no
  main-game card, and the companion action meets CR 903.11a's limits.
- **Rejected**: A plain game. CR 729.2 says the subgame follows rule 103 and
  names no variant, but the commander CR 729.2c moves would then be no
  commander, leaving rule 903's other rules unread for it.
- **Site**: `Parun.Engine.Commander.isCommanderGame`, proved by
  `Parun.OutsideTheGameSpec`'s "CR 729.2c/903.11 a wish in a subgame of a
  Commander game reaches no main-game creature".
- **Issue**: #6170.

## How perpetual effects follow a meld

- **Question**: Alchemy's "perpetually" follows an object across zone
  changes. When two cards meld into one permanent, or a melded permanent
  leaves, which object or objects does the effect follow?
- **Rules**: CR 712.21c, 400.7, 611.2c, 701.42a, 712.21a, 712.21e; no rule
  names perpetually; CR of 2026-09-25.
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
- **Rules**: CR 725.4, 101.2, 726.4; CR of 2026-09-25. Jared Carthalion, True
  Heir, 2020-11-10 ("exactly one monarch from that point forward").
- **Decision**: The "can become the monarch" test covers the active player
  too, so an ineligible one is skipped and the crown goes to the next
  eligible seat in turn order.
- **Rejected**: The literal reading: CR 101.2 stops sentence 1, an active player
  still in the game fails sentence 2's departure condition, and an eligible seat
  fails sentence 3's, so nobody is crowned. That leaves a game with no monarch
  while a player could be one, which sits badly with Jared's ruling, though
  sentence 3 keeps that ruling from being absolute.
- **Site**: `Parun.Engine.Monarch.reassignOnDeparture`, proved by
  `Parun.DepartureSpec`'s "CR 725.4 the crown skips a seat that can't become
  the monarch".
- **Issue**: #178.

## Which active player takes the monarch or initiative under shared team turns

- **Question**: CR 725.4 and 726.4 give the crown or the initiative to "the
  active player" when the holder leaves. With shared team turns there are
  several, and CR 805.9 covers only abilities.
- **Rules**: CR 725.4, 726.4, 805.2, 805.9; CR of 2026-09-25.
- **Decision**: The active team decides; its primary player chooses among the
  eligible active players.
- **Rejected**: Always the seat the turn began with.
- **Site**: `Parun.Engine.Game.heirOnDeparture`, proved by the scenario "CR
  725.4 the active team's primary player names the new monarch" and its two
  controls.
- **Issue**: #4142.

## Whose range of influence cuts a team's choice

- **Question**: Under shared team turns and limited range, a team's choice
  falls to its primary player when the team disagrees. Is it cut to the
  primary player's range (CR 801.5a), to the union of the choosing players'
  ranges, or not at all?
- **Rules**: CR 725.4, 726.4, 702.22k, 801.2, 801.2b, 801.5a, 801.5c, 805.2,
  805.9; CR of 2026-09-25.
- **Decision**: The union of the ranges of the players whose choice it is. The
  primary player settles the team's choice among answers its players could
  give; it is not a new choice of one player. The active team choosing who
  takes the monarch or initiative contains every candidate, each in their own
  range (CR 801.2b), so nothing is cut. Banding creatures of several
  controllers cut the active player who divides to their controllers' ranges.
- **Rejected**: The primary player's range: when it holds no eligible
  candidate (Jared Carthalion, True Heir on the primary player, the adjacent
  teammate gone) the team has an answer it cannot give, and CR 801.5c's
  hand-off speaks of an effect's controller, not a rule's team. No cut for
  banding: CR 805.9 makes it the abilities' controllers' choice, and CR 801.5a
  binds each of them.
- **Site**: `Parun.Engine.Game.heirOnDeparture` and
  `Parun.Engine.Damage.blockerChooser`, proved by the scenarios "CR 801.5a /
  805.2 the primary player crowns a teammate outside their own range" and "CR
  801.5a / 805.9 banding creatures of two controllers offer an active player in
  either range".
- **Issue**: #4918.

## Whether a melded permanent is one mutate component or two

- **Question**: A mutating spell merges with a melded permanent. CR 701.42a
  gives the pair's two cards no order, and CR 730.2a needs one topmost
  component.
- **Rules**: CR 730.2a, 701.42a, 712.8g, 730.2, 730.2c; CR of 2026-09-25.
- **Decision**: The melded pair is one component (`OfMeld`), showing the
  combined back face, expanded into its cards only on departure.
- **Rejected**: One component per card: "topmost" gets two heads and no
  tie-break. Refusing the merge: the CR states no exclusion.
- **Site**: `Parun.Types.MergeComponent.OfMeld` and
  `Parun.Engine.Event.mergeComponents`, proved by `Parun.MutateSpec`'s "CR
  730.2a/712.8g Cubwarden merges with a melded permanent, over and under".
- **Issue**: PR #3456.

## Which rows CR 730.3e counts as reaching only cards

- **Question**: CR 730.3e names a replacement that applies to a "card" without
  also including tokens. Is a row worded "nontoken creature" (Anafenza, the
  Foremost's "would die") such a row, and does a row that also names other
  characteristics reach the cards of a token-topped merged permanent?
- **Rules**: CR 730.3e, 730.2d, 108.2, 110.1, 111.1; CR of 2026-09-25.
- **Decision**: A row reaches the card components when its object filter fails
  the merged permanent only for being a token: it is judged against the
  permanent with token-ness cleared. "Nontoken" counts, a permanent being a
  card or a token (CR 110.1).
- **Rejected**: Only the word "card": the pool encodes "a card" and "nontoken"
  alike, and the rule's contrast is with tokens. Judging each card's own
  characteristics: the components have none apart from the permanent until
  they arrive.
- **Site**: `Parun.Engine.Replacement.reachesCardComponents`, proved by
  `Parun.MutateSpec`'s "CR 730.3e a token-topped merged permanent dies while
  Leyline of the Void exiles its card".
- **Issue**: #6169.

## What a fragmented loop forbids, and who is involved

- **Question**: CR 732.3 names the players "involved in the loop", and has them
  "make a different game choice". Over what span is a player involved, and how
  fine is a choice?
- **Rules**: CR 732.1, 732.3, 732.5; CR of 2026-09-25.
- **Decision**:
  - Involvement runs from when the state first occurred, not over the last lap.
  - An activation with something to announce or pay is refused as it was
    completed. Aiming or paying it another way is a different choice.
  - A choice made later at resolution is separate, and doesn't make a repeated
    activation a new one.
- **Rejected**: Involvement over the last lap only, which lets a shorter loop
  nested inside a longer one hide the longer one's players. Refusing a targeted or
  paid activation as a whole, which CR 732.1's "taking an action" would allow and
  CR 732.3's example, with no target, doesn't settle.
- **Site**: `Parun.Engine.Fragmented.forbidden`, proved by
  `Parun.FragmentedSpec`'s "a state that does not recur leaves the activation
  offered", "an activation is refused as announced, not as a whole", "an activation
  is refused as paid, not as announced", and "a choice the resolution offers does
  not make a repeated activation a new one".
- **Issue**: #951.

## When a re-created object is the same game state

- **Question**: CR 732.3 turns on "the same game state" being reached again,
  which the CR doesn't define. A lap that moves a card makes a new object
  (CR 400.7). Is the state it returns to the same one?
- **Rules**: CR 732.3, 400.7, 613.7; CR of 2026-09-25. No ruling.
- **Decision**: The same, where it differs only in which objects and stamps
  stand for which, in an order-preserving renaming, and what the log says of
  each held object answers alike. No card or player can tell the two apart.
- **Rejected**: Different, by identity, which lets Blinking Spirit under
  Omniscience loop forever with no player made to choose otherwise.
- **Site**: `Parun.Engine.Fragmented.digest`, proved by `Parun.FragmentedSpec`'s
  "a loop that moves a card recurs under the card's new identity".
- **Issue**: #6184.

## Who a fragmented loop inside a resolution refuses

- **Question**: Inside a repeated process (Thieves' Auction), when does CR
  732.3's loop close, who is involved, and what is a different choice?
- **Rules**: CR 732.3; CR of 2026-09-25.
- **Decision**: A run closes a loop when the next run begins in the state it
  began in. The involved players are those asked to pick in it; a pick with one
  option asks nobody. The first of them in APNAP order may not pick what they
  picked again while the state recurs.
- **Rejected**: Counting an unasked pick as involvement, which refuses a player
  their only option while another involved player could still vary theirs.
- **Site**: `Parun.Engine.Resolve.Arms.Zones.repeatIf` and
  `Parun.Engine.Resolve.Common.pickByChooser`, proved by the scenarios
  `thieves-auction-refuses-the-active-player-a-stranded-aura-both-players-chose`
  and
  `thieves-auction-goes-on-for-an-aura-that-can-enter-and-ends-on-one-that-cannot`.
- **Issue**: #6179.

## Whether attack left closes up over a seat that emptied

- **Question**: CR 803.1a and 803.1b let a player attack only the opponent seated
  immediately beside them. After a seat empties, is that still measured over it on
  later turns?
- **Rules**: CR 801.2c, 803.1a, 803.1b, 807.2, 807.4h; CR of 2026-09-25.
- **Decision**: Yes, for the rest of the game. A player whose neighbour left can't
  attack again.
- **Rejected**: Closing up as the next turn begins, as range of influence does (CR
  801.2c's Example, 807.4h). The 2026-11-04 audit preferred this: one reading of
  "seat" across a game, and no player locked out by an unrelated concession.
- **Site**: `Parun.Engine.Combat.attackableOpponents`' `Leftward` and `Rightward`
  arms. The scenarios `attack-option-left-seat-empty` and
  `attack-option-right-seat-after-departure` stop at the same turn; no test reaches
  a later one.
- **Issue**: none.

## Whether Alternating Teams teammates review hands across an emptied seat

- **Question**: CR 811.5 lets teammates review each other's hands only while
  "sitting next to each other". Once the seat between them empties, when are
  they?
- **Rules**: CR 801.2c, 811.4, 811.5; CR of 2026-09-25.
- **Decision**: As the next turn begins, when CR 801.2c closes the seat. Until
  then the departed player's seat still separates them.
- **Rejected**: At once, as the player leaves: CR 811.4's "seated next to"
  closes up a turn later (`Parun.Engine.Combat.attackableOpponents`), and the
  variant should have one reading of its seating.
- **Site**: `Parun.Engine.Visibility.reviewsHandOf`. The scenario
  `cr-811-5-a-teammate-reviews-a-hand-once-the-seat-between-them-closes`.
- **Issue**: #6171.

## Whether a player leaving ends a control-on-entry replacement

- **Question**: CR 800.4a ends "any effects which give that player control
  of any objects" when they leave. Does that reach a floating replacement
  making permanents enter under their control (Gather Specimens), for objects
  that do not exist yet?
- **Rules**: CR 800.4a, 109.5, 616.1b, 800.4b; CR of 2026-09-25.
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

## Which range a tally of what happened reads through

- **Question**: CR 801.11 hides events outside a controller's range; CR 800.4i
  and the rulings below keep a departed player's record. Under a limited range,
  (a) does a tally over an earlier turn use the range now or the range when the
  event happened, given CR 801.2c re-determines it as each turn begins and a
  player who left before this turn holds no seat? (b) Does damage or a loss
  count when its source is outside the range and the player it happened to is
  inside?
- **Rules**: CR 801.11, 801.2c, 801.7a, 800.4i, 801.18; CR of 2026-09-25.
  Rulings: Skewer the Critics (2024-01-12), Florian, Voldaren Scion
  (2021-09-24), Tymna the Weaver, Chandra's Incinerator. None speaks to a
  limited range.
- **Decision**: (a) the range as the tally is read. A seat emptied this turn is
  judged by where it stood, CR 801.7a's reading; a player who left in an earlier
  turn is in nobody's range, so Feast on the Fallen does not see them. (b) The
  cut asks only about the player the tally names: "an opponent who was dealt
  damage" is information about that opponent, so an in-range opponent counts
  whoever dealt it.
- **Rejected**: (a) the range when the event happened. The text allows it equally;
  it lost on cost, needing last turn's seats kept for a board needing both a
  limited range and a departure. (b) Requiring the whole event in range: that is
  CR 801.7's wording for a trigger event, and CR 801.11 does not repeat it.
- **Site**: `Parun.Engine.Count.historyPlayersFor`; scenarios
  `feast-on-the-fallen-does-not-see-a-seat-emptied-last-turn-under-a-range`
  and `furious-spinesplitter-counts-damage-from-a-source-outside-range`.
- **Issue**: #5878.

## Which active player a targeting ability names under shared team turns

- **Question**: Arcum's Whistle, Nettling Imp and Norritt target "creature the
  active player has controlled continuously since the beginning of the turn".
  Under shared team turns CR 805.9 has the ability's controller choose which
  active player that is as the effect is applied, after CR 608.2b's recheck.
  Is the target judged against one named player, and may the controller name
  an active player other than the target's controller, so that on the Whistle
  "that player" who may pay is someone else?
- **Rules**: CR 805.9, 805.4a, 601.2c, 608.2b, 608.2c; CR of 2026-09-25. The
  cards' rulings (Arcum's Whistle 2013-09-20, Nettling Imp 2004-10-04) are on
  combat, not teams.
- **Decision**: The target names the player. Both checks admit a creature of
  any active player, and as the effect applies the only active player the text
  can refer to is the one who has controlled the target since the turn began,
  its controller; the controller is not asked. On the Whistle that player pays.
- **Rejected**: Naming one player at CR 608.2b's recheck and judging the target
  against them: CR 805.9 places the choice when the effect is applied, after the
  recheck, and it would let a controller turn their own ability into a no-op.
  Naming any active player as the effect applies: it makes "that player" one
  the text's own description of the target does not fit.
- **Site**: `Parun.Engine.Filter.matches`'s `ControlledByRole` arm and
  `data/cards/arcums-whistle.json`'s `HolderOfBound` payer, proved by the
  scenario "CR 805.9 Arcum's Whistle asks the target's controller to pay, the
  active player its target names".
- **Issue**: #5458.

## A silenced entry silences its departure

- **Question**: Hushwing Gryff's "creatures entering don't cause abilities to
  trigger" names the entry. A creature card returned from a graveyard to the
  battlefield is one zone change, which a "whenever a card leaves your
  graveyard" ability (Spirit Mascot, Kishla Skimmer) also watches. Does that
  ability trigger?
- **Rules**: CR 603.6a, 603.6c, 603.10a, 613.11; CR of 2026-09-25. Rulings:
  Hushwing Gryff, Torpor Orb and Tocatli Honor Guard ("the trigger event
  doesn't have to specify 'creatures' entering"), Hushbringer 2019-10-04 (a
  "leaves the battlefield" trigger does not trigger on a creature dying).
- **Decision**: No. Every trigger the entering zone change satisfies is
  silenced, whichever side of the move its condition names. By the same
  reading, Yarok, the Desecrated (CR 603.2d) makes every such trigger of a
  permanent its controller controls trigger an additional time.
- **Rejected**: Silencing only the CR 603.6a enters abilities. The entry rulings
  say the event need not be phrased as creatures entering, and Hushbringer's
  ruling silences the other-side wording ("leaves the battlefield") of a
  silenced dying. Reading the entry half by that mirror leaves no ground for
  sparing the departure half.
- **Site**: `Parun.Engine.Event.Match.entryTriggers` and
  `additionalEntryTriggers`. Proved by the scenarios "Hushwing Gryff silences
  a leaves-your-graveyard trigger on a reanimated creature" (Spirit Mascot),
  "Hushwing Gryff silences a reanimated card's own leaves-your-graveyard
  trigger" (Oglor's grant) and
  yarok-the-desecrated-doubles-a-leaves-your-graveyard-trigger-on-a-reanimated-creature.
- **Issue**: #5713.

## An entry's own triggers are the zone change's

- **Question**: A permanent can enter with counters on it (a Saga's lore
  counter, CR 714.3a) or attached to something (an Aura). A chapter I ability,
  or a "whenever counters are put" or "becomes attached" ability, triggers on
  that. Does a permanent entering "cause" it, so that Yarok, the Desecrated
  makes it trigger an additional time and Hushwing Gryff silences it?
- **Rules**: CR 603.2c, 603.2d, 603.6a, 603.6d, 613.11, 122.6, 303.4f, 608.3c,
  714.2b, 714.3a; CR of 2026-09-25. No ruling: none of Yarok, Panharmonicon, Elesh Norn, Mother of
  Machines, Torpor Orb or any Saga has one on it.
- **Decision**: No. Only abilities triggering on the zone change itself are
  multiplied or silenced. A counter put as the permanent enters is part of the
  entry event (CR 603.6d, 714.3a) and an attachment made as it enters comes with
  the move (CR 303.4f, 608.3c), but the trigger event of such an ability is the
  counter or the attachment, not the permanent entering (CR 714.2b, 122.6; The
  Raven's Warning, 2021-02-05).
- **Rejected**: Treating every event that happens because a permanent entered
  as caused by the entry. CR 714.2b's trigger event is the lore counter being
  put, which CR 122.6 counts whether or not the Saga is entering, so the
  entry is at most its occasion.
- **Site**: `Parun.Engine.Event.Match.entryTriggers` and
  `additionalEntryTriggers`, which `Parun.Engine.Event.Trigger.eventTriggers`
  asks only of a move onto the battlefield. Proved by the scenario
  yarok-the-desecrated-doesn-t-double-a-saga-s-chapter-i.
- **Issue**: #5837.

## Whether assigning no combat damage beats assigning toughness

- **Question**: Gauntlets of Light's creature assigns combat damage equal to its
  toughness; Cloak of Confusion's may has it assign none this turn. Neither
  changes a characteristic (CR 613.11). Does the newer win, does none hold
  whichever came first, or does its controller choose?
- **Rules**: CR 510.1a, 613.11; CR of 2026-09-25. No ruling on either card.
  Narod, the Beige Flower's, of 2024-11-08 (Mystery Booster 2 playtest): "If
  there are multiple effects that attempt to modify how a creature assigns
  combat damage, that creature's controller chooses which effect applies", its
  example being Narod and Doran, the Siege Tower.
- **Decision**: None holds. CR 613.11's timestamp order applies both, and either
  order gives none: the toughness effect changes which number CR 510.1a reads,
  and the other says no number is assigned.
- **Rejected**: Last timestamp wins, under which a toughness effect arriving after
  the may would restore the damage the player traded away. The controller's
  choice, Narod's ruling: its words reach this pair, so the rejection rests on
  scope alone. It is a playtest card's note, those notes assuming "basic game
  rules would be updated", and neither the CR nor a printed card's ruling gives
  the choice. Under it a player who took the may could force the discard and
  still deal toughness damage; adopting it means a prompt at CR 510.1, not this
  order.
- **Site**: `Parun.Engine.Projection`'s `AssignCombatDamage` arm, by
  `CombatDamageAmount`'s order, proved by the scenarios
  "assigning-no-combat-damage-beats-an-older-toughness-marker" and "...-newer-...".
- **Issue**: #5462.

## Whether a total cost of {0} opens a mana window

- **Question**: Ornithopter's total cost is {0}. Does it "include a mana payment",
  giving its caster a chance to activate mana abilities (and Channel's life for
  mana) between choosing targets and paying? Observable: a mana ability that
  sacrifices a spell's target can be activated mid-cast only if it does.
- **Rules**: CR 118.5, 601.2f, 601.2g, 602.2b, 605.3a; CR of 2026-09-25. No ruling.
  CR 601.2f calls a reduced mana component {0}, and CR 118.5 says such a cost
  "requires no resources" and is still paid by acknowledging it. A cast with no
  mana cost to pay at all (CR 118.9) has no mana payment, forced.
- **Decision**: No window. A cost requiring no mana asks for no mana payment.
  Covers a printed {0}, a reduction to it, an alternative cost of {0}, X
  announced as 0, and Phyrexian symbols all announced as life (Mutagenic Growth).
- **Rejected**: A window at {0}, reading "mana component" as a mana payment of
  nothing. It splits a printed {0} from a free cast, which `Cost.mana` does not
  (`data/cards/ornithopter.json`'s cost is empty), and from a combat toll of {0},
  where CR 508.1i's and CR 509.1e's "If any of the costs require mana" forces no
  window.
- **Site**: `Cost.requiresNoMana`, read by `Cost.paySubstitutingReadingThen` and
  `Cost.payToll`, proved by the scenarios
  channel/channel-asks-nothing-of-a-free-cast,
  channel/channel-asks-nothing-when-x-is-zero,
  channel/channel-asks-nothing-of-a-gate-of-zero,
  channel/channel-asks-nothing-of-phyrexian-mana-paid-in-life and, for the toll,
  channel/channel-asks-nothing-of-a-toll-of-zero.

## Who pays Quenchable Fire's price once the planeswalker changes hands

- **Question**: Quenchable Fire's target is a planeswalker, which changes
  controllers before the caster's next upkeep. "That planeswalker's controller
  pays {U}": the player who controlled it as the spell resolved, or whoever
  controls it when they pay? The card's rulings speak only of a targeted player.
- **Rules**: CR 116.2c, 608.2c (CR of 2026-09-25).
- **Decision**: The controller as the spell resolves. The offer's seat is sampled
  once, as for every CR 116.2c offer.
- **Rejected**: Whoever controls it at payment, under which the offer moves with
  the planeswalker. The sentence names no later moment to ask again.
- **Site**: `Parun.Types.UntilPaid`'s `payer`, sampled by `Parun.Engine.Expiry.arm`.
  No test changes the planeswalker's controller.
- **Issue**: #6084.

## Whether a permanent's counters are divided among simultaneous damage

- **Question**: Rock Hydra has 3 +1/+1 counters and two creatures deal it 2 each
  at once, one with lifelink. "For each 1 damage ... if it has a +1/+1 counter
  on it" names no order. Does each event see all 3, and if not, who says which
  damage the counters stop? The lifelink observes it.
- **Rules**: CR 615.7, 615.10, 616.1 (CR of 2026-09-25). CR 615.7's division is
  of a shield a resolution made, CR 615.10's static effect holds no count, and
  the card's rulings don't speak to it.
- **Decision**: One supply, 1 counter for 1 damage, divided by the Hydra's
  controller as CR 615.7 divides a shield.
- **Rejected**: Each event reading all the counters, as CR 615.10's static
  shield applies separately: it would stop 4 damage for 3 counters. An order
  fixed by the engine: that makes a player's choice.
- **Site**: `Parun.Engine.Replacement`'s `allocationSupply`. The scenarios
  rock-hydra-divides-its-counters-away-from-the-lifelink and
  rock-hydra-divides-its-counters-onto-the-other-blocker.
- **Issue**: #6276.

## Camouflage's piles are block requirements

- **Question**: "Each creature in a pile that can block the creature that pile
  is assigned to does so." Where a pile's creatures can each block its attacker
  but not all together (Charging Rhino), or a block costs something (Archangel
  of Tithes), which block? And under Odric, Master Tactician, who divides?
- **Rules**: CR 509.1, 509.1b, 509.1c, 613.11, 700.3 (CR of 2026-09-25). The
  card has no rulings.
- **Decision**: The defending player still declares blockers, barred from any
  pair a pile does not hold, with each pile's pair a CR 509.1c requirement:
  the declaration must obey as many as can be, a cost to block excusing one.
  Where obeying them all is legal and free, it is made without asking. A later
  Odric row hands both the division and that declaration to its controller,
  in CR 613.11's timestamp order.
- **Rejected**: Each pile's able creatures blocking regardless, which builds
  an illegal block. The engine choosing among the ways to obey: that makes a
  player's choice. Dropping a pile that can't block whole, as Forge does,
  which blocks with fewer than can.
- **Site**: `Parun.Engine.Combat`'s `blockScopeGiven`, `blockCeilingGiven`
  and `pileChooser`. The scenarios under `data/scenarios/camouflage/`.
- **Issue**: #5464.
