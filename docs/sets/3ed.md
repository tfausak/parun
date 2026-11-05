# Revised Edition census

The Revised Edition (3ED) cards not yet in the pool, and which wait on a capability.
Derived 2026-11-05 from MTGJSON's set list against `data/cards/`. Re-derive the
missing list by writing the set list as a deck (`1 Name` per line) and running
`parun deck` on it: every unresolved name is reported.

## Expressible today

Every expressible Revised Edition card has been added to `data/cards/`.

## Needs a capability

Nothing: every Revised Edition card is in the pool.

## How it went

Finished 2026-11-05.

| Route | Cards | PRs |
| --- | --- | --- |
| Translated (census) | 8 | #6281 |
| Hand-written | 13 | #6305 |
| Behind a capability | 5 | below |

- Census trend: the first dry run translated 8 of the 26 missing; 5 needed a
  capability. No hand-batch verdict was overturned.
- Capability issues, hardest first: #6275 Guardian Angel (#6307), #6276 Rock
  Hydra (#6323), #6277 Jandor's Ring (#6343), #6278 Reverse Polarity (#6353),
  #5067 Fastbond (#6357).
- Filed along the way: #6358 (a land-play trigger's "if" read after a whole
  instruction rather than each land; Brilliant Ultimatum).
- Audits: 4 of 5 capability PRs; 2 found rules defects. Skipped #6343 (one enum
  value on a read only its filter uses) and the census and hand batch (card
  data only). #6307's audit found two vacuous tests; #6357's a latent defect no
  pool card reaches, filed as #6358.
  - #6323: Rock Hydra's counters left mid-batch, a division of nothing was
    prompted, and counters sat idle beside dealt damage.
  - #6353: a source the batch turned face up kept stale damage riders
    (deathtouch, lifelink lost on sibling events), a defect predating the PR.
- Cost (`script/session-tokens.sh` over the set's transcripts, the last unit
  measured before its merge): cache reads 0.08B, cache writes 3.3M, output
  0.78M; 3.1M cache reads per card. The costliest units, audits and fixers
  counted: #6357 (19.5M), #6323 (15.2M), #6353 (15.2M). Wall clock ~10h, one
  build lane.
- Owner review:
  - #6323: decisions.md "Whether a permanent's counters are divided among
    simultaneous damage"; `Replacement.unpaidDamage` changes `PreventNext`
    shields generally.
  - #6353: `asDealt` rereads riders only for a source the batch turned face up,
    a scope choice.
  - #6357: `CardsDiscardedThisTurn`, `CardsDrawnThisTurn` and
    `BendingsThisTurn` folded into `Quantity.TalliedThisTurn` (wire tags kept).
  - Wire additions, all defaulted or new tags: `LaterPayment` and
    `laterPayments` (#6307), `PreventRemovingCounters` (#6323), `LastDrawn`
    (#6343), `DealtDamage.by` and `DamageEvent.dealtByCardTypes` (#6353),
    `LandsPlayedThisTurn` and an optional `PlaysLand.from` (#6357).
