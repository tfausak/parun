# Adding cards set by set

What subagents running a set follow. `CLAUDE.md` and `CONTRIBUTING.md` apply
throughout and override this file except where it says otherwise. Rules only:
the incidents behind them are in git history.

Three roles. The **orchestrator** runs the set: it reads all of this file and
`docs/agents/orchestrating.md`, writes the briefs and owns GitHub. An
**implementer** holds a build in its own worktree and commits; it reads "What
every brief repeats" and "Implementing a unit". An **auditor** is read-only;
it reads "Auditing a unit".

## What every brief repeats

- Card-pool negatives ("no card does X") need the enumeration behind them.
- `parun ingest` may restamp out-of-set cards from a newer dump; say whether
  to keep or revert them, and have the agent list them.
- `parun translate` without `--out DIR` writes into `data/cards/`; every dry
  run passes `--out`.

## Implementing a unit

You hold a build; the brief carries only what is specific to your unit.
Finish in about 150 turns: nearing that with work left, commit, report, and
leave the rest to a fresh unit.

### Distrust the brief and the issue

A brief's reading holds up (whether a blocker landed, which producer works,
edit sites, CR citations); what needs a compiler does not (wire spellings,
line numbers, mutation predictions). `curl` the Oracle text and diff it
against the brief, grep the sibling to confirm edit sites, and re-derive the
mutations. A predicted-red mutation that comes back green is a finding: the
board cannot discriminate, or the site has no observer. Diagnose which.

