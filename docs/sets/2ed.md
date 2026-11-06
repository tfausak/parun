# Unlimited Edition census

The Unlimited Edition (2ED) cards not yet in the pool, and which wait on a capability.
Derived 2026-11-05 from MTGJSON's set list against `data/cards/`. Re-derive the
missing list by writing the set list as a deck (`1 Name` per line) and running
`parun deck` on it: every unresolved name is reported.

## Expressible today

Every expressible Unlimited Edition card has been added to `data/cards/`.

## Needs a capability

Nothing: every Unlimited Edition card but Chaos Orb is in the pool.

## Out of scope

- Chaos Orb: a dexterity card, out of scope by `docs/design.md` section 6
  (#250).

## How it went

Finished 2026-11-06.

| Route | Cards | PRs |
| --- | --- | --- |
| Translated (census) | 8 | #6372 |
| Hand-written | 5 | #6389 |
| Behind a capability | 6, plus 4 from other sets | below |

- Census trend: the first dry run translated 8 of the 20 missing; 6 needed a
  capability, and Chaos Orb is out of scope. No hand-batch verdict was
  overturned.
- Capability issues, hardest first: #5464 Camouflage (#6390), #5463 Raging
  River (#6412), #4133 Cyclopean Tomb (#6433), #5746 whole-turn skip (#6436,
  Meditate and Eater of Days), #6204 Time Vault (#6438, plus Fasting), #5005
  False Orders (#6440, plus Ydwen Efreet), #6371 Forcefield (#6454).
- Filed along the way: #6437 (a departed player's extra turn lost under shared
  team turns), #6445 (General Jarkeld's switch skips blocker counts).
- Audits: 7 of 7 capability PRs; 5 found rules defects. Skipped the census and
  hand batch (card data only).
  - #6390: piles counted the whole team's attackers under shared team turns;
    the division was not simultaneous.
  - #6433: any Cyclopean Tomb hid every counter loop from loop detection.
  - #6436: a departed teammate's seat swept the live teammate's "until your
    next turn" effects ahead of a skipped team turn.
  - #6438: the loop check ignored spent floating rows, forcing a decline where
    no loop existed.
  - #6440: an effect-made block skipped set-shaped restrictions (menace,
    Charging Rhino).
- Cost (`script/session-tokens.sh` over the set's transcripts, the last unit
  measured before its merge; the census and hand batch as logged): cache reads
  0.23B, cache writes 3.4M, output 1.06M; 12.2M cache reads per card. The
  costliest units, audits and fixers counted: #6433 (48.3M), #6436 (39.3M),
  #6438 (33.5M). Wall clock ~14h, one build lane.
- Owner review:
  - #6372: #5468 lists Unlimited as not in scope yet, but this run did it.
  - #6390: decisions.md "Camouflage's piles are block requirements".
  - #6412: `Effect.ChooseSector` widened to `Effect.ChooseGroup`, a wire change.
  - #6436: decisions.md "Where a skipped Grand Melee turn leaves its marker".
  - #6438: decisions.md "Who is the active player while a turn is skipped".
  - #6440: decisions.md "What a creature an effect makes block may block";
    `Effect.RemoveFromCombat` wire change.
  - #6454: `NextDamageOutcome` moves from a bare string to a tagged object.
