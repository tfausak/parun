# CLAUDE.md

Guidance for Claude Code (and other agents) working in this repository. Rules
only: the incidents that motivated them are in git history.

## What Parun is

A pure Haskell rules engine for *Magic: The Gathering*, a virtual machine in
two halves:

- A closed half: the comprehensive rules (turn structure, priority, the stack,
  zones, state-based actions, layers, combat). Finite; it can be finished.

- An open half: a first-order, non-recursive, statically-analyzable effect DSL,
  loaded as runtime data, never as Haskell modules. Grows forever.

The invariant that keeps them apart: the closed half depends on a
*classification* of effects (which layer, is it a mana ability, does it
target), never on an effect's *identity*. The rules core must never write
`case effect of DealDamage{} -> ...`; fusing the halves is the failure mode
that sinks this project --- audit for it. Keywords are rulebook (CR 702), so
`case keyword of Flying` is like casing on `Phase`.

The second invariant: the engine never makes a player's choice. Eliding a
prompt is legitimate only for indistinguishable options, and every elision
carries an issue. Where the rules leave nothing to ask, don't prompt.

Scope is four rings, worked in order: basic paper Magic, paper extras,
digital-only, non-engine (`docs/design.md` section 6). Rank work by ring first.

Read `docs/` by section, on demand, never a whole doc "for context".

- What's next? `gh issue list`
- Architecture rationale: `docs/design.md`
- Rules ground truth: `docs/rules.txt`, grepped by rule number --- never
  memory, and never a rule number quoted in an issue or a brief.
- Readings the rules don't force: `docs/decisions.md`, checked before deciding
  one and on every CR update
- Prior-art evidence: `docs/prior-art-lessons.md`
- What the milestone era established: `docs/progress.md` (frozen), newest first
- A landed unit's authoritative detail: `docs/superpowers/`
- Dispatched as a subagent, or running a set? `docs/agents/set-by-set.md` ---
  "Implementing a unit" if you hold the build, "Auditing a unit" if you are
  read-only; all of it and `docs/agents/orchestrating.md` if you orchestrate.

## Workflow

`CONTRIBUTING.md` has the loop --- issue, branch, TDD, draft PR --- and applies
to agents as written. What it doesn't say:

- Before a fresh worktree's first build, run `script/warm-worktree.sh seed
  <your worktree>`: it copies in the gitignored `cabal.project.local` (without
  it `pedantic` and `-Werror` are off) and clones finished `origin/main`
  builds, the suite's and `script/mutate.sh`'s `-O0` one. If it reports no
  warm build, copy `cabal.project.local` from the primary checkout by
  absolute path, as a command of its own, and build cold.

- Working in a worktree, NEVER `cd` to the primary checkout, not even to read:
  the isolation guard redirects only `git`, so other edits land on the owner's
  branch.

- The isolation guard refuses a command whose text holds the bare word
  `source`, a heredoc beside another command, or a `sed` expression carrying
  parentheses, a pipe, a `;` or a `$`. Grep as `grep -rn X . --include='*.hs'`
  or a quoted deeper path, run a heredoc as a command of its own, and give
  `script/mutate.sh` its script as `@FILE` from your scratchpad.

- Never `git stash`: every worktree shares one stash stack. Copy the file aside
  and move it back.

- Prefix every `cabal` call with `script/with-build-lock.sh`, test runs,
  mutation loops and ad hoc scripts included: `script/with-build-lock.sh cabal
  run -v0 parun -- test -p PATTERN`, never the built test binary. Kill a
  wedged run by its own PID, never `pkill -f`. Never pipe `cabal` into `head`
  or anything that closes the pipe early (it deadlocks holding a lock slot);
  redirect to a file and read the file.

- Derive against `origin/main`, not the working checkout: `git fetch`, then
  `git show origin/main:<path>` or a worktree cut from it. Grep for
  identifiers; line numbers in issue bodies are stale.

- Self-review the branch before opening the PR and fix the findings there. At
  minimum re-check every CR citation against `docs/rules.txt` and re-read
  every comment the change touched.

- The PR body carries the case for merging, a line each:
  - what changed and why, with `Closes #N` as bare text (backticks break the
    link). Never write close, fix or resolve next to an issue number you do
    not intend to close, in any phrasing, a denial included; write "related
    to #N". A keyword in any branch commit survives the squash.
  - the CR citations behind it
  - the design calls made, and the alternatives rejected
  - how it was verified: suite count before -> after, the proving test, and
    for each mutation the assertion it reddened, named.
  - whether the rules core cases on an effect's *identity* --- an explicit "no"
  - what was deferred

