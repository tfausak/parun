# Seventh Edition census

The Seventh Edition (7ED) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-23 from MTGJSON's set list against `data/cards/`.
The set list is `data/decks/sets/7ed.txt`, which the suite reads, so every card
of the set stays in the pool.

## Expressible today

Every expressible Seventh Edition card has been added to `data/cards/`.

## Needs a capability

Nothing. Every Seventh Edition card is in the pool.

## How it went

Finished 2026-10-23.

| Route | Cards | PRs |
| --- | --- | --- |
| Translated (census) | 60 | #5539 |
| Hand-written | 39 | #5541 |
| Behind a capability | 10, plus 12 from other sets | below |

- Census trend: the first dry run translated 60 of the 109 missing; 10
  needed a capability.
- Capability issues, hardest first: #5530 Sacred Ground (#5542), #5531
  Static Orb (#5543), #5532 Okk (#5545), #5087 Ensnaring Bridge (#5546; stays
  open for Zar Ojanen), #5174 Disorder (#5544; stays open for Desolation),
  #5533 Mana Clash (#5544), #5534 Phyrexian Colossus (#5547), #5535 Coat of
  Arms (#5546), #5536 Persecute (#5544), #5537 Gang of Elk (#5547).
- Filed along the way: #5540 (Obstinate Baloth's discard cause; closed in M11
  by #5618).
- Audits: none.
- Subagent tokens: census not recorded; hand 421k; capability 382k (#5542),
  255k (#5543), 407k (#5544), 307k (#5545), 355k (#5546), 309k (#5547).
  Total 2.44M without the census, 22.3k per card. Wall clock ~3.5h after the
  census; two lanes.
- Owner review:
  - #5542: decisions.md "What a spell or ability causes".
  - #5543: decisions.md "An untap cap leaves tapped only what it must".
  - Wire changes: #5544 (`ObjectRef.Players`, `Filter.Controls`,
    `Effect.ChooseQuality`), #5546 (`SharesCreatureTypeWith` takes an
    anchor; `AffectedUnless.amount`), #5547 (`BlockersBeyond` takes a
    number; `LimitUnless.comparison`).
