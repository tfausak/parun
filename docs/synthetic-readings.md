# Synthetic readings

Readings parun has chosen on boards only a synthetic card can build. No printed
card can tell them from the alternative, so they fail `docs/decisions.md`'s bar;
each records the reading and its synthetic test so nobody re-derives it. If a
printed card reaches one, or a CR update or a ruling settles it, re-check it, then
move it to `docs/decisions.md` or drop it.

Entries take `docs/decisions.md`'s format and order.

## Whether a skipped ending phase removes marked damage

- **Question**: CR 614.10a takes a skipped cleanup step's actions with it, but the
  turn still ends. Does marked damage come off?
- **Rules**: CR 120.6, 500.11, 514.2, 611.2a, 614.10a; CR of 2026-09-25.
- **Decision**: Yes, with the durations, as one action. A 5/4 (pumped 2/1) with 3
  damage survives as a 2/1 with no damage.
- **Rejected**: Durations end and damage stays, so the 2/1 dies to CR 704.5g. The
  2026-11-04 audit preferred this, moderate confidence, on CR 120.6's and CR
  614.10a's words.
- **Site**: `Parun.Engine.Engine.cleanupSecondAction`, proved on Synthetic Curfew
  Bell by the scenario
  `cr-514-2-a-pumped-creature-with-damage-marked-on-it-neither-dies-to-its-own-shrinking`.
- **Issue**: #491.

## Whether a target drawn out of a face-down pile is revealed

- **Question**: CR 406.4 says a card drawn at random out of a face-down pile while
  casting a spell or activating an ability "isn't revealed until after that cost
  is fully paid". Its "that cost" has no antecedent for a target, and no rule orders
  a reveal. Is the card revealed at all?
- **Rules**: CR 406.4, 601.2i, 602.2b, 701.20a; CR of 2026-09-25.
- **Decision**: Yes. Once the cost is paid and the spell becomes cast (CR 601.2i),
  or the ability becomes activated (CR 602.2b), the caster reveals the drawn card
  to every player. Until then nobody sees it, the caster included.
- **Rejected**: No reveal at all, reading the sentence as forbidding only an early
  one (owner, 2026-10-21).
- **Site**: `Parun.Engine.Cast.castProposed` and
  `Parun.Engine.Activate.activateAbilityWith`, revealing what
  `Parun.Engine.Target.chooseTargets` drew; proved on Synthetic Blind Reclamation
  by `Parun.ExileSpec`'s "CR 406.4 the card drawn for a spell's target is hidden
  while it is paid for, and revealed to both seats once cast" and its activation
  twin.
- **Issue**: #2568.

## Whether a cast redirected off the stack is still a cast

- **Question**: A CR 614 replacement sends a card being cast somewhere other
  than the stack (Synthetic Stack Interdiction). Does the cast rewind, stop,
  or complete?
- **Rules**: CR 601.2i, 601.2a, 601.2e, 614.6, 709.3a, 709.4; CR of
  2026-09-25.
- **Decision**: Only the arrival is replaced. CR 601.2b-i run on: targets
  chosen, costs paid, and the spell becomes cast, so "whenever you cast"
  triggers fire. The card shows CR 709.4's combined view where it lands.
- **Rejected**: Rewinding: CR 601.2's preamble returns the game when a player can't
  comply with a step, CR 112.1 leaves no spell for the later steps, and a cancelled
  move does rewind. But here the step was carried out as modified (CR 614.6).
  Stopping partway: no rule ends a cast midway.
- **Site**: `Parun.Engine.Cast.castSpellWith`, the `Event.changeZoneCasting`
  step, proved by `Parun.CastRestrictionSpec`'s "CR 601.2i a cast redirected
  off the stack is still a cast" and "CR 709.4 a cast redirected off the stack
  keeps both halves".
- **Issue**: none; #781 settled the face ordering beside it.

## Whether conjuring into a library is a library move for a mana ability

- **Question**: CR 605.1a disqualifies a mana ability whose effect moves a
  card to or from a library. A conjured card comes from no zone.
- **Rules**: CR 605.1a; no rule names conjure; CR of 2026-09-25.
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

## What a mandatory blight puts its counters on when no creature can take them

- **Question**: An effect says "blight N" and every creature the player
  controls can't have -1/-1 counters put on it (Solemnity, Melira, Sylvok
  Outcast). Does the player still choose one, so the blight happens, or is it
  CR 101.3's no-op? Where some creature can take them, CR 608.2d forbids
  choosing one that can't.
- **Rules**: CR 608.2d, 609.3, 701.68a, 701.68b, 701.68c, 701.68d; High Perfect
  Morcant's and Shadow Urchin's rulings of 2025-11-17; CR of 2026-09-25.
- **Decision**: The player chooses among every creature they control, nothing
  is put, and they have blighted: the chosen creature is CR 701.68c's
  "blighted creature" and "whenever a player blights" triggers.
- **Rejected**: No choice and no blight, which reads CR 608.2d's impossible
  option as emptying the pool. CR 609.3 has the effect do as much as it can,
  and choosing the creature can be done; CR 701.68d's "regardless of what
  events actually occurred" says a blight putting nothing still counts.
  High Perfect Morcant and Shadow Urchin, both mandatory, carry the ruling "If you
  can't place -1/-1 counters on any creatures you control ... you can't choose to
  blight"; printed beside a ruling about blight costs neither card has, it reads
  as CR 701.68b's limit on a choice, and this entry takes it so.
- **Site**: `Parun.Engine.Blight.instructed`, proved by
  `Parun.EventTriggerSpec`'s "CR 701.68d Solemnity keeps every counter off
  and the Chronicler still triggers", on Synthetic Blight Chronicler: no printing
  reads a mandatory blight.
- **Issue**: #5830.

## How two only-clauses about spending one mana combine

- **Question**: Two effects each say a mana may be spent "only as though it
  were" a different type. Which types may it be spent as?
- **Rules**: CR 609.4b, 101.2, 613.11; CR of 2026-09-25.
- **Decision**: The union of the clauses' sets, unordered. An "only" clause
  names permitted types rather than saying "can't".
- **Rejected**: Each "only" as a prohibition, which pulls in CR 101.2 and has
  the two clauses forbid each other's types.
- **Site**: `Parun.Engine.Mana.spendableAs`, proved by the scenario "CR 609.4b
  two only-clauses about one red mana each permit their own type" on
  Celestial Dawn and Synthetic Verdant Prism: Celestial Dawn is the one
  printing with such a clause.
- **Issue**: none.

## Which half of a split card answers for a box both halves have

- **Question**: CR 709.4 combines a split card's halves, but a power,
  toughness, loyalty, defense, intensity or vanguard box can be had only
  once. Which half answers when both print one, or when both halves'
  characteristic-defining abilities define it?
- **Rules**: CR 709.4, 208.1, 208.5, 604.3, 613.4, 613.4a, 613.7a, 613.8,
  709.4a, 709.4b, 709.4c; CR of 2026-09-25.
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
