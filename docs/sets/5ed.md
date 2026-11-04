# Fifth Edition census

The Fifth Edition (5ED) cards not yet in the pool, and which wait on a
capability. Derived 2026-11-03 from MTGJSON's set list against `data/cards/`.
The set list is `data/decks/sets/5ed.txt`, which the suite reads, so every card
of the set stays in the pool.

## Needs a capability

Nothing: every Fifth Edition card is in the pool.

## How it went

Finished 2026-11-04.

| Route | Cards | PRs |
| --- | --- | --- |
| Translated (census) | 40 | #5997 |
| Hand-written | 104 | #5998, #6001, #6003, #6008, #6011, #6013 |
| Behind a capability | 25, plus 5 from other sets | below |

- Census trend: the first dry run translated 40 of the 170 missing; 22 needed a
  capability. Drain Life, the other one, landed outside this run (#5975).
- Capability issues, hardest first: #5985 Game of Chaos (#6014), #5986 Sylvan
  Library (#6015), #5987 Dance of Many (#6016), #5988 Nether Shadow (#6028),
  #5989 Shapeshifter (#6030), #5991 Eye for an Eye (#6038), #5990 Clockwork
  Beast and Steed (#6048), #6010 Sacred Boon (#6049), #6002 Island Sanctuary
  (#6053), #6012 Venom (#6054), #5999 Errantry and #5994 Orcish Conscripts
  (#6056), #5177 Gauntlets of Chaos (#6057), #5462 Cloak of Confusion and
  Orcish Squatters (#6058), #5089 Funeral March (#6059), #5208 Mana Flare
  (#6061), #5216 Ghazbán Ogre (#6063), #4892 Personal Incarnation (#6065),
  #5686 Panic (#6071), #5992 Serra Bestiary (#6073), #5993 Instill Energy
  (#6078), #5995 Coral Helm (#6092), #5996 Orcish Farmer (#6100). From other
  sets: Confusion in the Ranks, Eloren Wilds, The Black Gate, Detention Vortex,
  Sonic Burst.
- Filed along the way: #6000 (Erg Raiders' departed control history), #6024
  (the client can't arrange a graveyard batch), #6047 (a counted redirect skips
  a shield's division), #6055 (a host-watching block trigger reads at the
  scan), #6060 (a cost payable only with triggered mana), #6062 (a granted
  "can't be blocked by" under Humility), #6064 (other named activators), #6070
  (Panic's siblings), #6072 (the next turn's upkeep; closed by #6074), #6079
  (a target-bound attack waiver), #6080 (the {T} half of "as though it had
  haste"), #6094 (Dream Halls).
- Audits: 18 of 22 capability PRs, and hand batch #6008; 5 found rules defects.
  - #6016: copy-acquired pairs read another pair's rows.
  - #6038: three: Syphon Soul and Chandra counted Eye's damage as dealt this
    way, CR 615.7's division over the added damage, Eye's chooser.
  - #6049: alike shields never asked (CR 616.1), so Healing Salve beside Sacred
    Boon took the Shock.
  - #6057: a phased-out permanent was still exchanged.
  - #6059: two on the new `LeftTheGame` road: a stolen staying Aura's controller,
    and two players leaving at once.
- Cost (`script/session-tokens.sh` over the set's transcripts, the last two
  units' session included whole): cache reads 0.27B, cache writes 10M, output
  3.1M; 1.5M cache reads per card. Per unit about 11M to 13M at the top; not
  mapped to PRs. Wall clock ~30h. Unit 10 left no log entry; a session failing
  after #6078's merge left another written up afterwards.
- Owner review:
  - #6058: decisions.md "Whether assigning no combat damage beats assigning
    toughness", an open call against Narod's 2024-11-08 playtest ruling.
  - #6057: decisions.md "Whether Confusion in the Ranks counts Kindred as a
    shared type".
  - #6038: decisions.md "Whether damage a replacement adds joins a division
    already owed"; a contested shield can be asked twice.
  - #6100: decisions.md "Whose next step a control change leaves".
  - #6000: an intervening reading for Erg Raiders, pending its filed issue.
  - #6049, #6053: new `ChooseReplacement` prompts with no consequence on alike
    shields and two Island Sanctuaries, asked rather than elided.
  - #6072: the skipped-upkeep case, an unsettled CR 614.10a reading.
  - Breaking wire: #6008 (`whosePhase`), #6015 (`MilledThisTurn`), #6016
    (`enteredWith` in a saved state), #6038, #6048 (`ChooseNumber.upTo`), #6054
    (block trigger payloads), #6059 (a bare destination), #6065 (the activator's
    default tag), #6071 (`BeforeCombatDamage`), #6100 (`UntilYourNextStep`).
