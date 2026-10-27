# Ninth Edition census

The Ninth Edition (9ED) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-24 from MTGJSON's set list against `data/cards/`.
The set list is `data/decks/sets/9ed.txt`, which the suite reads, so every card
of the set stays in the pool.

## Expressible today

Every expressible Ninth Edition card has been added to `data/cards/`.

## Needs a capability

Nothing. Every Ninth Edition card is in the pool.

## How it went

Finished 2026-10-24.

| Route | Cards | PRs |
| --- | --- | --- |
| Translated (census) | 48 | #5564 |
| Hand-written | 45 | #5566 (22), #5568 (23) |
| Behind a capability | 5, plus 1 from another set | below |

- Census trend: the first dry run translated 48 of the 98 missing; 4 needed
  a capability.
- Capability issues, hardest first: #5560 Booby Trap (#5567), #5561 Seedborn
  Muse (#5569), #5562 Storage Matrix (#5570), #5563 Slate of Ancestry
  (#5572). Found by #5566: #5565 Consume Spirit (#5572).
- Filed along the way: #5571 (Drain Life's life gain capped by what its
  target had).
- Audits: none.
- Subagent tokens: census 254k; hand 346k, 230k; capability 358k (#5567),
  207k (#5569), 177k (#5570), 352k (#5572). Total 1.92M, 19.6k per card.
  Wall clock ~6h; two lanes.
- Owner review:
  - #5566: renderer `Target.Context.pumped`; lint widenings.
  - #5567: `Replacement.choose` skips the order question for a one-source
    choice; wire change `RevealsFirstDraw` to `RevealsDraw`.
  - #5569: the untap step untaps simultaneously across several active
    players.
  - #5572: decisions.md "Cost reductions on a confined X" (pruned by #5608);
    wire change, a discard's count became a `CardCount`.