Check which issue, and which half of a split one ("the other half stays on
#N"), you are closing. The cheapest first move is to find the funnel --- the
one function every path to the behaviour goes through --- and read what it
already gates or orders.

Seed from the warm worktree (`CLAUDE.md`); if it is missing, say so in the PR.
Never build in the warm worktree.

### Running the suite

    script/with-build-lock.sh cabal run -v0 parun -- test -p PATTERN --hide-successes

`PATTERN` is a tasty pattern over the `Spec.describe` group names, passed
unsplit (`--test-options` splits on spaces). Iterate on your subtree, and run
the whole suite before each commit. Redirect output to a file and read the
file. Build with `cabal build -v0`. No `cabal clean`; keep the optimizer on
for the suite (mutations are the exception).

Run `cabal` in the foreground with a generous timeout and split long runs by
pattern; a run at 0% CPU for ten minutes is wedged.

The timeout catches infinite loops, not slowness: use the one budget in
`flake.nix`'s `testFlags` and `.github/workflows/ci.yml`, which must agree. A
lone TIMEOUT on a shared machine is noise until it repeats unloaded.

### Reading code

Everything a command prints is re-read every turn after, so read narrowly.
Run `script/tags.sh` once in the worktree; a definition is then one lookup
(`grep -P '^castUse\t' tags` gives file and line), and `sed -n` reads just
that span. `grep -n` the identifier only to find its uses. Never page through
a whole module, never re-read what is already in the context, and send long
output to a file, reading only the lines that matter. Auditors read the same
way.

A question that takes many reads --- every site reading a slot, every pool
card using a constructor, how a funnel orders its callers --- goes to an
Explore subagent (`model: haiku` for a lookup, `sonnet` for a judgement),
briefed with the question and the paths. Verify a claim it makes before
relying on it.

### Enumerate the edit sites in one pass

When you add a constructor or field, grep a sibling to enumerate every site
and patch them all before rebuilding, rather than letting `-Werror` name them
one build at a time. Then find the sites `-Werror` will not name
(`CLAUDE.md`, "Before you consider a change done").

### Parameters, not siblings

Before adding a constructor, field or function, grep for one the new thing is
an instance of:

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
  for counting absolutes (`one`, `only`, `no card`, `the pool's`); a second
  producer falsifies them.
- **A new negative** prefers the citation: usually it explains an unbuilt
  slot, an elision, so `Not implemented: ... (#N)` or `(gap #N)`. Otherwise
  record the query and its date, not the conclusion (Scryfall `o:"deals
  damage to" o:"that source"`, 2026-08-18, no hit). Build the query from the
  printed template, never a constructor name; scope the noun (`data/cards/`
  or every printing); and name the card that WOULD refute you.
  `Parun.Types.SpendManaAsThough`'s `only` field is the model.

### Stale reads

A consumer reading a snapshot where the rule asks about live state is the
recurring defect: a gate reading bindings captured when resolution began
cannot see a slot an earlier clause defined. When you add a gate, prompt or
condition, ask what it reads and when that was captured
(`Parun.Engine.Resolve.gateHolds` and its callers). One writer, every road:
when you record an event, grep every function performing the action; a road
around the funnel (`Daytime.turnDue` reaching `Game.turnFaceOver` around
`Resolve.turnOver`) is the usual miss.

### Mutation testing

`script/mutate.sh FILE SED_EXPR PATTERN [CABAL_ARG...]`, under the build lock,
backs the file up outside the tree, applies the mutation, runs the subtree
`PATTERN` selects at `-O0` in `dist-mutate/`, prints the first failing
assertion, and restores the file; its exit status is the outcome (`--help`).
Keep the pattern narrow. Whether the assertion it names is the gameplay-level
one is your judgement.

- **One mutation at a time, and read the failure.** It must go red for the
  intended reason in the intended place.
- **Name the assertion it reddened.** If a cheap proxy ahead of the
  behavioural one (a prompt count, a zone size) absorbed it, reorder so the
  behavioural assertion comes first and re-run. `Parun.ExpirySpec`'s "CR
  514.2 / 611.2a neither cleanup nor the handoff into bob's turn reaches it"
  is the worked example.
- **First is necessary, not sufficient:** the assertion must be able to
  DIFFER under the mutation. Ask what a wrong implementation would produce at
  the moment you read the value; for a counter, resolve the stack down.
- **Never `git checkout <file>` to revert**; `mutate.sh` restores from its own
  backup.
- **Run a mutation alone in its checkout,** after the suite: a build, commit
  or edit beside it picks up the mutated line or is overwritten by the
  restore.
- **Build a negative as a pair of boards differing in exactly one thing.**
- **Point the pattern at the spec that reads the line**; a wrong subtree
  reports NOTHING RED. Grep for the test first: `Parun.Engine.Event.Binding`'s
  slots are pinned by `Parun.LeavesTriggerSpec`'s "eventBindingSlots names
  exactly", not `Parun.ZoneTriggerSpec`.
- **Anchor a sed whose text recurs** (`/a comment above it/{n;s/.../.../}`),
  and read the failure's condition name before believing it.
- **Keep the mutated binding referenced**, or `-Wunused-local-binds` turns a
  red into a build failure: `const Map.empty . f`, `filter (const False)`.
- **Use the narrowest path that shows the behaviour**; a whole priority loop
  can answer for the wrong reason.
- **Mutate towards LESS permissive.** `mutate.sh` passes no `--timeout`; if a
  mutation loops the engine, kill your own PID and mutate the other way.
- **Report a mutation you could not run** (holds by construction, or
  `-Werror` rejects it) at the site and in the PR: the assertion is a fence,
  not a proof.
- **Green means no observer.** Don't close the issue; add the card that gives
  the line an observer, or it is `wontfix` / `expires:synthetic`. A line kept
  because the CR states it says so at the site and in the PR.

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

Fetch and diff every card's Oracle text yourself (`CLAUDE.md`); for a
double-faced card read `card_faces`. A clause the DSL cannot express makes the
card stricter or weaker than printed: weaker in its controller's favour
disqualifies it; stricter is admissible with an issue and an inline `(#N)`.
A stale transcription looks exactly like a missing capability: grep
`data/cards/` for a card already using it before concluding. Having fixed one
card, sweep the corpus for its siblings.

### Prior art

Consult after the CR (`CLAUDE.md`). Each is one grep:

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
  naming the card that exercises it (a printing, or a synthetic draft) ---
  never dropped for want of a card in the pool. Only a rules reason lets a
  known problem go unfiled.
- **Blocked is a good outcome.** A unit that cannot land adds
  `needs-planning`, links its blocker as a dependency (`CLAUDE.md`), or, where
  the blocker is an owner decision, names the question. A decomposition beats
  a half-landed unit.

### Git and the PR

- When cut from another unit's branch, say so in the PR body.
- **Merge `origin/main` once**, immediately before self-review, never
  mid-work; never force-push, and resolve conflicts taking both sides. Then
  run the suite first --- a card in a superseded wire spelling fails
  `Parun.CardsSpec` and makes every lookup answer `InvalidCorpus`, so grep the
  new cards for any JSON key a merged PR renamed --- and re-run the
  load-bearing mutations, since a bad resolution can neuter a test.
- Measure the suite count, never infer it; re-measure after a merge.
- Grep a closed issue's bare number again after the last merge. An issue
  only narrowed gets "related to #N" and a retitle naming what is left.
- `script/format-json.sh` takes `MODE FILE...` and passes vacuously when run
  bare.
- After a CR update, grep the renumbered rules in the tree (fix in the PR) and
  in issue bodies (fix in a comment).

## Auditing a unit

You are read-only: no build, test, compiler, branch, checkout, edit or PR, and
no issue comments or labels unless the brief says those are the deliverable.
Read other refs with `git show <ref>:<path>`. If `gh issue view` returns
nothing, use `gh api repos/tfausak/parun/issues/N` and `.../comments`. Prior
art is a lead, never a citation.

### What a finding is

Behaviour that diverges from the CR or a ruling; a rules-core arm casing on an
effect's identity; a false CR classification in a comment; a mutation the PR
reports that could not have reddened the named assertion; a new constructor,
field or hand-kept list that should have been a parameter ("Parameters, not
siblings"); a test that does not prove what it claims. Prose is not a
finding: leave a wording nit, or a stale citation still pointing at the right
rule, to the next unit editing the file. Report each finding as board, action
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

A test is worth something only if the buggy implementation fails it. Name the
asserted quantity and its value under each; equal values mean the board can't
discriminate. Walk the buggy implementation to the END through the rules that
fire on the way (CR 400.3 sending a found card to its OWNER's hand is the
classic collapse). Every board element needs a reason; the unjustified one
usually hides the collapse. Where the divergence is a time, say which moment
is read: an effect that ends and one that pauses agree at the first read.

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
