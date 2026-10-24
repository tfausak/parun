# Driver, answerers and observers (unit 1 of #5182) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One game loop, `Parun.Engine.Driver`, that any answerer plugs into
(a scenario timeline now; a human, a bot, or chance later), with observers
that see every prompt and answer. `Parun.Scenario` is rebuilt on it with no
behaviour change.

**Architecture:** An `Answerer m` wraps the `forall r. Asked r -> m r`
callback that `Engine.runGameAsked` already takes. An `Observer m` is a
pair of hooks, run before and after each answer. `Driver.ask` composes the
two. `Driver.bySeat` routes a prompt to its seat's answerer via
`deciderOf`, which moves here from `Parun.Scenario.Prompt`. `Driver.match`
plays a whole game from a matchup. `Driver.drive` steps from a state until
the game ends, the step budget runs out, or a stop predicate holds. The
scenario timeline becomes one answerer, and its interleaved checks become
one observer.

**Tech Stack:** Haskell (GHC via the flake), cabal sublibraries, `Parun.Spec`
test DSL, transformers' `StateT`.

**Spec:** `docs/superpowers/specs/2026-10-17-play-portal-client-design.md`
(unit 1).

## Global Constraints

- No new non-boot dependency.
- The rules core never cases on an effect's identity, and nothing in this
  unit touches `Parun.Engine` rules modules.
- One type per module under `Parun.Types.<TypeName>`. Constructors take a
  `Mk` prefix, and a type unwraps through an `unwrap` field.
- Language extensions come only from `.hlint.yaml`'s allowlist (`GADTs` and
  `RankNTypes` are on it).
- Every existing scenario under `data/scenarios/` passes unchanged, and so
  does every `Parun.ScenarioSpec` case. No assertion is edited, weakened or
  deleted.
- This PR is unit 1 of #5182. Its body says "related to #5182", never a
  closing keyword.
