# Orchestrating a set

How to run one set of #5468's ladder: every card of the set in the pool, and
its census doc (`docs/sets/<set>.md`) listing nothing under "Needs a
capability". Read with `docs/agents/set-by-set.md`, which the implementers and
auditors you dispatch follow; `CLAUDE.md` and `CONTRIBUTING.md` apply
throughout and override both except where they say otherwise. Every subagent
is opus. Rules only: the incidents behind them are in git history.

## Machine setup

`_scratch/` is gitignored. Fetch each input from its source when a step needs
it, never copying one between machines; a missing file is a fetch, not a
blocker.

- MTGJSON: `curl -sfL -o _scratch/X.json.gz
  https://mtgjson.com/api/v5/X.json.gz && gunzip _scratch/X.json.gz` for `X`
  in `AllPrintings` (set lists) and `AtomicCards`, then `jq -f
  script/ingest/candidates.jq _scratch/AtomicCards.json >
  _scratch/candidates.json`, the CANDIDATES file.
- mtgish: `git clone https://github.com/i5jb/mtgish _scratch/mtgish`; it
  commits `data/mtgish.lines.json` pre-built, and `git pull` refreshes it.
- Prior art, optional: clone `https://github.com/phase-rs/phase` and
  `https://github.com/wingedsheep/argentum-engine` into `_scratch/`.
- The warm worktree: only the orchestrator runs `script/warm-worktree.sh` (no
  argument), once before the first dispatch and in the background after every
  merge; implementers seed from it. Never reap, rename or dispatch into it.
- A binary run outside `cabal run` (`cabal list-bin parun`) needs
  `parun_datadir` pointing at the checkout's `data/`.

## The procedure

Per set, in this order, one unit at a time ("Mechanics").

1. **Census unit.** Diff AllPrintings' `.data[SET].cards[].name` (split ` // `
   names into faces) against every face `name` in `data/cards/` (`jq -r
   '.faces[].name' data/cards/*.json`), never against names a card's text
   mentions. Put each missing card in exactly one place:
   - added in this PR: what `parun translate` accepts;
   - "Expressible today": with the mtgish node translate stops at, or
     "renders differently";
   - "Needs a capability": grouped under its issue, hardest first, a
     one-line note each on why.

   Shape `docs/sets/<set>.md` like the previous set's census as its census PR
   first wrote it (`git log --diff-filter=A --format=%h --
   docs/sets/<prev>.md`, then `git show`), not the finished file. File one
   issue per missing capability (`gap`, an `area:*`, `expires:card-driven`,
   no priority), or comment on an existing one naming the card. Classify
   cheaply: start from `parun translate --set SET --out DIR`'s rejections,
   judge whether the DSL expresses the blocking node (a pool card using it is
   the evidence), and Scryfall-verify only the "Needs a capability" cards.
   Report the two trend numbers: the first dry run's translations, and the
   cards needing a capability.
2. **Hand batches** over "Expressible today", in order, about 20 cards each.
   Translate first, hand-write on rejection. Every census verdict and every
   sibling it names is a claim to verify. A wrong verdict moves the card
   under "Needs a capability" (issue or comment), or is folded if small. Each
   batch updates the census.
3. **Capability units**, one per issue, hardest first. Parameter-sized issues
   share a capability batch only when they share an edit site: name the
   function or constructor they all edit, and read it; if you cannot, they
   are a topic, not a batch. Capability units do NOT edit
   `docs/sets/<set>.md`; the orchestrator or the set's last unit does.
4. **Audit** a PR that changes what many games pass through: a `GameState`
   field, a reader every resolution, search, combat or cast passes through, a
   codec shape, or a new `docs/decisions.md` entry. Audit any other PR at the
   orchestrator's judgement: more of a kind that keeps finding defects, none
   of a kind clean twice running. Record each skip and its reason as the unit
   reports. Hand the findings, as claims to verify, to a FRESH fixer with the
   PR's diff and body; it pushes back with evidence where the audit is wrong.
   The PR stays a draft until the fixes land.
