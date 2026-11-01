# Magic Origins census

The Magic Origins (ORI) cards not yet in the pool, and which wait on a
capability. Derived 2026-10-29 from MTGJSON's set list against `data/cards/`.
The set list is `data/decks/sets/ori.txt`, which the suite reads, so every card
of the set stays in the pool.

## Expressible today

Every expressible Magic Origins card has been added to `data/cards/`.

## Needs a capability

Nothing. Every Magic Origins card is in the pool.

## How it went

Finished 2026-10-31.

| Route | Cards | PRs |
| --- | --- | --- |
| Translated (census) | 76 | #5755 |
| Hand-written | 105 | #5760 (17), #5761 (10), #5763 (9), #5766 (8), #5767 (9), #5769 (9), #5772 (8), #5774 (10), #5777 (8), #5780 (8), #5781 (9) |
| Behind a capability | 17, plus 7 from other sets | below |

- Census trend: the first dry run translated 76 of the 198 missing; 3
  needed a capability at the census, 17 in the end (the hand batches
  overturned 14 verdicts).
- Capability issues, hardest first: #5395 Demonic Pact (#5785), #4781
  Alhammarret's Archive (#5787), #5756 Alhammarret, High Arbiter (#5789),
  #5758 and #5759 Chandra, Fire of Kaladesh (#5790), #5757 Archangel of
  Tithes (#5791), #5765 and #5778 Harbinger of the Tides and Swift Reckoning
  (#5793), #5762 Exquisite Firecraft (#5794), #5779 The Great Aurora
  (#5795), #5764 Hallowed Moonlight (#5797), #4735 Jace, Vryn's Prodigy
  (#5800), #4564 and #5768 Mizzium Meddler (#5801, #5802), #5771 Psychic
  Rebuttal (#5803), #5770 Nissa's Revelation (#5804, no capability needed),
  #5776 Sphinx's Tutelage (#5805), #5775 Somberwald Alpha (#5806), #5754
  Tainted Remedy (#5808). Other-set cards: Chains of Mephistopheles, Ghitu
  Fire, Rout, Synthetic Hasty Hydra, Radiant Performer, Return the Favor,
  Spellskite.
- Filed along the way: #5773 (search truncates an over-long answer), #5782
  #5783 #5784 #5786 (mode memory gaps), #5788 (skipped first draw step),
  #5792 (Swift Reckoning counts itself), #5796 #5798 (zone-change redirect
  ordering), #5799 (graveyard land play, Kaldring), #5807 (sibling
  becomes-blocked-by conditions), #5809 (lifelink gain written before damage
  loss), #5810 (Rain of Gore).
- Audits: 16 of 17 capability PRs (#5804 skipped: data only), plus hand
  batches #5761 and #5780; findings went to a fresh fixer, and #5787, #5797
  and #5808 got a re-audit of the follow-up. 8 found rules defects:
  - #5785: an activated ability's "hasn't been chosen" memory was accepted
    and ignored.
  - #5787: Chains of Mephistopheles' discard was credited to the drawer; the
    follow-up's re-audit caught Plagiarize resetting the draw kind.
  - #5789: a chosen card name skipped an adventure's or MDFC's other face.
  - #5794: a batch counter judged spell mastery after part of its batch moved.
  - #5795: a melded permanent counted twice toward The Great Aurora's draw.
  - #5797: the entry redirect was judged before copy-entry rewrites; the
    re-audit caught a diverted copy still firing its "when you do".
  - #5800: an exile grant redirected into a graveyard became castable there.
  - #5808: filed as #5809 (predates the PR); the follow-up carried CR 614.5's
    applied set into nested funnels (Lich with Words of Worship).
  - Hand batch #5780: Talent of the Telepath read spell mastery after its
    first cast.
- Cost, approximate: `script/session-tokens.sh` then counted each API call
  once per content block, and the cloud transcripts are not at hand, so
  these are its figures over M19's measured overcount (1.85 reads, 1.86
  writes, 2.06 output). Cache reads ~0.88B (~0.74B over 70 agent sessions, ~0.14B
  orchestrating); cache writes ~13M; output ~3.4M; ~4.4M cache reads per
  card. The costliest units: #5760 (~61M), #5787 (~48M), #5780 (~41M),
  #5797 (~39M). Wall clock ~32h.
- Owner review:
  - #5787: decisions.md "Which draw is the first one drawn in a draw step";
    `ProposedEvent.WouldDraw` gained `DrawKind`; Baral, Chief of Compliance
    re-encoded with `ifTaken`.
  - #5793: decisions.md "A paid flash permission is offered at sorcery
    timing too"; synthetic card `synthetic-hasty-hydra`.
  - #5797: decisions.md "Whether a token an entry redirect takes was
    created"; elision #5798.
  - #5795: the `shuffled` slot keeps one arrival per moved object (a melded
    pair is one entry).
  - #5802: a mandatory one-target change answered "unchanged" takes the
    first swap (as `Game.among` does) rather than re-asking; the prompt
    still offers "unchanged".
  - #5807: filed with `area:triggers` only (a refactor, not a gap).
  - Wire-format changes: #5785 `Modal.memory`, #5787 `DrawR`/`DrawRewrite`,
    #5789 `ChooseCardName.among`, #5790 `Quantity` `DamageDealtThisTurn`,
    #5791 `AttackCost`/`BlockCost.while`, #5793 `CastingPermission`, #5794
    `Counterability` condition, #5795 `ChosenCardInHand` count, #5800
    `Object.playPermission` and `GrantPlayFromExile.zone`, #5801
    `Pool.SpellsAndAbilities`, #5802 `ChangeTargets` record, #5805
    `Aggregation.MostSharing`, #5806 `CreatureBecomesBlocked`, #5808
    `LifeGainRewrite.LoseInstead`.
  - Hand batch sizes cut from 20 to 10 after batch 1 cost 112M for 17
    cards; audits skipped on data-only and renderer-only hand batches and on
    the census.
  - Unverified, not filed: a scenario's scripted answers that no prompt
    asked for did not fail (possible harness leniency).