- Keep prose terse --- PR bodies, issue comments, commit messages, code
  comments --- with a citation in place of a quoted rule. Verify in full;
  write it up short. A commit message is a subject line and at most two
  sentences of why. A PR body is the bullets above and nothing else. Never
  trim the mutation line.

- Mention no one: everything is posted as the owner, the only person on the
  project. Put any `@` or `#` not meant to link in a code span.

- Mark the PR ready once the self-review's fixes are pushed and the suite is
  green, report it, and stop: don't wait for CI, don't start the next unit.
  One unit at a time per checkout. An orchestrated unit leaves it a draft,
  overriding `CONTRIBUTING.md`; the orchestrator marks it ready
  (`docs/agents/orchestrating.md`).

- STAGE, then `hooky fix` (staged files only; it runs every `.hooky.kdl` check
  and rewrites in place), then `git add` again. `--all` sweeps the tree; use
  it only when you suspect something landed unstaged.

- After a PR merges, before the next unit, ask: did anything catch you that
  your own checks didn't? did you violate an instruction? did you learn a
  project fact the repo doesn't record? Record such a fact here, in the
  section it bears on, as a rule, in the next unit's PR. Skip it when there
  is nothing.

- Most of what's left is card-driven: working an issue means finding the real
  card and adding it to `data/cards/`; "no producer in the pool" describes the
  work, not an excuse. A capability no card exercises is forbidden: an effect
  is not done until a card exercises it in a gameplay-level test
  (`docs/design.md` section 4). The one good reason to stop is a *rules* one:
  the card turns out not to exercise the thing. A scenario proves an ability,
  not a card: cards sharing an ability's Oracle wording share one scenario
  set, and a new scenario needs new wording or a new behaviour. The PR body
  names each card left without a scenario and the scenario covering it.

- Labels: `elision`, `gap`, `rules-correctness`, `bug`, and the expiry
  triggers `expires:milestone`, `expires:card-driven`, `expires:subsystem`,
  `expires:synthetic`. Priority labels are the owner's: prefer high priority
  when picking, never set one. `gap` (the capability does not exist) and
  `rules-correctness` (behaviour observably diverges) often both apply;
  `elision` excludes `rules-correctness`. `expires:card-driven` means add the
  card, not wait. No `expires:*` means the trigger already fired. Add an
  `area:*` label where one fits: the subsystem names, plus `area:keywords` (CR
  701/702), `area:effects` (the DSL), `area:cards` (card data, faces, layouts,
  schemas, lints), `area:stack` (CR 601/602/608), `area:variants` (CR 313/315,
  subgames, Commander, the Ring, dungeons), `area:client` (`parun play`:
  text client, line protocol, hotseat and bot seats).

- Verify Oracle text with `curl -s
  'https://api.scryfall.com/cards/named?fuzzy=<name>'` (WebFetch gets 403s).
  `/cards/search` needs a `User-Agent` header for regex queries and
  rate-limits a loop into empty bodies; for bulk querying use MTGJSON's
  `AllPrintings.json` in `_scratch/`. A dump is dated: sound for FINDING a
  card, unsound for ruling one out. In it there is no space after the colon
  (`"name":"Foo"`), and `rulings` sorts before `text`, so a hit near a name is
  usually ruling boilerplate.

- `_scratch/` (gitignored; a missing input is a fetch,
  `docs/agents/orchestrating.md`'s "Machine setup", and missing prior art a
  skipped step, not a blocker) holds
  prior art --- `phase`, `mtgish`, `argentum-engine`; see
  `docs/agents/set-by-set.md`, "Prior art". Consult it AFTER deriving the rule
  from `docs/rules.txt`; the CR wins every disagreement.

