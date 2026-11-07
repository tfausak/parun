# Orchestrating a set

How to run one set of #6476's ladder: every card of the set in the pool, and
its set list committed. Read with `docs/agents/set-by-set.md`, which the
sessions working the set's issues follow; `CLAUDE.md` and `CONTRIBUTING.md`
apply throughout and override both except where they say otherwise. Rules
only: the incidents behind them are in git history.

## The shape

A set is one **tracking issue**, a sub-issue of #6476, whose sub-issues are
the set's units. Each unit is one issue a fresh cloud session can finish from
its body alone, and one PR closing it. GitHub is the only progress record:
open and closed sub-issues, their blocked-by links and the tracker's census
snapshot. No unit edits a file another unit of the set also edits for
bookkeeping: the set's doc, `docs/sets/<set>.md`, is written once, by the
finish unit.

The orchestrator dispatches a unit by applying the `claude` label to its
issue; the session that starts opens the PR. The orchestrator owns the
tracker, which only the census unit also writes (its snapshot), and the body
of every unlabelled issue. A labelled issue's body belongs to its unit:
nobody edits it after labelling.

The units, as sub-issues of the tracker:

- **Census**: one, first.
- **Batch**: about 20 expressible cards, a contiguous run in name order.
- **Capability**: one missing capability and the cards waiting on it.
- **Fix**: an audit finding on a merged unit.
- **Finish**: one, last, filed when everything else is closed.

## Session setup

A cloud session starts without `_scratch/` (gitignored). Fetch each input
when a step needs it; a missing file is a fetch, not a blocker.

- MTGJSON: `curl -sfL -o _scratch/X.json.gz
  https://mtgjson.com/api/v5/X.json.gz && gunzip _scratch/X.json.gz` for `X`
  in `AllPrintings` (set lists) and `AtomicCards`, then `jq -f
  script/ingest/candidates.jq _scratch/AtomicCards.json >
  _scratch/candidates.json`, the CANDIDATES file.
- mtgish: `git clone https://github.com/i5jb/mtgish _scratch/mtgish`; it
  commits `data/mtgish.lines.json` pre-built, and `git pull` refreshes it.
- Prior art, optional: clone `https://github.com/phase-rs/phase` and
  `https://github.com/wingedsheep/argentum-engine` into `_scratch/`.
- A binary run outside `cabal run` (`cabal list-bin parun`) needs
  `parun_datadir` pointing at the checkout's `data/`.

## The procedure

1. **Tracker.** Open `SETNAME (SET)` with a dated plain-language summary,
   make it a sub-issue of #6476, file the census issue under it ("Templates")
   and label the census issue.
2. **Census unit.** Diff AllPrintings' `.data[SET].cards[].name` (split ` // `
   names into faces) against every face `name` in `data/cards/` (`jq -r
   '.faces[].name' data/cards/*.json`), never against names a card's text
   mentions. Put each missing card in exactly one place:
   - added in the census PR: what `parun translate` accepts;
   - a batch issue: what the DSL expresses but translate rejects, in name
     order, about 20 a batch, each card with the mtgish node translate stops
     at, or "renders differently";
   - a capability issue: what needs a capability (`gap`, an `area:*`,
     `expires:card-driven`, no priority), hardest first. An open issue
     already covering it gets a comment naming the card instead; if it has a
     parent elsewhere (an issue has one), link it as blocking the tracker.

   Every issue it files is a sub-issue of the tracker, written per "Writing
   an issue". Classify cheaply: start from `parun translate --set SET --out
   DIR`'s rejections, judge whether the DSL expresses the blocking node (a
   pool card using it is the evidence), and Scryfall-verify only the
   capability cards. Then append the census snapshot to the tracker's body:
   the date, the count per place, and the two trend numbers (the first dry
   run's translations, and the cards needing a capability).
3. **Fan out** ("Mechanics"). Capability issues hardest first, then batches.
4. **Audit** a merged PR that changes what many games pass through: a
   `GameState` field, a reader every resolution, search, combat or cast
   passes through, a codec shape, or a new `docs/decisions.md` entry. Audit
   any other at the orchestrator's judgement: more of a kind that keeps
   finding defects, none of a kind clean twice running. The auditor is a
   read-only subagent of the orchestrator ("Templates"); each finding that
   holds on the orchestrator's own reading becomes a fix issue (`bug`,
   `rules-correctness`) under the tracker. Record each skip and its reason on
   the tracker.
5. **Finish.** When every other sub-issue and every issue blocking the
   tracker is closed, file the finish issue and label it. Its PR commits the
   set list as `data/decks/sets/<set>/all.txt` (`1 Name` a line, one per
   card name; `DecksSpec` proves each resolves), writes `docs/sets/<set>.md`,
   and ticks the set on #6476. The doc is the tracker's census snapshot, then
   `## How it went`: a frozen record (the no-tallies rule for trackers does
   not apply) built from the tracker and its sub-issues' merged PRs, where a
   figure nobody recorded is "not recorded", never an estimate:

   ```markdown
   ## How it went

   Finished YYYY-MM-DD.

   | Route | Cards | PRs |
   | --- | --- | --- |
   | Translated (census) | N | #census |
   | Batches | N | #batch1, #batch2 |
   | Behind a capability | N, plus M from other sets | below |

   - Census trend: the first dry run translated T of the N missing; C
     needed a capability.
   - Capability issues, hardest first: #issue Card (#PR), ...
   - Filed along the way: #N (one phrase), ...
   - Audits: A of K capability PRs; D found rules defects.
     - #PR: the defect, in a line, and its fix issue.
   - Cost: as recorded on the tracker, else "not recorded". Wall clock ~Nh.
   - Owner review:
     - #PR: a decisions.md entry, wire-format change or contested reading.
   ```

