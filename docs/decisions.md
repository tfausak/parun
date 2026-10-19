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
