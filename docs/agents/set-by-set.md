# Adding cards set by set

How to run one set of #5468's ladder: every card of the set in the pool, and
its census doc (`docs/sets/<set>.md`) listing nothing under "Needs a
capability". `CLAUDE.md` and `CONTRIBUTING.md` apply throughout and override
this file, except where it says otherwise. Rules only: the incidents behind
them are in git history.

Three roles. The **orchestrator** is the session told to run the set; it reads
all of this file, writes the briefs and owns GitHub. An **implementer** holds a
build in its own worktree and commits; it reads "Implementing a unit". An
**auditor** is read-only; it reads "Auditing a unit". Every subagent is opus.

## Machine setup

`_scratch/` is gitignored. Fetch each input from its source when a step needs
it; never copy one between machines. A missing file is a fetch, not a blocker.

- MTGJSON, into `_scratch/`: `curl -sfL -o _scratch/X.json.gz
  https://mtgjson.com/api/v5/X.json.gz && gunzip _scratch/X.json.gz`, for `X`
  in `AllPrintings` (the set lists) and `AtomicCards` (Oracle text,
  printings). Then `jq -f script/ingest/candidates.jq
  _scratch/AtomicCards.json > _scratch/candidates.json`, the CANDIDATES file
  `parun ingest` and `parun translate` read. A dump newer than the pool's
  stamps restamps cards outside the set; see "What every brief repeats".
- mtgish: `git clone https://github.com/i5jb/mtgish _scratch/mtgish`. The repo
  commits its output pre-built, so `_scratch/mtgish/data/mtgish.lines.json`
  exists after the clone, and `git pull` there refreshes it. Nothing in parun
  generates it.
- Prior art, optional (see "Prior art"): `git clone` of
  `https://github.com/phase-rs/phase` and
  `https://github.com/wingedsheep/argentum-engine` into `_scratch/`.
- The warm worktree: `script/warm-worktree.sh` (no argument) creates or
  refreshes `.claude/worktrees/warm` at `origin/main` with a finished build.
  Only the orchestrator runs it: once before the first dispatch, then in the
  background after every merge. Implementers seed from it (`CLAUDE.md`). It is
  never reaped, renamed or dispatched into.
- A built binary run outside `cabal run` (`cabal list-bin parun`) needs
  `parun_datadir` pointing at the checkout's `data/`.

## The procedure

Per set, in this order, one unit at a time ("Mechanics").

1. **Census unit.** Derive the missing list from AllPrintings'
   `.data[SET].cards[].name` (split a ` // ` name into its faces) diffed
   against every face `name` in `data/cards/` (`jq -r '.faces[].name'
   data/cards/*.json`), never against names a card's text mentions. Classify
   each missing card into exactly one place:
   - added in this PR: what `parun translate` accepts;
   - "Expressible today": with the mtgish node translate stops at, or
     "renders differently";
   - "Needs a capability": grouped under its issue, hardest first, a
     one-line note each on why.

   Write `docs/sets/<set>.md` shaped like the previous set's census as its
   census PR first wrote it (`git log --diff-filter=A --format=%h --
   docs/sets/<prev>.md`, then `git show`), not the finished file. File one
   capability issue per missing capability (`gap`, an `area:*`,
   `expires:card-driven`, no priority; the issue-body conventions are
   below), or comment on an existing issue naming the card. Classify
   cheaply: start from `parun translate --set SET --out DIR`'s rejections,
   judge whether the DSL expresses the blocking node (a pool card using it is
   the evidence), and Scryfall-verify only the "Needs a capability" cards.
   Report two trend numbers: the first dry run's translations, and the cards
   needing a capability. About a third to a half usually translate.
2. **Two hand batches** over "Expressible today": the first half, then the
   second. Translate first, hand-write on rejection. Every census verdict and
   every sibling it names is a claim to verify --- every set so far had wrong
   ones. A wrong verdict moves the card under "Needs a capability" (issue or
   comment), or is folded if small. Each batch updates the census.
3. **Capability units**, one per issue, hardest first.
   Several parameter-sized issues go in one capability batch, but only when
   they share an edit site: name the function or constructor they all edit,
   read it, and if you cannot, they are a topic, not a batch. Capability units
   do NOT edit `docs/sets/<set>.md`; the orchestrator or the set's last unit
   does.