- A card whose whole text is keywords is ingested, never hand-written: `jq -f
  script/ingest/candidates.jq` over MTGJSON's `AtomicCards.json`, then `parun
  ingest` on the result. That run also stamps every pool card's faces'
  `oracleText` and names on stderr each card disagreeing with MTGJSON; re-run
  it after adding cards by hand.

- A card the DSL already expresses is translated before it is hand-written:
  `parun translate _scratch/mtgish/data/mtgish.lines.json CANDIDATES (NAME |
  @FILE | --set CODE)...`, CANDIDATES being the `candidates.jq` output. It
  writes only cards that render back to their Oracle text, naming every other
  on stderr with the node it stopped at; `--out DIR` writes the pool's own
  cards too, for comparison. An accepted ability marked `new` owes a
  scenario; a shared one does too unless a test of the card it names
  exercises it.

- `Filter.HasCardType` matches in every zone, but "a creature" with no zone,
  "card" or "spell" means a permanent (CR 109.2). Where nothing else confines
  a filter to the battlefield (a trigger's object filter, say), conjoin
  `IsInZone Battlefield`.

- When no printing can reach the rule, write `data/cards/synthetic-*.json`.
  Search first: a real card wins, in the order regular > Arena > playtest >
  un-set > synthetic (`docs/design.md` section 6), and a better-ranked card
  replaces a worse one whenever it turns up; a digital-only producer is
  ordinary card-driven work. A synthetic card is legitimate when you can cite
  the rule it exercises and the CR does not forbid such a card (that issue
  waits under `expires:synthetic`); when the absence is rules-*enforced*, the
  elision is provably sound --- close the issue as wontfix.

- A reading gets a `docs/decisions.md` entry, in the same PR, only when BOTH
  hold: it is observable (different game states or legal choices on some
  legal board), and not forced (neither the CR nor an official ruling picks
  one). The code site cites the entry. A forced reading --- including one
  whose rejected alternative is refuted by a rule or ruling --- cites it at
  the code site instead; an unobservable implementation choice goes in the PR
  body and gets at most a one-line code comment. Check there first, so a
  settled question is not decided again differently.

- File the issue, cite it inline. An elision gets an issue carrying status,
  rationale and expiry trigger, and a code-site comment stating only what is
  *not* implemented, plus `(#N)` --- never the expiry. That comment dies in
  the commit closing the issue; a comment citing the test that *proves* a
  behaviour outlives it.

  The WORDING is the convention, because a `grep` finds these; no script
  checks it, and none should. A comment paragraph saying "not implemented" is
  an elision paragraph; an elision phrased otherwise cites `(gap #N)`; a
  historical reference sharing a paragraph with an elision drops the
  parentheses (`see #1116`). Closing an issue means grepping its bare number
  over the whole tree and rewriting every elision citing it, in the same PR.

  Fold a known problem in or file it, naming the card that exercises it;
  `docs/agents/set-by-set.md`, "Follow-ups: fold in or file", has the rule.

  A BLOCKED issue records its blocker as a GitHub dependency, not prose (no
  `Blocked by #N` comment); a closed blocker keeps its link, and a blocker
  with no issue gets one filed first:

  ```
  gh api -X POST repos/tfausak/parun/issues/<N>/dependencies/blocked_by \
    -F issue_id="$(gh api repos/tfausak/parun/issues/<BLOCKER> --jq .id)"
  ```

  When a capability lands, read its dependents (`gh api
  repos/tfausak/parun/issues/N/dependencies/blocking`) and name in the PR body
  the issues it unblocked.

- A spec or plan is optional; commit one in the same PR when the unit
  warrants it. Following one, work its tasks in order, and never edit the
  plan, weaken an assertion, or delete a test to make a check pass. If the
  plan looks wrong, stop and say so.

## Before you consider a change done

1.  Distrust the issue body --- status, blockers and size estimate are
    routinely wrong. Re-derive against the tree before planning, and correct
    the issue in a comment.

2.  Verify a scripted edit's blast radius. Bulk `sed`/Python rewrites land in
    comments, strings, mid-case bodies, and comment groups that COUNT their
    members. Read the diff before staging; move an inserted arm out of a
    counted group and give it its own comment.

3.  Mutate the change away and re-run: break the line you wrote, confirm the
    new test *fails*, put it back. If the assertion that failed is not the
    gameplay-level one, an assertion ahead of it absorbed the mutation and
    the behaviour is unproven. If nothing fails, say so in the PR.
    `script/mutate.sh` runs one mutation; `docs/agents/set-by-set.md`,
    "Mutation testing", lists the traps.

4.  Find the sites `-Werror` won't. Grep the sibling constructor, read every
    hit, and record in the PR which you read and why each is right as it
    stands.

    A `{}` or `_` pattern absorbs a new constructor or field silently:
    `Parun.Engine.Event.Binding`'s `eventBindings` fallthrough,
    `Parun.ZoneTriggerSpec`'s hand-kept `everyTriggerCondition` and
    `representativeEvents`, `Parun.CardSpec`'s filter and keyword traversals.
    An `Arm.tagged` codec forces only the new constructor's tag; a tag with no
    arm encodes as `{}`, so it still owes a round-trip case. An `Arm.enum`
    codec needs neither.

    A TYPE THAT GAINS an ObjectId, a slot name or a Filter where it held none:
    `Parun.Engine.Interchangeable.Mentions` discards its fields by name and
    compiles on. Give the type a function there and turn each discard into a
    read.

    A CONSTRUCTOR GREP allows for the module ALIAS: `Keyword.Flying` is
    `Keyword.Type.Flying` in some modules (`Parun.Engine.Filter`'s
    `rewriteKeyword`).

    A NEW FIELD: grep every construction site by hand; positional
    construction in the test suite absorbs it in argument order. `Object` is
    the exception: its neutral value goes in `Object.new` once, and
    `Object.newIncarnation` resets it on every zone change unless carried
    across there.

    A RECORD UPDATE keeps the old value of a field you added, so a descent
    that rebuilds a record drops it: grep `{ SomeRecord.field = ` and say in
    the PR which you checked. The recurring site is
    `Parun.Engine.Projection.Rewrite`'s `rewriteEffect` (CR 612.1). The one
    update that keeps fields ON PURPOSE is
    `Parun.Engine.Resolve.Common.happenedBetween` (CR 603.12): any write an
    instruction makes whether or not it happened --- a prune, a cache, a
    stamp, a zero tally, in a new field or an existing one --- owes a
    copy-across there, or an ignored instruction arms its "when you do".

    A NEW READ OF A PERMANENT'S CARD goes through the projection
    (`Parun.Engine.Projection.View`) or the copiable record it stamps
    (`Game.copyStampOf`), never `Game.cardOf` or `Game.faceOf`, which answer
    the PRINTED card and misread a copy or a merged permanent
    (`Source.OfMerge`). Put a Clone of the producer in the test. A bare
    `Binding.copyOf` misses a conjured duplicate's values (`Object.duplicate`).

    A new field or disjunct on `Parun.Types.ProjectedCharacteristics` or
    `Parun.Engine.Filter`'s `View` is filled in EVERY builder:
    `Parun.Engine.Projection.View`'s `viewOfCard`, `viewOfCharacteristics`
    and `copiableCharacteristics`, and `Parun.Engine.Count`'s
    `viewOfSnapshot`. A `View` field read by id off the turn's log or a
    LastKnown field is `Count.lastKnownView`'s too.

    A DELETED TEST's orphaned helpers compile clean (spec modules have no
    export list): grep every top-level helper the deleted block called.

    WIDENING AN EXISTING FUNCTION'S RESULT has no tripwire, and a mutation
    proves only that your test sees your line: grep the callers, and say in
    the PR which paths you drove and which you did not.