Preconstructed and theme decks are optional, never a unit's goal. Add no cards
from other sets unless a scenario needs one. Widen the translator only when
the census's top blocking construct unlocks enough remaining-ladder cards to
beat hand-writing them. A filed issue opens with a dated plain-language
summary, and its title carries no CR numbers.

## Mechanics

- **Eight at a time.** Toposort the tracker's open sub-issues, and the open
  issues blocking it, by their blocked-by links, and label up to eight whose
  blockers are all closed. As each PR merges, label the next. Never label an
  issue with an open blocker.
- **Shared edit sites serialize.** Two issues that edit the same function or
  constructor are never in flight together: link the later as blocked by
  the earlier, so the toposort orders them. A batch takes a contiguous run in
  name order, so batches meet only at their ends in a sorted list.
- **Hot files stay sorted.** A list every card PR edits is kept in byte order,
  never appended to: `data/oracle-unrendered.txt` (`script/sort-lines.sh`,
  the `sorted` hook). A new list of that kind gets the same treatment.
- **Carry findings forward** by editing unlabelled issues: a census verdict a
  merged unit overturned, a renderer wording or `docs/decisions.md` entry it
  added that a later unit must extend rather than duplicate. An issue a unit
  files for the set goes under the tracker; adopt it if it did not.
- **Short units.** Size an issue to finish in about 150 turns: about 20 cards
  a batch, one capability an issue, or two or three parameter-sized ones
  that share an edit site (name it, and read it; if you cannot, they are a
  topic, not one issue). A unit with work left files the rest as a new
  sub-issue ("Implementing a unit").
- **Cost** is cache reads (`script/session-tokens.sh` on the transcripts,
  where they are reachable): every turn re-reads the whole context, so cost
  grows with the square of a session's length. Record it on the tracker as
  each unit merges.
- **Merging.** The unit's session marks its PR ready and arms auto-merge
  itself; the orchestrator only watches. A PR stalled out of the queue is
  read from `gh api repos/parun-mtg/parun/issues/P/events`: a queued PR shows
  no `autoMergeRequest`, so the last `auto_merge_*` or `*_merge_queue` event
  says whether it is still queued. On a conflict or a CI failure that needs
  `main`, a fresh agent merges `origin/main` into the branch
  (`docs/agents/set-by-set.md`, "Git and the PR"). Don't update a `BEHIND`
  branch: the queue tests each PR against main. Read a failed job's log
  first: one that died in `Set up job` is not a real failure.
- **Waiting** is a scheduled check-in or a PR subscription, never a polling
  loop.

## Writing an issue