5. **Finish.** When every capability card is in the pool, set "Needs a
   capability" to "Nothing", commit the set list as
   `data/decks/sets/<set>.txt` (`1 Name` a line, one per card name;
   `DecksSpec` proves each resolves), and tick the set on #5468. The set's
   last unit does this; until then, check the list with `parun deck` from a
   scratch file. The orchestrator then writes `## How it went` as the
   census's last section from what it recorded as each unit reported: a
   frozen record (the no-tallies rule for trackers does not apply), and a
   figure nobody recorded is "not recorded", never an estimate:

   ```markdown
   ## How it went

   Finished YYYY-MM-DD.

   | Route | Cards | PRs |
   | --- | --- | --- |
   | Translated (census) | N | #census |
   | Hand-written | N | #hand1, #hand2 |
   | Behind a capability | N, plus M from other sets | below |

   - Census trend: the first dry run translated T of the N missing; C
     needed a capability.
   - Capability issues, hardest first: #issue Card (#PR), ...
   - Filed along the way: #N (one phrase), ...
   - Audits: A of K capability PRs; D found rules defects.
     - #PR: the defect, in a line.
   - Cost (`script/session-tokens.sh` over the set's transcripts): cache
     reads X.XB, cache writes XM, output XM; X.XM cache reads per card. The
     costliest units: #PR (XM), .... Wall clock ~Nh.
   - Owner review:
     - #PR: a decisions.md entry, wire-format change or contested reading.
   ```

Preconstructed and theme decks are optional, never a unit's goal. Add no cards
from other sets unless a scenario needs one. Widen the translator only when
the census's top blocking construct unlocks enough remaining-ladder cards to
beat hand-writing them. A filed issue opens with a dated plain-language
summary, and its title carries no CR numbers.

## Mechanics

- **One unit at a time.** Dispatch the next unit only after the current one's
  PR merges, cut from that `origin/main`; a read-only audit runs while its
  unit waits. Tokens, not wall clock, are the budget.
  `script/with-build-lock.sh` (`PARUN_BUILD_SLOTS`) stays as the guard.
- **Cost** is cache reads (`script/session-tokens.sh` on the transcripts):
  every turn re-reads the whole context, so cost grows with the square of a
  session's length.
- **Short sessions.** Size a unit to finish in about 150 turns: hand batches
  of about 20 cards, capability batches of two or three issues. A unit
  with work left hands it to a fresh unit briefed with its branch and report
  ("Implementing a unit"). Never resume a finished agent for more work; brief
  a fresh one.
- **Subagents commit; the orchestrator pushes.** Before pushing, grep the
  branch's commit messages and the PR body for close/fix/resolve beside an
  issue number. Open the PR as a draft from the agent's PR-body file, then
  shepherd it.
- **Scratch.** Each agent gets its own named subfolder of the session
  scratchpad. Briefs and PR bodies are files there, relayed by path, never
  retyped.
- **Merging.** When a PR has cleared any audit, `gh pr ready` it and arm
  auto-merge (squash) in the same step; a later send-back undoes ready first
  (`gh pr ready --undo`). Re-check `autoMergeRequest` after arming and after
  every push. On a conflict, send the agent back to merge `origin/main`
  (`docs/agents/set-by-set.md`, "Git and the PR").
- **Shepherd** each PR with `script/shepherd.sh PR` in the background: it
  updates a `BEHIND` branch and exits on merge, conflict or a failed check.
  Read a failed job's log first: one that died in `Set up job` is not a real
  failure.