5.  Every CR 701 keyword action and CR 702 keyword ability has its own issue
    (`gh issue list --label area:keywords --label gap`; there is no census),
    so landing one means closing that issue and grepping its bare number.

## Code conventions

`docs/style-guide.md` is the style guide and is not repeated here. The
project-specific rules it doesn't cover:

- No API stability obligations: rename, split, merge and re-sign freely ---
  never add deprecation shims or compat re-exports.

- One type per module under `Parun.Types.<TypeName>`, holding the type and its
  instances only; cross-type logic lives in other `Parun.*` modules.

- A constructor's haddock is ONE line saying what it means, plus its CR
  citation --- not the rule's text, an example or its history. Only two things
  earn more: an elision paragraph (what is NOT implemented, with its issue)
  and a note naming the test that PROVES a behaviour.

- Constructors take a `Mk` prefix and never pun the type name ---
  `newtype Name = MkName Text` --- except a smart constructor's `UnsafeX`.

- A constructor, field or function that differs from an existing one only by
  a parameter IS that parameter on the existing one: find the sibling,
  extend it, and name it in the PR body (`docs/agents/set-by-set.md`,
  "Parameters, not siblings").

- An exhaustive list --- of constructors, of fields, of the `GameState` rows
  something walks --- exists once. Derive a second from the first or add to
  the first.

- `applyOneEffect` stays one exhaustive `case`, each arm a call into
  `Parun.Engine.Resolve.Arms.*`, one function per `Effect` constructor beside
  its neighbours. A helper that never reaches `applyOneEffect` goes in
  `Parun.Engine.Resolve.Common`; one that does stays in
  `Parun.Engine.Resolve.Effect`, passed by the dispatcher to the arm calling
  it.

- A new `Parun.Types.Keyword` constructor that CARRIES A PAYLOAD owes a
  matching `Parun.Types.KeywordFamily` constructor ("a creature with toxic")
  in the same change; `-Werror` forces the `Parun.Engine.Keyword.familyOf` arm
  but not the family, since `Nothing` compiles.

## Adding a module

Which sublibrary a module belongs to, how `exposed-modules` is generated, and
where its spec goes: `docs/adding-a-module.md`. Read it before adding or
deleting a module.