- Naming: `Parun.Types.Decider` already exists (the seat that makes a
  controlled player's choices, CR 723.5). The new type is therefore
  `Answerer`, matching the tree's existing word for it.

## Review Focus

1. **A prompt raised inside a subgame (CR 729).** The checks observer must
   not run a timeline check against the subgame's state. The scenario still
   reports `MkNestedGamePrompt` (Task 2, Step 1).
2. **A refused move (CR 733.1) re-asks `ChooseAction`.** The observer runs
   again at the re-ask. `made` must stay a no-op there, because a refusal
   sets `reversing`, not `awaiting`. This is covered by the existing `Refuse`
   scenarios (Task 2, Step 4).
3. **A seat with no answerer in `bySeat`'s map** falls to the fallback, not
   to an error (Task 1 test `unmapped`).
4. **The game ends before the stop predicate holds.** `drive` returns the
   finished state instead of looping (Task 1 test `ends`).
5. **A budget of 0** returns the starting state untouched (Task 1 test
   `budget`).

---

### Task 1: `Parun.Engine.Driver` and its types

**Files:**
- Create: `source/libraries/types/Parun/Types/Answerer.hs`
- Create: `source/libraries/types/Parun/Types/Observer.hs`
- Create: `source/libraries/engine/Parun/Engine/Driver.hs`
- Create: `source/libraries/test/Parun/DriverSpec.hs`
- Modify: `source/libraries/test/Parun/Test.hs` (wire `DriverSpec.spec`)
- Modify: `source/libraries/scenario/Parun/Scenario/Prompt.hs` (delete
  `deciderOf`)
- Modify: `source/libraries/scenario/Parun/Scenario.hs` (call
  `Driver.deciderOf`)
- Modify: `source/libraries/test/Parun/ZoneChangeSpec.hs` (comment naming
  `Parun.Scenario.Prompt.deciderOf`)
- Modify: `parun.cabal` (stage it; `cabal-gild parun.cabal` regenerates the
  module lists)

**Interfaces:**
- Produces, used by Task 2 and units 3–5:
  - `Parun.Types.Answerer`:
    `newtype Answerer m = MkAnswerer {unwrap :: forall r. Asked.Asked r -> m r}`
  - `Parun.Types.Observer`:
    `data Observer m = MkObserver {before :: forall r. Asked.Asked r -> m (), after :: forall r. Asked.Asked r -> r -> m ()}`
  - `Driver.deciderOf :: Prompt.Prompt r -> Maybe PlayerId.PlayerId`
    (moved verbatim from `Scenario.Prompt.deciderOf`, comment and all)
  - `Driver.bySeat :: Map.Map PlayerId.PlayerId (Answerer.Answerer m) -> Answerer.Answerer m -> Answerer.Answerer m`
    (a prompt whose `deciderOf` is a mapped seat goes to that seat; every
    other prompt, chance included, goes to the fallback)
  - `Driver.ask :: (Monad m) => [Observer.Observer m] -> Answerer.Answerer m -> Asked.Asked r -> m r`
    (every `before` in list order, then the answer, then every `after` in
    list order)
  - `Driver.match :: (Monad m) => [Observer.Observer m] -> Answerer.Answerer m -> GameSettings.GameSettings -> NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> m (Result.Result, GameState.GameState)`
    (`Engine.runGameAsked (ask observers answerer)` over
    `Setup.gameWith settings (fmap fst matchup)` and
    `Engine.playFrom matchup`, the shape `Engine.runMatch` has)
  - `Driver.drive :: (Monad m) => [Observer.Observer m] -> Answerer.Answerer m -> Natural -> (GameState.GameState -> m Bool) -> GameState.GameState -> m GameState.GameState`
    (runs `Engine.runStep` repeatedly. It stops before a step when the
    budget is 0, `GameState.result` is `Just`, or the predicate answers
    `True`, and it decrements the budget by one per step)

- [ ] **Step 1: Write `Parun.DriverSpec`**

  The module's head comment says it covers `Parun.Engine.Driver`. Its
  signature is
  `spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()`,
  under `Spec.describe s "Driver"`. Every test plays
  `matchup <- S.redRed (S.printingOf s registry)` with `GameSettings.plain`,
  and answers inside `State.State` from `Control.Monad.Trans.State.Strict`.
  The tagging answerer used below is
  `tagged tag = MkAnswerer (\asked -> S.castAnswer (Asked.prompt asked) <$ State.modify' (<> [(tag, Driver.deciderOf (Asked.prompt asked))]))`.

  - `routes`: "each seat's prompts reach that seat's answerer, and chance
    reaches the fallback". Answer with
    `bySeat (Map.fromList [(S.alice, tagged "alice"), (S.bob, tagged "bob")]) (tagged "chance")`,
    and run `Driver.match [] ...` from an empty log. Assertions:
    - `"alice answered"`: some entry is tagged `"alice"`;
    - `"bob answered"`: some entry is tagged `"bob"`;
    - `"chance answered"`: some entry is tagged `"chance"`;
    - `"alice's only"`: every `"alice"` entry has `Just S.alice`;
    - `"bob's only"`: every `"bob"` entry has `Just S.bob`;
    - `"chance only"`: every `"chance"` entry has `Nothing`.
  - `unmapped`: "a seat with no answerer of its own reaches the fallback".
    Use `bySeat (Map.singleton S.alice (tagged "alice")) (tagged "rest")`.
    Assertion `"bob to rest"`: some `"rest"` entry has `Just S.bob`.
  - `observed`: "observers see each prompt before its answer and each
    answer after, in the order a recording does". The observer is:
    - `before`: appends `Nothing`;
    - `after`: appends `Just (Replay.encode (Asked.prompt asked) answer)`.

    Answer with `MkAnswerer (pure . S.castAnswer . Asked.prompt)`.
    Assertions:
    - `"alternates"`: the log alternates `Nothing`, `Just _`, starting with
      `Nothing`;
    - `"transcript"`: the `Just` values equal
      `snd (Replay.record S.castAnswer (Setup.gameWith GameSettings.plain (fmap fst matchup)) (Engine.playFrom matchup))`.
  - `stops`: "drive stops when its predicate says so". The start state is
    `snd (Engine.runGamePure S.castAnswer (Setup.gameWith GameSettings.plain (fmap fst matchup)) (Setup.newGame (Resolve.performHandAction Engine.playSubgame) matchup))`, with `Resolve` being `Parun.Engine.Resolve.Effect`.
    Run `drive [] castAnswerer 1000 (\gs -> pure (GameState.turnNumber gs >= 3)) start`.
    Assertions:
    - `"turn"`: `turnNumber == 3`;
    - `"unfinished"`: `result == Nothing`.
  - `ends`: "drive returns a finished game rather than outrunning it". Use
    the same start and `drive [] castAnswerer 100000 (const (pure False))`.
    Assertion `"finished"`: `GameState.result` is `Just`.
  - `budget`: "a budget of 0 takes no step". Assertion `"untouched"`: the
    result `== start`.

- [ ] **Step 2: Run it and watch it fail to compile** (`Parun.Engine.Driver`
  does not exist)

  Run:
  `script/with-build-lock.sh cabal build parun:test > "$SCRATCH/build.log" 2>&1`
  Expected: the module is not found.

- [ ] **Step 3: Create the two type modules and `Parun.Engine.Driver`**

  Each type module holds the type alone, with a one-line haddock. Move
  `deciderOf` and its whole comment verbatim, delete it from
  `Scenario.Prompt`, and repoint `Scenario.hs`'s call and `ZoneChangeSpec`'s
  comment. The module comment of `Driver` says what it is: the one loop
  every answerer plugs into (#5182).

- [ ] **Step 4: Stage `parun.cabal`, run `cabal-gild parun.cabal`, and run
  the new spec**

  Run:
  `script/with-build-lock.sh cabal run parun:test -- -p Driver > "$SCRATCH/t1.log" 2>&1`
  (use the suite's existing pattern flag, the one `docs/agents/implementing.md` shows)
  Expected: all six tests pass.

- [ ] **Step 5: Mutate**

  Mutate each of these away, one at a time, with `script/mutate.sh` (give
  it its script as `@FILE`), and record the assertion that reddens:
  - `bySeat` always uses the fallback: expect `"alice answered"`;
  - `ask` skips the `after` hooks: expect `"alternates"`;
  - `drive` ignores its predicate: expect `"turn"`;
  - `drive` ignores `GameState.result`: expect `"finished"`, or a hang
    caught by the suite timeout. Say which one in the PR.

- [ ] **Step 6: Commit** — `Add a driver that any answerer plugs into`

### Task 2: Rebuild `Parun.Scenario` on the driver

**Files:**
- Modify: `source/libraries/scenario/Parun/Scenario.hs`

**Interfaces:**
- Consumes: `Driver.ask`, `Driver.drive`, `Answerer`, `Observer` (Task 1).
- Produces:
  - `Scenario.timeline :: Answerer.Answerer Run`, which is `answerPrompt`;
  - `Scenario.checks :: Observer.Observer Run`.

  Later units reuse both, to replay a saved game.

- [ ] **Step 1: Pin the nested-game case.** Grep `ScenarioSpec` for
  `MkNestedGamePrompt`. If a case asserts it, note its name as the
  Review Focus 1 guard. If none does, add one first: copy the shape of the
  nearest `answerPrompt` failure case and assert the `MkNestedGamePrompt`
  failure. Run it green on the unmodified runner before going on.

- [ ] **Step 2: Move the two priority-time checks out of the answerer**

  Delete `made gs` and `runLeadingChecks key gs` from
  `answerActionPrompt`. `checks` is their new home:
  - its `before` hook runs only when `null (Asked.enclosing asked)` and the
    prompt is `ChooseAction who _ _`;
  - it then runs `made gs`, then `whenOf gs (Decider.unwrap who)`, then
    `runLeadingChecks key gs`;
  - its `after` hook is `\_ _ -> pure ()`.

  Re-asking at a refused move's `ChooseAction` re-runs both, harmlessly:
  `awaiting` is already `Nothing` and the leading checks are already popped.

- [ ] **Step 3: Route both entry points through the driver**

  - `playOut` becomes `Driver.drive [checks] timeline stepBudget stop`. Its
    `stop` keeps today's conditions apart from the budget: the queues are
    empty, or the turn is past the last one the timeline names.
  - `rehearse` uses `Engine.runGameAsked (Driver.ask [checks] timeline)`.
  - Delete `playOut` if it becomes a bare alias.

- [ ] **Step 4: Run the whole suite**

  Run:
  `script/with-build-lock.sh cabal run parun:test > "$SCRATCH/t2.log" 2>&1`
  Expected: every test passes, including every `data/scenarios` file. Record
  the test count before and after. If a `ScenarioSpec` failure-kind
  assertion now reports a different failure, stop and report it rather than
  editing the assertion. A check may now run ahead of a refusal or
  unused-choice failure at the same priority prompt.

- [ ] **Step 5: Mutate**
  - Pass `[]` instead of `[checks]` in `playOut`. Expect a `data/scenarios`
    file with an `expect` entry to fail with unrun checks, and record which
    one.
  - Drop the `null enclosing` guard. Expect the Step 1 case to redden, or
    record that nothing did.

- [ ] **Step 6: Commit** — `Run scenarios through the driver, checks as an observer`

### Task 3: Self-review and PR

- [ ] **Step 1:** Commit this plan and the spec
  (`docs/superpowers/specs/2026-10-17-play-portal-client-design.md`) on the
  branch.
- [ ] **Step 2:** Merge `origin/main` once. Stage everything, run
  `hooky fix`, and stage again.
- [ ] **Step 3:** Self-review per CLAUDE.md:
  - re-read every comment the diff touched;
  - grep `deciderOf` across the tree, so that no stale
    `Scenario.Prompt.deciderOf` remains, including in comments;
  - confirm `Engine.runMatch` and `Driver.match` are not a parameter pair
    that should be one function. `runMatch` takes a `Prompt`-level
    answerer; say in the PR why both stay, or fold `runMatch` into
    `Driver.match`.
- [ ] **Step 4:** Open the PR, draft until the suite is green, then ready.
  The body has a line each for:
  - what changed, with "related to #5182 (unit 1)";
  - the CR citations, 723.5 and 729.1 via `deciderOf`;
  - the design calls: the name `Answerer`, why checks are an observer, and
    that failure precedence may shift only for runs that already fail;
  - verification: the suite count before → after, and each mutation with
    the assertion it reddened, named;
  - the rules core cases on an effect's identity: no;
  - deferred: units 2–7.