The labelled session sees the issue, `CLAUDE.md` and the tree, and nothing the
orchestrator knows: everything it needs is in the body or one link away. It
names the set and the tracker (`#T`), says the PR closes this issue, and lists
the deliverables. It carries facts reading settles (producers, Oracle text
fetched that day, what the census found, which merged PRs it must reuse) and
flags anything else unverified --- never a predicted wire spelling, test
board, mutation outcome or file list. Never tell an implementer not to chase
something.

## Templates

Placeholders: `SET` (code, e.g. `HOB`), `SETNAME`, `T` (the tracker), `DATE`.
Every unit issue but the finish ends with **Footer**.

**Footer.**

> Follow `CLAUDE.md` and `docs/agents/set-by-set.md` ("What every unit
> repeats" and "Implementing a unit"). Part of SETNAME (SET), tracked in #T;
> file anything new for the set as a sub-issue of #T. Do not edit
> `docs/sets/<set>.md`. The PR closes this issue.

**Census.**

> **Summary (DATE).** Census SETNAME (SET): find the hard cards early, and
> cut the rest into issues. Follow `docs/agents/orchestrating.md`, "The
> procedure", step 2. Deliverables: one PR adding the cards `parun
> translate` accepts, each `new` ability (and each shared one no test
> exercises) with a gameplay-level scenario, ten spot-checked on Scryfall,
> keyword-only cards ingested; the batch and capability issues, each a
> sub-issue of #T written per "Writing an issue"; the census snapshot on
> #T's body. Before filing a capability, check the DSL for a sibling a
> parameter would extend ("Parameters, not siblings"). Read `git log
> --oneline` since the previous set's census and use today's names for
> every wire shape. Confirm every sibling you name is in the pool and
> expresses the wording.

**Batch.**

> **Summary (DATE).** Add N SETNAME cards, FIRST through LAST. The census
> found the DSL expresses each; translate stopped at the node named
> ("verify" marks a clause it did not settle):
>
> - CARD: `NODE`
>
> Translate first, hand-write on rejection. Verify each card's Oracle text,
> cost, type line and P/T on Scryfall; stamp `oracleText` via `parun ingest`;
> one scenario per new ability wording, the PR body naming each card left
> without its own and the scenario covering it. Each verdict above is a
> claim: a card that needs a capability goes to a capability issue (file
> one, or comment on the open one) and the PR says so. Reuse: MERGED.

**Capability** is a `gap` issue in the project's usual form, plus: the
SETNAME cards needing it (Oracle text fetched DATE), the census's one-line
claim to verify ("needs only a parameter on X"), the merged units whose shape
it must reuse, "prefer a parameter on an existing type", and "every
capability needs a gameplay-level scenario on the real card".

**Fix.**

> **Summary (DATE).** An audit of #P (merged) found: FINDING, as board,
> action sequence, engine behaviour, CR or ruling, file and identifier.
> Verify it before fixing; if it does not hold, close this issue as not
> planned with the evidence.

**Finish.**

> **Summary (DATE).** Finish SETNAME: every other sub-issue of #T, and
> every issue blocking it, is closed.
> Follow `docs/agents/orchestrating.md`, "The procedure", step 5. Check the
> set list with `parun deck` from a scratch file first; a card still missing
> is a new sub-issue of #T, not this unit's work. The PR also closes #T.

**Audit** (a subagent prompt, not an issue).

> You are a read-only auditor on parun. Read `CLAUDE.md` and
> `docs/agents/set-by-set.md` ("Auditing a unit") first and follow them. Do
> not edit, commit, push, build or run tests. Audit PR #P, merged as SHA:
> `git fetch origin main`, then `git show SHA`. It implements #ISSUE, adds
> CARDS, and its body states the design (`gh api
> repos/parun-mtg/parun/pulls/P --jq .body`). Find rules-correctness
> defects: a legal board on which the change plays differently from
> `docs/rules.txt` or the cards' rulings (Scryfall `named?fuzzy=`, then each
> `rulings_uri`). The riskiest part is SHAREDGATE, which every
> RESOLUTION/SEARCH/COMBAT passes through. Check: BOARDS (that unaffected
> games are unchanged; two such effects at once; control or zone changes
> mid-effect; multiplayer). Enumerate with jq the pool cards that reach the
> changed reader and say whether any now reads differently. Also check
> `CLAUDE.md` item 4's sites for the new constructors and fields, and
> whether the tests prove what they claim. Report findings only, most severe
> first.