4. **Audit** only capability PRs that change a shared rules gate or a wire
   format: a `GameState` field, a reader every resolution, search or combat
   passes through, a codec shape. Relay findings to the SAME implementer as
   claims to verify; it pushes back with evidence where the audit is wrong.
   The PR stays a draft until the fixes land.
5. **Finish.** When every capability card is in the pool, set "Needs a
   capability" to "Nothing", commit the set list as
   `data/decks/sets/<set>.txt` (`1 Name` a line, one per card name in the
   set; `DecksSpec` then proves every name resolves), and tick the set on
   #5468. The set's last unit does this; until then, check the list with
   `parun deck` from a scratch file. Then the orchestrator writes `## How
   it went` as the census's last section, from the costs and outcomes it
   recorded as each unit reported. It is a frozen record, written once and
   never updated, so the no-tallies rule for trackers does not apply. A
   figure nobody recorded is "not recorded", never an estimate. The shape:

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
   - Subagent tokens: census Xk; hand Xk, Xk; capability Xk (#PR), ...;
     audits Xk (#PR), .... Total X.XXM, Xk per card. Wall clock ~Nh.
   - Owner review:
     - #PR: a decisions.md entry, wire-format change or contested reading.
   ```

Preconstructed and theme decks are optional: add them when convenient for
testing the client, never as a unit's goal. Add no cards from other sets
unless a scenario needs one.

Widen the translator itself only when the census dry run's top blocking
construct unlocks enough remaining-ladder cards to beat hand-writing them;
otherwise the tail is hand-written.

A filed issue opens with a dated plain-language summary, and its title carries
no CR numbers.

## Mechanics

- **One unit at a time.** Dispatch the next unit only after the current unit's
  PR has merged, and cut it from that `origin/main`; a read-only audit runs
  while its unit waits. Tokens, not wall clock, are the budget, and parallel
  units each move main under the others and cost a merge apiece.
  `script/with-build-lock.sh` stays as the guard (`PARUN_BUILD_SLOTS`).
- **Cost, for planning** (subagent tokens): census ~300--350k; hand batch
  ~13--17k per card; capability unit ~150--350k; audit ~100--200k.
- **Subagents commit; the orchestrator pushes.** Before pushing, grep the
  branch's commit messages and the PR body for close/fix/resolve beside an
  issue number. Open the PR as a draft from the agent's PR-body file, then
  shepherd it (below).
- **Merge `origin/main` once**, just before self-review, never mid-work.
  Afterwards grep the new cards for any JSON key a merged PR renamed: a key
  the decoder ignores loads silently wrong.
- **Scratch.** Each agent gets its own named subfolder of the session
  scratchpad; agents sharing one have overwritten each other's mutation
  files. Briefs and PR bodies are files there, relayed by path, never retyped.
- **Builds.** Agents run `cabal` in the foreground with a generous timeout,
  split long runs by pattern, and kill a wedged run (0% CPU for ten minutes)
  by its own PID, never by pattern.
- **Merging.** When a PR has cleared any audit, `gh pr ready` it and arm
  auto-merge (squash) in the same step; a later send-back undoes ready first
  (`gh pr ready --undo`). Re-check `autoMergeRequest` after arming and after
  every push: a push can drop it. On a conflict, send the agent back to merge
  `origin/main`, take both sides, and re-run its mutations. Agents never
  force-push.
- **Shepherd** each PR with `script/shepherd.sh PR` in the background: it
  updates a `BEHIND` branch and exits on merge, conflict or a failed check.
  Before acting on a failed check, read the job log: a job that died in `Set
  up job` is not a real failure.
- **Reap after every merge**, from the primary checkout: `git worktree remove
  --force` the unit's worktree (unlock first), `git worktree prune`, `git
  fetch --prune`, then delete every local branch whose upstream is `[gone]` or
  that has no commit beyond `origin/main`, skipping any a live worktree has
  checked out. Kill a stalled `cabal` by PID after `lsof -p <pid> -d cwd`
  shows a finished worktree. Leave branches you did not create that carry
  commits. Reaping makes an agent unresumable, so hold a worktree while an
  audit or a send-back may still reach it. Then refresh the warm worktree.
- **Follow-ups an agent files in its own files** go back to the same agent on
  a new branch once its PR merges, rather than to a fresh dispatch.
- **Blocked is a good outcome.** A unit that cannot land adds
  `needs-planning`, links its blocker as a dependency (`CLAUDE.md`), or, where
  the blocker is an owner decision, names the question. A decomposition beats
  a half-landed unit.

## Writing a brief

The templates below are the briefs; fill the placeholders and add only what is
specific to the unit. Always instantiate the template, never a previous
filled-in brief: one inherited a stale branch name.

Don't research ahead of the implementer: it re-derives everything, and every
brief-time prediction of a wire spelling, a test board, a mutation's colour or
a files-touched list has been wrong. A brief carries facts reading settles
(producers, Oracle text fetched this session, what the census says, which
merged units it must reuse) and flags anything else unverified.
Never tell an implementer not to chase something.

### What every brief repeats

- Card-pool negatives ("no card does X") need the enumeration behind them.
- The `docs/decisions.md` bar: two readings that play differently on some
  legal board, neither forced by the CR or a ruling. A "rejected" argument
  that cites a rule or ruling is forced: cite it at the code site instead.
  Implementation choices go in the PR body.
- A card that doesn't render back to its Oracle text goes in
  `data/oracle-unrendered.txt` (`Parun.IngestSpec` checks it both ways).
- `parun ingest` may restamp out-of-set cards from a newer dump; say whether
  to keep or revert them, and have the agent list them.
- `parun translate` without `--out DIR` writes into `data/cards/`; every dry
  run passes `--out`.
- A merged PR may rename JSON keys; grep new cards after merging main.

### Templates

Placeholders: `SET` (code, e.g. `M14`), `SETNAME`, `ISSUE`, `BRANCH`,
`SCRATCH` (the agent's folder under the session scratchpad), `BASESHA`,
`HEADSHA`. Every implementer brief opens with **Preamble** and
closes with **Finishing**.

**Preamble.**

> You are an implementing agent on parun. Read `CLAUDE.md` and
> `docs/agents/set-by-set.md` ("Implementing a unit" and "What every brief
> repeats") first and follow them. You are in your own git worktree; never
> cd to the primary checkout. First `git fetch` and `git checkout -B BRANCH
> origin/main` (or the branch named below, if its PR has not merged). Keep
> every scratch file, mutation scripts included, in your folder `SCRATCH`
> under the session scratchpad. Run every `cabal` call and test run through
> `script/with-build-lock.sh`; another agent builds at the same time, so
> prefer pattern runs to full-suite runs except the last.

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
> every wire shape, never ones copied from memory or an older brief. Confirm
> every sibling you name is in the pool and expresses the wording. The PR
> says "related to #5468". Also report the count per census section and the
> two trend numbers.

**Hand batch 1.**

> Hand-write the first half of SETNAME's "Expressible today" list in
> `docs/sets/<set>.md`: its first N entries, FIRST through LAST. Follow "The
> procedure", step 2: translate first; verify each card's Oracle text, cost,
> type line and P/T on Scryfall; stamp `oracleText` via `parun ingest`; one
> scenario per new ability wording, the PR body naming each card left without
> its own and the scenario covering it. Update the census: move the added
> cards out, and drop any "Needs a capability" entry whose card is now on main
> (re-check after your merge). The PR says "related to #5468". Also report the
> cards and scenarios added and what remains, by census section.

**Hand batch 2** differs only in: the last N entries, FIRST through LAST;
"batch 1 is PR #P, merged"; this batch finishes the
list; and it carries batch 1's findings forward --- the census verdicts it
overturned, and any renderer wordings or `docs/decisions.md` entries it
added, so batch 2 extends those sites by reading batch 1's diff rather than
duplicating them.

**Capability unit.**

> Implement #ISSUE and add the SETNAME card or cards it names; it came out of
> the census (`docs/sets/<set>.md`), and the PR closes it. Distrust the issue
> body: its card facts, wire shapes and claim about what the DSL lacks can all
> be wrong, so re-derive each against the tree, `docs/rules.txt` and Scryfall.
> Prefer a parameter on an existing type. Every capability needs a
> gameplay-level scenario on the real card. Do NOT edit `docs/sets/<set>.md`.
> Fold small follow-ups in; file only what is too big, naming its card.

**Capability batch** is the capability unit over several issues: it names
each (#A, #B, ...) with its card and the one-line census claim to verify
("needs only a parameter on X"), the edit site they share, and any merged
unit whose shape it must reuse rather than duplicate; the PR closes
them all. As the set's last unit it also finishes the census ("The
procedure", step 5) and reports which entries were still open.

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

## Implementing a unit

You hold a build; the brief carries only what is specific to your unit.

### Distrust the brief and the issue

What a brief could READ holds up: whether a blocker landed, which producer
works, edit sites, CR citations. What needs a compiler does not: wire
spellings, line numbers, mutation predictions. `curl` the Oracle text and diff
it against the brief, grep the sibling to confirm edit sites, and re-derive
the mutations. A mutation the brief predicted red that comes back green is a
finding: the board cannot discriminate, or the site has no observer. Diagnose
which; don't reword the prediction.

Check which issue, and which half of a split one ("the other half stays on
#N"), you are closing. Distrust the issue's size estimate in both directions. The cheapest first move
is to find the funnel --- the one function every path to the behaviour goes
through --- and read what it already gates or orders.

Before the first build, copy `cabal.project.local` in as a bare command of its
own and confirm it is there (the isolation guard refuses compound commands),
then seed from the warm worktree (`CLAUDE.md`). If the warm build is missing,
build cold and say so in the PR. Never build in the warm worktree.

### Running the suite

    script/with-build-lock.sh cabal run -v0 parun -- test -p PATTERN --hide-successes

`PATTERN` is a tasty pattern over the `Spec.describe` group names; the
executable hands it to tasty unsplit, where `--test-options` splits on spaces.
Iterate on your subtree, and run the whole suite before each commit: an engine
change reaches specs you did not open. Redirect output to a file and read the
file, and keep `--hide-successes`. Build with `cabal build -v0`. No `cabal
clean`; keep the optimizer on for the suite (mutations are the exception).

The timeout catches infinite loops, not slowness. ONE budget covers the suite:
read it off `flake.nix`'s `testFlags` and `.github/workflows/ci.yml`, which
must agree, and pass the same one locally. A lone TIMEOUT on a shared machine
is noise until it repeats unloaded.

### Enumerate the edit sites in one pass

When you add a constructor or field, grep a sibling to enumerate every site and
patch them all before rebuilding; don't let `-Werror` name them one build at a
time. Then find the sites `-Werror` will not name (`CLAUDE.md`, "Before you
consider a change done"), and say in the PR which you read and why each is
correct.

### Parameters, not siblings

The cheapest way to pass one card is a constructor shaped exactly like its
text; that is how the engine grew a comparison per card shape and a trigger per
player action, each later folded at real cost. Before adding a constructor,
field or function, grep for one the new thing is an instance of:

- the same reading against another number, comparison or object:
  `Filter.Measures`, `Parun.Types.Arithmetic`;
- the same event for another action or actor: `GameEvent.PlayerActed`,
  `GameEvent.PermanentActed`;
- the same rule over another subject: `CostModifier`, `Effect.Prohibit`;
- another row in a list something already walks: `Expiry.traverseExpiries`.

If one exists, extend it and name it in the PR body. If the CR makes the
difference observable so it cannot carry the new case, say that, with the
citation. A sibling added anyway is an audit finding.

### Prose the compiler cannot check

- **When your change widens a capability**, grep for prose asserting the old
  limit --- what you widened, the zone or type it now reaches, and `only`,
  `never`, `does not`, `no card` --- including `source/libraries/test/` and
  files you did not edit.
- **When you add a card**, grep the construct's type and constructor names
  for counting absolutes (`one`, `only`, `no card`, `the pool's`); the card
  that becomes the second producer falsifies them.
- **A new negative** takes one of two shapes. Prefer the citation: the claim
  is usually why a slot is unbuilt, an elision, so `Not implemented: ...
  (#N)` or `(gap #N)`. Otherwise record the query and its date, not the
  conclusion (Scryfall `o:"deals damage to" o:"that source"`, 2026-08-18, no
  hit). Either way, build the query from the printed template, never a
  constructor name; scope the noun (`data/cards/` or every printing); and
  name the card that WOULD refute you. `Parun.Types.SpendManaAsThough`'s
  `only` field is the model.

### Stale reads

The recurring defect is a consumer reading a snapshot where the rule asks
about live state: a gate reading the bindings captured when resolution began,
so a slot an earlier clause defined is invisible to a later one. When you add
a gate, prompt or condition, ask what it reads and when that was captured;
`Parun.Engine.Resolve.gateHolds` and its callers are where this bites. One
writer, every road: when you record an event, grep every function performing
the action; a second road around the funnel (`Daytime.turnDue` reaching
`Game.turnFaceOver` around `Resolve.turnOver`) is the usual miss.

### Mutation testing

`script/mutate.sh FILE SED_EXPR PATTERN [CABAL_ARG...]`, under the build lock,
backs the file up outside the tree, applies the mutation, runs the subtree
`PATTERN` selects, prints the first failing assertion, and restores the file.
Its exit status is the outcome (`--help`). It builds at `-O0` in
`dist-mutate/`: fast per mutation, though the first build after an interface
change recompiles every importer. Keep the pattern narrow. It does not judge
whether the assertion it names is the gameplay-level one; you do.

- **One mutation at a time, and read the failure.** It must go red for the
  intended reason in the intended place; a dozen unrelated failures proved
  something else.
- **Name the assertion it reddened**, its own message, and ask whether it is
  the gameplay-level one. If a cheap proxy ahead of it (a prompt count, a zone
  size) absorbed the mutation, reorder so the behavioural assertion comes
  first and re-run. `Parun.ExpirySpec`'s "CR 514.2 / 611.2a neither cleanup
  nor the handoff into bob's turn reaches it" is the worked example.
- **First is necessary, not sufficient:** the assertion must be able to
  DIFFER under the mutation. Ask what a wrong implementation would produce at
  the moment you read the value; for a counter, resolve the stack down.
- **Pass a script the guard refuses as `@FILE`** from your scratch folder.
  Never `git checkout <file>` to revert; `mutate.sh` restores from its own
  backup.
- **Run a mutation alone in its checkout,** after the suite: a build or
  commit beside it picks up the mutated line. `mutate.sh` restores its backup
  over the file, so an edit made during a run vanishes.
- **Build a negative as a pair of boards differing in exactly one thing.**
- **Point the pattern at the spec that reads the line**; a wrong subtree
  reports NOTHING RED, which looks like no observer.
  `Parun.Engine.Event.Binding`'s slots are pinned by
  `Parun.LeavesTriggerSpec`'s "eventBindingSlots names exactly", not
  `Parun.ZoneTriggerSpec`. Grep for the test first.
- **Anchor a sed whose text recurs** (`/a comment above it/{n;s/.../.../}`),
  and read the failure's condition name before believing it.
- **Keep the mutated binding referenced**, or `-Wunused-local-binds` turns a
  red into a build failure: `const Map.empty . f`, `filter (const False)`.
- **Use the narrowest path that shows the behaviour**; a whole priority loop
  can answer for the wrong reason.
- **Mutate towards LESS permissive.** `mutate.sh` passes no `--timeout`, so a
  mutation that loops the engine hangs; kill your own PID and mutate the
  other way.
- **Report a mutation you could not run** (holds by construction, or
  `-Werror` rejects it) at the site and in the PR: the assertion is a fence,
  not a proof.
- **Green means no observer.** Don't close the issue; add the card that gives
  the line an observer, or it is `wontfix` / `expires:synthetic`. A line kept
  because the CR states it says so at the site and in the PR.

After any merge from `origin/main`, run the suite first --- a card in a
superseded wire spelling fails `Parun.CardsSpec` and makes every lookup answer
`InvalidCorpus`; grep the corpus for the old spelling --- then re-run the
load-bearing mutations, since a bad resolution can neuter a test.

A wire rewrite through a decode alias cannot see a field whose default changes
meaning: a file omitting it decodes through the new codec (`Fields.object`
ignores unknown keys) and re-encodes as a value the round trip agrees with.
List every file that omits the field beside an old key and check each.

### Gameplay harness

Prefer a scenario: a JSON file under `data/scenarios/` (its README has the
format), or `Parun.Support`'s `S.board`, `S.turn`/`S.on` and `play` over the
same runner when a test must drive one engine entry point or assert what no
`Check` names. Extend its vocabulary only alongside a test that needs it.

Keep a test-local answerer when the prompt protocol is the subject, when
identical prompts need different answers, or when the harness would hide what
the test proves. The harness has no vocabulary for `Prompt.OrderTriggers`,
`ChooseMutateSide` or `ChooseTapsForTotalPower`; use `S.runPure` with a local
answerer (`Parun.AuraSpec`'s bestow group) and say so. A spec matching on
`Prompt` needs `GADTs`, hence `MonoLocalBinds`: give a local polymorphic `let`
a signature. A hand-built combat board needs `S.combatBoardOf`, or
`S.runCombat` runs no combat and a negative passes vacuously.

### Vacuity traps

Each has shipped a green-but-meaningless test here:

- Negative cast-gate assertions pass for unrelated reasons (no mana, timing,
  a non-empty stack): give every negative the positive board's mana.
- `Activate.activatable` answers `False` for every mana ability (CR 605.3b);
  assert at gameplay level.
- Two seats collapse "that player", "an opponent" and "the defending
  player"; use three.
- A fixture player decked by CR 104.3c loses first: stock libraries when the
  fixture draws or advances turns.
- Numeric coincidences: distinct values everywhere.
- A prompt short-circuits when candidates equal the count: offer more.
- A token exiled from a graveyard ceases to exist (CR 111.7).
- An answerer that searches for a legal option repairs the mutation: pin the
  answer by index.
- An answer equal to the engine's fallback (`Replay.defaultAnswer`, often
  index 0) proves nothing about the prompt.
- An answerer that BUILDS a recipient loses the target: a hand-built
  `Recipient.ToObject` is not the offered `Recipient.ToCreature`, and CR
  608.2b's re-read drops it silently. Filter the offered set.
- A pure `Prompt r -> r` answerer can't tell identical prompts apart: thread
  state (`countingAnswer` in `Parun.CopySpec`, `Parun.ManaSpec`).
- Fixtures supply preconditions: `S.addPermanent` settles sickness, `Board`
  does not. Assert the precondition on the board.
- `S.countOnBattlefieldByName` indexes by OWNER (CR 108.3);
  `Projection.controllerOf` is the control question.
- A board that can't tell two readings apart (same zone, same timestamp, one
  player in two roles): change the board, not the assertion.
- A rule stating exclusions needs each exclusion shown (CR 701.27g excludes
  both a previously turned face and a melded permanent).

### Cards

Fetch every card's Oracle text yourself (`CLAUDE.md`) and diff; for a
double-faced card read `card_faces`. A clause the DSL cannot express makes the
card stricter or weaker than printed: weaker in its controller's favour
disqualifies it; stricter is admissible with an issue and an inline `(#N)`.
A stale transcription looks exactly like a missing capability: grep
`data/cards/` for a card already using it before concluding. Having fixed one
card, sweep the corpus for its siblings.

### Prior art

`CLAUDE.md` says when to consult these (after the CR). Each is one grep:

- **`_scratch/phase`** finds the CARD: `crates/engine/tests/integration/`
  holds test files named for card and rule. Not a design reference.
- **`_scratch/mtgish`** gives the effect's SHAPE: `data/mtgish.lines.json`,
  vocabulary in `rust_syntax/src/mtg_types.rs`. Its grammar matches a whole
  card, so an unparsed card is absent, not partial (`grammars/ignore.json5`);
  a rule can still map text to a coarser constructor than the card needs.
- **`_scratch/argentum-engine`** answers MODELING questions.

A green test elsewhere means someone considered the case, not that their
answer is right. Ported code carries the MIT notice; card text is Wizards IP
whatever an engine's licence says.

### Prompts

Don't mint a bespoke resolution-time choice. `Parun.Types.Prompt`'s
`ChooseRingBearer`, `ChooseBolster`, `ChooseAmass`, `ChooseBlight` and
`ChooseCopyTarget` share one posture --- choose, not target; filter the
candidates rather than trusting the answer; prompt only when two or more
candidates make it a real choice. Deviate only where the rule does, and say
so in the PR.

### Follow-ups: fold in or file

- **Fold it in** unless it needs an owner design call, new engine state or a
  new core type, or would push the unit past ~300k tokens or ~300 tool uses.
  Fold anything costing one more proving test and roughly 30k tokens, even
  across module boundaries, and say so in the PR.
- **Never file a rules-correctness shortfall in behaviour your unit adds or
  makes reachable**: get it right or ship less.
- **One fix, every sibling site**, proved on the observable one; a sibling
  constructor of one you are adding is folded, not filed.
- **File** only what clears that bar, cited inline where the code elides it,
  naming the card that exercises it (a printing, or a synthetic draft). Only
  a rules reason lets a known problem go unfiled.

### Git and the PR

- **Leave the PR a draft.** The orchestrator marks it ready once any audit's
  fixes land. This overrides `CLAUDE.md`'s and `CONTRIBUTING.md`'s "mark it
  ready".
- When cut from another unit's branch, say so in the PR body.
- `git fetch` and merge `origin/main` immediately before self-review, then
  re-run the suite and the load-bearing mutations. Never force-push; resolve
  conflicts taking both sides.
- Measure the suite count, never infer it; re-measure after a merge.
- Landing a capability means reading its dependents (`CLAUDE.md` has the
  query) and naming the now-workable ones in the PR.
- Closing #N means grepping its bare number over the whole tree, again after
  the last merge. An issue only narrowed gets "related to #N" and a retitle
  naming what is left.
- Stage, `hooky fix`, stage again. `script/format-json.sh` takes `MODE
  FILE...` and passes vacuously when run bare.
- Nothing checks a CR citation but re-reading the rule in `docs/rules.txt`.
  After a CR update, grep the renumbered rules in the tree (fix in the PR) and
  in issue bodies (fix in a comment).

Then stop: don't wait on CI, don't start another unit.

## Auditing a unit

You are read-only: no build, test, compiler, branch, checkout, edit or PR, and
no issue comments or labels unless the brief says those are the deliverable.
Read other refs with `git show <ref>:<path>`. `gh issue view` returns nothing
for some agents; use `gh api repos/tfausak/parun/issues/N` and
`.../comments`. Prior art is a lead, never a citation.

### What a finding is

Behaviour that diverges from the CR or a ruling; a rules-core arm casing on an
effect's identity; a false CR classification in a comment; a mutation the PR
reports that could not have reddened the named assertion; a new constructor,
field or hand-kept list that should have been a parameter ("Parameters, not
siblings"); a test that does not prove what it claims. Prose is not a finding:
a wording nit or a stale citation still pointing at the right rule is left for
the next unit editing the file. Report each finding as board, action
sequence, engine behaviour, CR or ruling, file and identifier, confidence. "I
found nothing" is a result.

### Negative claims and carriers

"No printed card does this" is the least reliable claim in the tracker: search
the mechanic, not the card names already written down (`t:aura o:/morph/`). A
negative usually swept one axis; name it and ask what the neighbouring one
returns. "Needs a subsystem parun doesn't have" is verified at the CARRIER, the
type or function that would hold the behaviour: read it and name it. A false
claim can live in a code comment. A named producer can be unusable for a
reason the body never checked: check it against the vocabulary, not just
print. An omission called stricter than printed can run weaker. Cite
identifiers, never line numbers.

### Discriminating power

A test is a claim about two implementations and is worth something only if the
buggy one fails it. Name the asserted quantity and its value under each;
equal values mean the board can't discriminate. Walk the buggy implementation
to the END through the rules that fire on the way (CR 400.3 sending a found
card to its OWNER's hand is the classic collapse). Every board element needs a
reason; the unjustified one usually hides the collapse. Where the divergence
is a time, say which moment is read: an effect that ends and one that pauses
agree at the first read.

### Composition

Opcodes that each exist can be inert together: a VACUOUS ATOM cannot be false
(or true) because the field it reads was never filled on this path. For each:

- Trace to the call and name the function building the context.
  `Filter.Context`'s context-relative fields are empty in `Filter.contextFor`;
  in resolution they come from `Resolve.Slots.effectContext`.
- Ask what the atom answers against an empty field, per atom.
  `Filter.IsBound`, `Shares Name Bound`, `IsHostOfSource` and
  `HeldByRecipient` answer False; `Quantity.AgainstSlot` answers unanswered;
  `ControllerRelatesToBound` answers TRUE, widening the offer, and only
  `Parun.CardSpec`'s position lint keeps it out of positions with empty
  `slotControllers`.
- Read the guardrail: `Parun.CardSpec` fences some fields with a position
  lint; `recipient` carries none.
- Where two opcodes must see each other, say whether one builder supplies
  both. `IsBound` reads single and group bindings; `Quantity.AgainstSlot` and
  the other singular readers take the single one (`Filter.slotOneObject`); a
  target slot's own filter is matched before any binding exists
  (`Target.admittedGiven`).

When reading cannot settle it, say "these exist and I did not verify they
compose along PATH".