- **Reap after every merge**, from the primary checkout: `git worktree remove
  --force` the unit's worktree (unlock first), `git worktree prune`, `git
  fetch --prune`, then delete every local branch whose upstream is `[gone]` or
  that has no commit beyond `origin/main`, skipping any a live worktree has
  checked out. Kill a stalled `cabal` by PID after `lsof -p <pid> -d cwd`
  shows a finished worktree. Leave branches you did not create that carry
  commits. Hold a worktree while an audit or send-back may still reach it.
  Then refresh the warm worktree.
## Writing a brief

Instantiate the templates below, never a previous filled-in brief; add only
what is specific to the unit. Don't research ahead of the implementer: a brief
carries facts reading settles (producers, Oracle text fetched this session,
what the census says, which merged units it must reuse) and flags anything
else unverified --- never a predicted wire spelling, test board, mutation
outcome or file list. Never tell an implementer not to chase something.

## Templates

Placeholders: `SET` (code, e.g. `M14`), `SETNAME`, `ISSUE`, `BRANCH`,
`SCRATCH` (the agent's folder under the session scratchpad), `BASESHA`,
`HEADSHA`. Every implementer brief opens with **Preamble** and closes with
**Finishing**.

**Preamble.**

> You are an implementing agent on parun. Read `CLAUDE.md` and
> `docs/agents/set-by-set.md` ("Implementing a unit" and "What every brief
> repeats") first and follow them. You are in your own git worktree. First
> `git fetch` and `git checkout -B BRANCH origin/main` (or the branch named
> below, if its PR has not merged). Keep every scratch file, mutation scripts
> included, in `SCRATCH`. Another agent builds at the same time, so prefer
> pattern runs to full-suite runs except the last.

**Finishing.**

> Work through `CLAUDE.md`'s "Before you consider a change done" in full,
> self-review, and run the full suite after your last code change. Commit on
> `BRANCH`; DO NOT push and DO NOT open the PR. End every commit with the
> session's `Co-Authored-By` trailer. Report: branch, worktree path, head
> SHA; suite count before -> after; issues filed or commented on; and the PR
> body, per `CLAUDE.md`'s bullets, saved to `SCRATCH/pr.md` and ending with
> the session's generated-with line.

**Census.**

> Start SETNAME (SET) under #5468: unit 1, the census, whose purpose is to
> find the hard cards early. Follow "The procedure", step 1. Deliverables, one
> PR: `docs/sets/<set>.md`; the capability issues or comments, dated today;
> the cards `parun translate` accepts, each `new` ability (and each shared one
> no test exercises) with a gameplay-level scenario, ten spot-checked on
> Scryfall; keyword-only cards ingested. Before filing, check the DSL for a
> sibling a parameter would extend ("Parameters, not siblings"). Read `git
> log --oneline` since the previous set's census and use today's names for
> every wire shape. Confirm every sibling you name is in the pool and
> expresses the wording. The PR says "related to #5468". Also report the
> count per census section and the two trend numbers.

**Hand batch.**

> Hand-write entries FIRST through LAST (N cards) of SETNAME's "Expressible
> today" list in `docs/sets/<set>.md`. Follow "The procedure", step 2:
> translate first; verify each card's Oracle text, cost, type line and P/T on
> Scryfall; stamp `oracleText` via `parun ingest`; one scenario per new
> ability wording, the PR body naming each card left without its own and the
> scenario covering it. Update the census: move the added cards out, and drop
> any "Needs a capability" entry whose card is now on main (re-check after
> your merge). The PR says "related to #5468". Also report the cards and
> scenarios added and what remains, by census section.

Each later batch adds "the previous batch is PR #P, merged", says whether it
finishes the list, and carries the earlier batches' findings forward --- the
census verdicts they overturned, and any renderer wordings or
`docs/decisions.md` entries they added --- so it extends those sites rather
than duplicating them.

**Audit fix.**

> Fix the findings of PR #P's audit. You are on branch BRANCH (PR #P) in
> your own worktree; read the PR body (`gh api
> repos/tfausak/parun/pulls/P --jq .body`) and its diff (`git diff
> BASESHA HEAD`) before anything else, and read only the code the findings
> name. Each finding below is a claim to verify: fix what holds, push back
> with evidence where it doesn't. FINDINGS. Update the PR body file
> `SCRATCH/pr.md` (copy it from the PR first) and report the head SHA.

**Capability unit.**

> Implement #ISSUE and add the SETNAME card or cards it names; it came out of
> the census (`docs/sets/<set>.md`), and the PR closes it. Re-derive the
> issue's card facts, wire shapes and claim about what the DSL lacks against
> the tree, `docs/rules.txt` and Scryfall. Prefer a parameter on an existing
> type. Every capability needs a gameplay-level scenario on the real card. Do
> NOT edit `docs/sets/<set>.md`. Fold small follow-ups in; file only what is
> too big, naming its card.

**Capability batch** is the capability unit over several issues: it names
each (#A, #B, ...) with its card and the one-line census claim to verify
("needs only a parameter on X"), the edit site they share, and any merged
unit whose shape it must reuse; the PR closes them all. As the set's last
unit it also finishes the census ("The procedure", step 5) and reports which
entries were still open.

**Audit.**

> You are a read-only auditor on parun. Read `CLAUDE.md` and
> `docs/agents/set-by-set.md` ("Auditing a unit") first and follow them. Do
> not edit, commit, push, build or run tests; never cd to the primary
> checkout. Audit branch `BRANCH` at head HEADSHA (pin it; never
> `FETCH_HEAD`). Read only its own diff: `git fetch origin BRANCH` then `git
> diff BASESHA HEADSHA`, BASESHA being `origin/main`'s merge base. It
> implements #ISSUE, adds CARDS, and is PR #P, whose body states the design.
> Find rules-correctness defects: a legal board on which the change plays
> differently from `docs/rules.txt` or the cards' rulings (Scryfall
> `named?fuzzy=`, then each `rulings_uri`). The riskiest part is SHAREDGATE,
> which every RESOLUTION/SEARCH/COMBAT passes through. Check: BOARDS (that
> unaffected games are unchanged; two such effects at once; control or zone
> changes mid-effect; multiplayer). Enumerate with jq the pool cards that
> reach the changed reader and say whether any now reads differently. Also
> check `CLAUDE.md` item 4's sites for the new constructors and fields, and
> whether the tests prove what they claim. Keep scratch in `SCRATCH`. Report
> findings only, most severe first.
