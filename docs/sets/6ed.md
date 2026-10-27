# Sixth Edition census

The Sixth Edition (6ED) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-23 from MTGJSON's set list against `data/cards/`.
The set list is `data/decks/sets/6ed.txt`, which the suite reads, so every card
of the set stays in the pool.

## Expressible today

Every expressible Sixth Edition card has been added to `data/cards/`.

## Needs a capability

Nothing: every Sixth Edition card is in the pool.

## Decks

MTGJSON lists two 6ED decks, the preconstructed Deck A and Deck B. Neither is in
`data/decks/` yet, though every card of both is in the pool.

## How it went

Finished 2026-10-23.

| Route | Cards | PRs |
| --- | --- | --- |
| Translated | 105 | #5515 (67), #5518 (30), #5522 (8) |
| Hand-written | 75 | #5526 (50), #5528 (25) |
| Behind a capability | 21, plus 14 from other sets | below |

- Census trend: the census (#5502) predates the translator; its first run
  (#5515) translated 67 of the 201 missing. The census put 18 under a
  capability.
- Capability issues, hardest first: #5490 Illicit Auction (#5505), #5491
  Zur's Weirding (#5507), #5492 Amber Prison (#5508), #4491 Rowen (#5510),
  #5493 Forbidden Crypt (#5512), #5494 Doomsday (#5513), #5311 Juxtapose
  (#5516), #5310 Tariff (#5517), #5405 Library of Lat-Nam (#5523), #5495 Jade
  Monolith and Kjeldoran Royal Guard (#5521), #5496 Syphon Soul (#5527, with
  #5404), #5497 Mana Short and Power Sink (#5521), #5498 Mystic Compass
  (#5525), #5499 Dense Foliage (#5529), #5500 Primal Clay (#5521), #5501
  Crimson Hellkite (#5521). Found after the census: #5520 Regeneration
  (#5525), #5524 Derelor (#5538).
- Filed along the way: #5504 (the client hides a number prompt's bounds),
  #5511 (Forbidden Crypt's loss waits for the other draws), #5514 ("the
  greatest power among" outside an edict), #5519 (Vampire Bats; closed in
  10E by #5592).
- Audits: none.
- Subagent tokens: census not recorded; hand ~500k (#5526), ~460k (#5528);
  capability units not recorded; translator widening #5522 ~510k. Total not
  recorded (the run's own estimate was ~9M). Wall clock not recorded (the
  run's own estimate was ~26--30h); two lanes.
- Owner review:
  - #5510: decisions.md "How many times two draw-time reveals reveal one
    card" (pruned by #5608).
  - #5538: wire change, a cost increase's amount became a mana cost; a
    concurrent PR's card (Feroz's Ban, #5539) needed a fix after merge.
