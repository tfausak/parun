# Fourth Edition census

The Fourth Edition (4ED) cards not yet in the pool, and which wait on a
capability. Derived 2026-11-04 from MTGJSON's set list against `data/cards/`.
The set list is `data/decks/sets/4ed/all.txt`, which the suite reads, so every card
of the set stays in the pool.

## Needs a capability

Nothing: every Fourth Edition card is in the pool.

## How it went

Finished 2026-11-04.

| Route | Cards | PRs |
| --- | --- | --- |
| Translated (census) | 19 | #6089 |
| Hand-written | 48 | #6110, #6132, #6138 |
| Behind a capability | 10, plus 1 from other sets | below |

- Census trend: the first dry run translated 19 of the 77 missing; 9 needed a
  capability. Power Leak, the tenth, moved there from a hand batch.
- Capability issues, hardest first: #6081 Balance (#6109), #6082 Tetravus
  (#6123), #6083 Power Surge (#6137), #6084 Nafs Asp (#6143), #6085 Channel
  (#6158), #6086 Magnetic Mountain (#6149), #6128 Power Leak (#6151), #6087
  Aladdin's Lamp (#6226), #6088 Erosion (#6259), #5995 Coral Helm (#6092, in
  the Fifth Edition run). From other sets: Quenchable Fire. Balance, Magnetic
  Mountain and Erosion needed no engine change: the DSL already composed them.
- Filed along the way: #6128 (Power Leak's one-instruction shield).
- Audits: 6 of 9 capability PRs, and hand batch #6132; 5 found rules defects.
  Skipped as card data with no shared reader: #6109, #6110, #6149, #6259, and
  #6138, whose one engine change has two readers.
  - #6123: a phased-out permanent was still acted on through a reserved slot or
    a group (Tetravus, Fishing Pole, Thatcher Revolt).
  - #6132: Mishra's War Machine tapped when its damage was redirected away.
  - #6143: under shared team turns a delayed step trigger hit the active player
    rather than the seat it captured (Nafs Asp, Elkin Lair).
  - #6158: Channel was offered with no mana payment to make, and a toll of {0}
    opened a mana window (a second audit round).
  - #6226: a token shuffled into a library counted as a card atop it (the Lamp,
    Abundance, Zur's Weirding, Chains of Mephistopheles' mill).
- Cost (`script/session-tokens.sh` over the set's transcripts): cache reads
  0.26B, cache writes 10M, output 2.1M; 3.4M cache reads per card. The costliest
  units, audits and fixers counted: #6158 (42.1M), #6132 (27.6M), #6143 (26.4M).
  Wall clock ~15h, two build lanes, including 3h20m lost to a mutation that
  looped the engine until the owner killed it.
- Owner review:
  - #6151: decisions.md "Whether an ability's own "prevent" is a
    self-replacement", read as one, so Power Leak gives no CR 616.1e choice.
  - #6158: decisions.md "Whether a total cost of {0} opens a mana window", which
    removes `ChooseExtraManaSource` at {0} (248 scenarios lost that answer).
  - #6143: decisions.md "Who pays Quenchable Fire's price once the planeswalker
    changes hands"; Synthetic Standing Bounty deleted for the real card.
  - #6137: decisions.md "Whether "at the beginning of this turn" sees an effect
    lasting until that turn", unproven by a scenario.
  - #6109: the fewest across players is `Negate` over `Greatest`, with no `Least`
    arm.
  - Breaking wire: #6143 (`UntilPaid`'s payer, `PaidExpiry`'s resolution).
