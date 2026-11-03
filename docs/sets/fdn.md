# Foundations census

The Foundations (FDN) cards not yet in the pool, and which wait on a capability.
Derived 2026-11-02 from MTGJSON's set list against `data/cards/`. Re-derive the
missing list by writing the set list as a deck (`1 Name` per line) and running
`parun deck` on it: every unresolved name is reported.

## Expressible today

Every expressible Foundations card has been added to `data/cards/`.

## Needs a capability

Nothing. Every Foundations card is in the pool.

## How it went

Finished 2026-11-03.

| Route | Cards | PRs |
| --- | --- | --- |
| Translated (census) | 112 | #5919 |
| Hand-written | 217 | #5920 (20), #5922 (19), #5925 (18), #5927 (19), #5928 (18), #5930 (20), #5931 (20), #5932 (20), #5935 (20), #5938 (20), #5945 (23) |
| Behind a capability | 18, plus 3 from other sets | below |

- Census trend: the first dry run translated 112 of the 347 missing; 10
  needed a capability at the census, 18 in the end (the hand batches overturned
  8 verdicts).
- Capability issues, hardest first: #5910 Curator of Destinies (#5948), #5911
  Muldrotha, the Gravetide (#5951), #5912 Tinybones, Bauble Burglar (#5957),
  #5913 Liliana, Dreadhorde General (#5960, no capability needed), #5914
  Fishing Pole (#5961), #5942 Vizier of the Menagerie (#5962), #5915 Steel
  Hellkite (#5964), #5916 Goblin Negotiation (#5971), #5921 Cat Collector and
  Vanguard Seraph (#5974), #5926 Exemplar of Light (#5977), #5923 Divine
  Resilience (#5978, no capability needed), #5924 and #5929 Deadly Brew and
  Fiendish Panda (#5979; #5929 no capability needed), #5636 Fiery Annihilation
  (#5981, the issue's other half stays open), #5917 Run Away Together (#5983),
  #5918 Courageous Goblin and Ruby, Daring Tracker (#5984, no capability
  needed). Other-set cards: Tangled Florahedron, Pestilent Spirit, Pristine
  Talisman.
- Filed along the way: #5933 (a later payer of a shared cost isn't told an
  earlier choice), #5934 (a sacrifice made for mana shares the payments' one
  event), #5949 (a permission by prototyped mana value), #5958 (a sacrifice
  trigger finding a card redirected to another public zone), #5959 (a later
  chooser in a loop isn't shown earlier picks), #5963 (Consume Spirit's X under
  a spend-as-though clause), #5976 (tribute's counters credited to the
  controller), #5980 (a token returned to a hand counts as a card), #5982
  (consecutive destroys are two steps).
- Audits: 8 of 15 capability PRs (#5948, #5960, #5961, #5978, #5981, #5983,
  #5984 skipped: nothing shared changed), plus hand batches #5930, #5932 and
  #5945; findings went to a fresh fixer where they needed one, and none was
  re-audited. 6 found rules defects:
  - #5930: older siblings of a departed damage source's blank zone: Pyromancer's
    Gauntlet counted a cycled instant card as a spell, and Judgment of
    Alexander's trigger fired for a creature card.
  - #5932: Perforating Artist's payments were sequential where its ruling says
    simultaneous.
  - #5951: an MDFC's land face was unplayable under a Play permission; a search
    cast lost narrowed candidates; Savage Summoning was spent by a bestowed
    spell.
  - #5957: CR 400.7k on Tinybones' own activation path.
  - #5971: deathtouch's flat excess threshold on a creature already at lethal.
  - #5979: a token awaiting CR 704.5d was offered as a card by
    `Replacement.graveyardCandidates` and `legalCopyTargets`.
- Cost (`script/session-tokens.sh` over the set's transcripts, 28 sessions and
  18 agents, before this unit's last turns): cache reads 0.26B, cache writes
  8.5M, output 2.9M; 0.75M cache reads per card. The costliest units: #5957
  (26.5M), #5945 (21.6M), #5932 (21.4M). Wall clock ~23h.
- Owner review:
  - #5957: decisions.md "How a mana of any type rider combines with an
    only-clause" and "What moved a madness card"; #5958, which no ruling
    settles.
  - #5932: payers now choose before anything happens (#5933 needs a prompt
    payload decision); `Object.castBy` in the `Object` codec.
  - #5960: #5959 needs a prompt payload decision.
  - #5961: a Fishing Pole another player controls can pay (forced by CR
    701.26a, cited in its scenario).
  - #5962: #5963; one sentence added to the any-type rider's decisions.md entry.
  - #5964: `sourceDealtDamageEarlier` has no card, kept and disclosed as a
    fence.
  - #5979: `sameBefore` can add a mana-source prompt on a rare board (audit
    finding overruled); the wide `Game.cardsIn` sweep.
  - #5983: #4865's question narrowed by a ruling; #5982's scope.
  - Wire-format changes: #5945 `EventShape.SpellCast` window, #5948
    `faceUpPile`, #5957 `spending`, #5962 `casting`, #5964 `dealer` and
    `HolderOfCandidate`, #5971 `excessTally`, #5974 `PlayerGainsLife`
    (18 cards rewritten) and `LifeGained.first`, #5977 `CounterPlacement.putter`
    and `CountersPut.putter`, #5979 `Filter.BeforeMove`.
