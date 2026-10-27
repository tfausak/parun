# Eighth Edition census

The Eighth Edition (8ED) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-24 from MTGJSON's set list against `data/cards/`.
The set list is `data/decks/sets/8ed.txt`, which the suite reads, so every card
of the set stays in the pool.

## Expressible today

Every expressible Eighth Edition card has been added to `data/cards/`.

## Needs a capability

Nothing. Every Eighth Edition card is in the pool.

## How it went

Finished 2026-10-24.

| Route | Cards | PRs |
| --- | --- | --- |
| Translated (census) | 57 | #5551 |
| Hand-written | 56 | #5552 (28), #5555 (28) |
| Behind a capability | 7, plus 4 from other sets | below |

- Census trend: the first dry run translated 57 of the 120 missing; 7
  needed a capability.
- Capability issues, hardest first: #4844 Thieves' Auction (#5553), #5549
  Death Pits of Rath, Noble Purpose and Curiosity (#5556), #4853 Star Compass
  (#5557; stays open for Squandered Resources), #5550 Shifting Sky and
  Distorting Lens (#5558).
- Filed along the way: #5554 (a creature dealt damage by two sources at once
  triggers twice).
- Audits: none.
- Subagent tokens: census 308k; hand 263k, 374k; capability 352k (#5553),
  297k (#5556), 225k (#5557), 170k (#5558). Total 1.99M, 16.6k per card.
  Wall clock ~7h; two lanes.
- Owner review:
  - #5553: decisions.md "When Thieves' Auction's repeated process ends" (an
    Aura ruling conflict); wire change `underOwner` to `under`, whose old key
    the decoder ignores silently.
  - #5555: a `FilterPositionLintSpec` change (`ChosenSourceFramed`).
  - #5556: wire change, the damage triggers renamed.
