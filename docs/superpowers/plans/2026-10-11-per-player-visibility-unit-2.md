# Per-player visibility, unit 2: lasting reveals

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A card revealed by a cost, by an activation from a hidden zone, by a reveal that causes a trigger, or from an opening hand stays visible to every player for as long as the CR says (CR 701.20a, 702.49b, 702.57b, 702.94b, 103.6b), and `sees` reads it.

**Architecture:** A per-incarnation field, `Object.revealed :: Maybe RevealWindow`, is stamped at each writer and reset by `Object.newIncarnation`, so a zone change ends a reveal (CR 400.7) with no code. Nothing sweeps the field: `Parun.Engine.Visibility.sees` gains one term that answers `Visible` to every seat while the window is live, and liveness is derived from the state.

**Tech Stack:** Haskell (GHC via the repo's nix flake), cabal, tasty, JSON scenarios under `data/scenarios/`.

**Spec:** `docs/superpowers/specs/2026-10-11-per-player-visibility-design.md`, section "Unit 2". Read that section only.

## Global Constraints

- Work only in `/Volumes/nvme/Developer/parun/.claude/worktrees/1408-lasting-reveals` (branch `1408-lasting-reveals`, cut from `origin/main` at 507d8680d). Never `cd` to the primary checkout. Before the first build, run `script/warm-worktree.sh seed /Volumes/nvme/Developer/parun/.claude/worktrees/1408-lasting-reveals` and confirm `ls cabal.project.local`.
- Merge `origin/main` ONCE, in Task 5 Step 1, never mid-plan.
- Prefix every `cabal` call with `script/with-build-lock.sh`. Redirect output to a scratchpad file and read the file; never pipe into `head`.
- Scenario test names are the bare FILE NAME, so select them by a file-name stem: `-p lasting-reveal`, which every scenario this unit adds carries. Spec groups are selected by their `describe` text. The command is `script/with-build-lock.sh cabal test --test-options '--timeout 120s --hide-successes -p <pattern>' > "$SCRATCH/x.log" 2>&1`.
- Full suite: the same command with no `-p`. Record the count before Task 1.
- The rules core never cases on an effect's identity. Casing on `Keyword.Forecast` (CR 702) and on a `RevealCause` is allowed; casing on an `Effect` constructor is not.
- CLAUDE.md item 4 applies in full to the new `Object` field: `Object.new`, `Codec.Object` plus `Parun.Codec.ObjectSpec`'s positional `MkObject`, `Parun.Engine.Reversal.objectWith`, and `Parun.Engine.Interchangeable` (the field holds an `ObjectId`). Grep `{ Object.` record updates too.
- One type per `Parun.Types.<TypeName>` module. A constructor's haddock is one line plus its CR citation. Every new codec gets a spec round-trip case.
- Style: `case` over `maybe`, `let` over `where`, no backticks, no partial `head`, extensions only from `.hlint.yaml`.
- Every proving check gets a mutation: `script/with-build-lock.sh script/mutate.sh FILE @SCRIPT PATTERN`, with the sed script in a scratchpad file, keeping every import and binding used (`-Werror`). Name the assertion that reddened. Never edit a file while a mutation runs on it.
- Never stash. Stage, `hooky fix`, `git add` again.
- Commits are a subject line and at most two sentences of why, with the trailers `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01N6oeJknHeSC1oKJ3H5pihY`. A commit says "related to #1408"; never close, fix or resolve next to an issue number in a commit.
- CR text comes from `docs/rules.txt`, by number. Checked 2026-10-11: 103.6b, 400.7, 602.2a, 603.10a, 701.20a, 702.49b, 702.57b, 702.94b.

## Divergences from the spec

- **Serum Powder does not prove CR 103.6b.** Its mulligan action is `ExileHandThenDraw`, which reveals nothing. No-Regrets Egret's reveal is a CR 103.5b mulligan action, the momentary case. Chancellor of the Forge is the only CR 103.6b producer. Scenario boards start mid-turn and cannot express the pre-game window (`data/scenarios/README.md`: setup is a state), so its proof is a `Parun.MulliganSpec` test.
- **Forecast gets a third window.** CR 702.57b keeps the card revealed "until it leaves the player's hand or until a step or phase that isn't an upkeep step begins". That outlives the ability on the stack, so `WhileOnStack` would end it too early. Steeling Stance is in the pool.
- **"The first turn begins" is derived from the log.** `Setup` sets `turnNumber = 1` before the mulligans, so the turn number cannot say. The window is live while `turnNumber == 1` and no `GameEvent.StepBegan` is in `GameState.events`. The log is cleared at turn handoff, where `turnNumber` rises, and `Engine` logs `StepBegan` as each step begins. Task 1 Step 2 confirms that the first step of turn 1 logs it; if it does not, stop and report.
- **CR 603.10a's "an object that all players can see" reader is not switched.** `Parun.Engine.Event.Match` decides it from the zone's hidden-ness alone, so a revealed card leaving a hand under-reads. Moving it onto the new status needs the departed incarnation's window, and that is its own change. Task 5 files it with a producer.

## Review Focus

1. **The window ends when the stack object leaves.** A revealed card in hand must stop being visible to the opponent once the ability resolves, not merely be visible while it is pending. Test: Task 3 (miracle), the check after the trigger resolves and the Wrath stays in hand.
2. **A cost reveal on a spell.** The window tracks the SPELL's stack object, not the revealed card's. Test: Task 2 (Living Destiny), the checks during and after resolution.
3. **Forecast outlives its ability.** The card stays revealed after the ability resolves, for the rest of the upkeep, and not after. Test: Task 4 (Steeling Stance), the checks in Upkeep after resolution and then in Draw.
4. **The opening-hand reveal ends as the first turn begins.** Test: Task 1, `Parun.MulliganSpec`.
5. **A zone change ends the reveal.** The ninja goes from hand to battlefield, and its hand incarnation's window must not follow it. Test: Task 4, after the ninjutsu resolves.

---

### Task 1: The window, its liveness, and CR 103.6b

**Files:**
- Create: `source/libraries/types/Parun/Types/RevealWindow.hs`
- Create: `source/libraries/codec/Parun/Codec/RevealWindow.hs` and `source/libraries/codec/Parun/Codec/RevealWindowSpec.hs` (pattern: `Parun.Codec.RevealCause`, `Parun.Codec.RevealCauseSpec`)
- Modify: `source/libraries/types/Parun/Types/Object.hs` (field after `exileLookers`, plus `new`)
- Modify: `source/libraries/codec/Parun/Codec/Object.hs`, `source/libraries/codec/Parun/Codec/ObjectSpec.hs`
- Modify: `source/libraries/engine/Parun/Engine/Reversal.hs` (`objectWith`, compile-forced)
- Modify: `source/libraries/engine/Parun/Engine/Interchangeable.hs` (read the new ObjectId)
- Modify: `source/libraries/engine/Parun/Engine/Visibility.hs` (the new term)
- Modify: `source/libraries/engine/Parun/Engine/Event.hs` (the stamp helper)
- Modify: `source/libraries/engine/Parun/Engine/Mulligan.hs` (the CR 103.6b writer)
- Test: `source/libraries/test/Parun/MulliganSpec.hs`

**Interfaces:**
- Produces:
  - `Parun.Types.RevealWindow.RevealWindow`, with constructors `WhileOnStack ObjectId`, `UntilFirstTurn` and `DuringUpkeep Natural`.
  - the field `Object.revealed :: Maybe RevealWindow`.
  - `Parun.Engine.Event.stampReveal :: RevealWindow -> ObjectId -> Game ()`.
  - `Parun.Engine.Visibility.revealedNow :: ObjectId -> GameState -> Visibility`.

- [ ] **Step 1: Baseline.** Seed the worktree, run the full suite, and record the count.

- [ ] **Step 2: Confirm the first-turn signal.** Read `Parun.Engine.Engine` where `GameEvent.StepBegan` is recorded, and where the turn handoff clears `GameState.events`. Confirm that turn 1's first step logs `StepBegan` before any player gets priority, and that `Setup.newGame` and `Setup.restartGame` start with no `StepBegan` in the log. If either fails, stop and report NEEDS_CONTEXT.

- [ ] **Step 3: Write the failing test.** In `Parun.MulliganSpec`, beside the existing Chancellor of the Forge test (it uses `chancellorGame`, `revealedNames` and `throughFirstUpkeep`), add `"CR 103.6b a card revealed from the opening hand stays revealed until the first turn begins"`. It runs the opening-hand window with Chancellor revealed, then asserts:
  - `Visibility.sees` for the OPPONENT on the Chancellor in its owner's hand is `Visible` before the first turn;
  - the same read after the first turn's first step has begun (drive the game the way `throughFirstUpkeep` does) is `Obscured`.

  Find the Chancellor's id the way the existing test finds it. Run `-p '103.6b a card revealed'` and expect a failure on the first assertion (`Obscured`).

- [ ] **Step 4: The type.** In `Parun.Types.RevealWindow`:

```haskell
module Parun.Types.RevealWindow where

import Numeric.Natural (Natural)
import Parun.Types.ObjectId (ObjectId)

-- | How long a lasting reveal lasts (CR 701.20a).
data RevealWindow
  = -- | CR 701.20a: until that spell or ability leaves the stack.
    WhileOnStack ObjectId
  | -- | CR 103.6b: until the first turn begins.
    UntilFirstTurn
  | -- | CR 702.57b: until a step that isn't that turn's upkeep begins.
    DuringUpkeep Natural
  deriving (Eq, Ord, Show)
```

Match the import style of the sibling type modules.

- [ ] **Step 5: The field.** In `Object.hs`, after `exileLookers`:

```haskell
    -- | CR 701.20a: how long this card stays revealed, if it is.
    --
    -- Per-incarnation: reset by newIncarnation (CR 400.7), which is each window's
    -- "until it leaves the zone".
    revealed :: Maybe RevealWindow.RevealWindow,
```

`new` writes `revealed = Nothing`. Confirm that `newIncarnation` does not carry the field. Then add it to:
  - `Codec.Object`, as a `Fields.defaulted` line like `exileLookers`'s, and in the `MkObject` slot;
  - `ObjectSpec`'s positional `MkObject` and its JSON strings;
  - `Reversal.objectWith`.

Write `Parun.Codec.RevealWindow` in the style of `Parun.Codec.RevealCause` (an `Arm.tagged` codec, so give every constructor an arm). `RevealWindowSpec` round-trips all three constructors. Wire the spec the way `RevealCauseSpec` is wired.

- [ ] **Step 6: Interchangeable.** `WhileOnStack` names an object. Read how `Parun.Engine.Interchangeable` treats `Object.exileLookers` and `Object.attachedTo` (`objects` compares Objects whole; `namedByAnother` reads `attachedTo` and `bindings`). If `Mentions` (or its equivalent) enumerates Object fields by name, make the new field a read rather than a discard. If nothing enumerates fields there, the whole-Object comparison already distinguishes two cards with different windows: record which case you found, and why it is right, in the report.

- [ ] **Step 7: The stamp and the liveness term.** In `Parun.Engine.Event`, beside `reveal`:

```haskell
-- | CR 701.20a: keep a revealed card revealed for a window.
stampReveal :: RevealWindow.RevealWindow -> ObjectId -> Game ()
stampReveal window oid = State.modify (\gs -> gs {GameState.objects = Map.adjust (\obj -> obj {Object.revealed = Just window}) oid (GameState.objects gs)})
```

If the module already has an object-update helper, use it; match the module's idiom. In `Parun.Engine.Visibility`:

```haskell
-- | CR 701.20a: a card in a lasting reveal is seen by every player while its
-- window is live.
revealedNow :: ObjectId -> GameState.GameState -> Visibility.Visibility
revealedNow oid gs =
  let begun logged = case LoggedEvent.event logged of
        GameEvent.StepBegan _ -> True
        _ -> False
      live window = case window of
        RevealWindow.WhileOnStack sid -> Game.zoneOf sid gs == Just Zone.Stack -- CR 701.20a
        RevealWindow.UntilFirstTurn -> GameState.turnNumber gs == 1 && not (any begun (GameState.events gs)) -- CR 103.6b
        RevealWindow.DuringUpkeep turn -> GameState.turnNumber gs == turn && GameState.phase gs == Phase.Beginning BeginningStep.Upkeep -- CR 702.57b
   in case Game.lookupObject oid gs >>= Object.revealed of
        Nothing -> Visibility.Obscured
        Just window -> visibleIf (live window)
```

The `_` arm in `begun` is over `GameEvent`, which is legitimate here: only `StepBegan` answers. In `sees`, join the term on both branches: `revealedNow oid gs <> case Game.zoneOf oid gs of ...`.

`WhileOnStack` checks the stack object's zone, not whether the object exists, because `stackArchive` keeps a departed stack object.

- [ ] **Step 8: The CR 103.6b writer.** In `Mulligan.handWindowExcept`, after `perform` runs an action for which `revealsItself` holds, and ONLY when `cap == RevealOncePerCard` (CR 103.6's window, not CR 103.5b's `Repeatable` one), call `Event.stampReveal RevealWindow.UntilFirstTurn` on the card. Rewrite `handWindow`'s CR 103.6b elision (lines ~170-175, citing #3045): the second sentence is now implemented, and its proof is the new MulliganSpec test.

- [ ] **Step 9: Green, then mutations.** Run `-p '103.6b a card revealed'`, `-p RevealWindow` and `-p Object` (the codec specs), then the full suite.

  Mutations; name the assertion that reddens for each:
  - **m1** (Mulligan.hs): drop the stamp, or guard it on `False`. Expect the "before the first turn" assertion to redden.
  - **m2** (Visibility.hs): drop `not (any begun ...)` to `True`. Expect the "after the first step began" assertion to redden.
  - **m3** (Visibility.hs): drop `revealedNow oid gs <>` from `sees`. Expect the first assertion to redden.

- [ ] **Step 10: Commit.** "Keep a revealed card revealed for its window, and the opening hand's until the first turn".

### Task 2: A cost reveal lasts while its spell or ability is on the stack

**Files:**
- Modify: `source/libraries/engine/Parun/Engine/Cost.hs` (the cost-reveal sites: `RevealCardFromHand` ~6627, `beholdObjects`' hand case ~2419, `RevealTopOfLibrary` ~6359; grep `Event.reveal` in the file)
- Create: `data/scenarios/cost/cr-701-20a-lasting-reveal-living-destiny-s-revealed-card-stays-revealed-while-it-is-cast.json`

**Interfaces:**
- Consumes: `Event.stampReveal`, `RevealWindow.WhileOnStack`, `View.Seers` and `Visibility.revealedNow` from Task 1.

- [ ] **Step 1: Find the stack object's id at each site.**
  - For a spell, the stack object is minted by `Event.changeZoneCasting` before costs are paid, and `payPayable` receives it as its `oid` (Cast.hs ~2466, ~3587).
  - For an activation, `payPayable`'s `oid` is the SOURCE, and the ability's id reaches Cost only as `announced :: Maybe ObjectId` (Activate.hs ~416, Cost.hs ~4850).
  - Read both. Choose the smallest threading that gives every cost-reveal site the id of the stack object being paid for, and record it in the report.
  - A cost-reveal site for which no stack object exists (a cost paid outside casting or activating, CR 118.12a) stamps nothing and stays as it is. Say which sites those are.

- [ ] **Step 2: Write the failing scenario.** Start from `data/scenarios/cost/cr-701-20a-the-revealed-card-s-mana-value-is-the-life-gained.json`, keeping its board, its cast of Living Destiny and its choices. Label the creature card it reveals in hand (`$shown`), if the board does not already. Checks, all keyed to the caster:
  - before the cast: `{ "View": { "of": "Seers", "object": "$shown", "is": ["alice"] } }` (use the caster's seat label);
  - after the cast, with Living Destiny on the stack: `"is": ["alice", "bob"]`;
  - after `"Pass"` and `{ "View": { "of": "Stack", "is": [] } }`: back to `["alice"]`.

  If the revealed card is not still in hand when Living Destiny resolves, check `Seers` on a card that is, or report. Do not change what the scenario proves. Run `-p lasting-reveal` and expect the second check to fail.

- [ ] **Step 3: Stamp at every cost-reveal site.** After each site's `Event.reveal`, call `Event.stampReveal (RevealWindow.WhileOnStack stackId) card`. Rewrite Cost.hs's elision paragraph (~6614-6621, citing #1408); it is now implemented.

- [ ] **Step 4: Green and mutations.** Run `-p lasting-reveal`, then the full suite. For **m4**, drop the stamp in the `RevealCardFromHand` arm; expect the during-cast check to redden. If a pool card reaches an ACTIVATION's cost reveal (grep `data/cards` for `RevealCardFromHand`, `Behold` and `RevealTopOfLibrary` inside `activatedAbilities`), add a scenario for it with the same three checks, plus a mutation. Otherwise say in the report that the activation path is unproven.

- [ ] **Step 5: Commit.** "Keep a cost's revealed card revealed while its spell or ability is on the stack".

### Task 3: A reveal that causes a trigger lasts while the trigger is on the stack (miracle)

**Files:**
- Modify: `source/libraries/engine/Parun/Engine/Engine.hs` (`placeBorne`, ~840)
- Modify: `source/libraries/engine/Parun/Engine/Event.hs` (`offerMiracleReveal`'s elision, ~8757)
- Create: `data/scenarios/event-trigger/cr-702-94b-lasting-reveal-the-miracle-card-stays-revealed-while-its-trigger-is-on-the-stack.json`

- [ ] **Step 1: Write the failing scenario.** Start from `data/scenarios/event-trigger/cr-121-9-the-draw-step-s-own-draw-opens-the-window.json` (turn 2, Wrath on top). Keep its board and the `OfferedMiracleReveal` → `Exercises` answer. After the existing `{ "View": { "of": "Stack", "is": ["trigger of Thunderous Wrath"] } }` check:
  - add `{ "View": { "of": "Seers", "object": "Thunderous Wrath", "is": ["alice", "bob"] } }`, using the seat labels the board uses, with the drawer first in turn order;
  - then `"Pass"`, and answer the trigger's `OfferedCast` with `{ "type": "Declines" }` (confirm the spelling in `data/scenarios/README.md`'s `Answer` paragraph), so the Wrath stays in hand;
  - after the stack is empty: `Seers` is the drawer alone.

  Run `-p lasting-reveal`; expect the first `Seers` check to fail.

- [ ] **Step 2: Stamp at placement.** In `placeBorne`, after the trigger's id (`abilId`) is minted: if the pending trigger's `firedBy` is a `GameEvent.Revealed` event, call `Event.stampReveal (RevealWindow.WhileOnStack abilId)` on that event's card. This is CR 701.20a's generic "if revealing a card causes a triggered ability to trigger"; cases on `GameEvent.Revealed` and not on miracle. The stamp happens at placement, which is CR 701.20a's last sentence: the card is unmarked between the reveal and the next time a player would receive priority. Rewrite `Event.offerMiracleReveal`'s elision (~8757, citing #1408).

- [ ] **Step 3: Green and mutations.** Run `-p lasting-reveal` and the full suite.
  - **m5**: drop the `placeBorne` stamp. Expect the during-trigger check to redden.
  - **m6**: in `revealedNow`, replace `Game.zoneOf sid gs == Just Zone.Stack` with `True`. Expect the after-decline check to redden.

- [ ] **Step 4: Commit.** "Keep a card whose reveal triggered an ability revealed while that ability is on the stack".

### Task 4: An activation from a hidden zone, and forecast

**Files:**
- Modify: `source/libraries/engine/Parun/Engine/Activate.hs` (`revealIfHidden` ~84, called ~117; `abilId` minted ~119)
- Create: `data/scenarios/activate/cr-702-49b-lasting-reveal-the-ninja-stays-revealed-while-ninjutsu-is-on-the-stack.json`
- Create: `data/scenarios/activate/cr-702-57b-lasting-reveal-steeling-stance-stays-revealed-for-the-rest-of-the-upkeep.json`

- [ ] **Step 1: Write the failing ninjutsu scenario.** Start from `data/scenarios/activate/cr-702-49a-whole-card-the-piker-goes-home-and-the-ninja-arrives-tapped-and-attac.json`, keeping its board, `Attack` and `Activate` (ability 0, `mana`). Checks:
  - before the activation: `Seers` on `$ninja-of-the-deep-hours` is the attacker alone;
  - after the activation, before `"Pass"`: both seats;
  - after resolution, with the stack empty: `Seers` on `"Ninja of the Deep Hours"` is both seats, because it is face up on the battlefield. The point of this check is that it holds for the battlefield object; the hand incarnation's window does not follow it.

  Expect the second check to fail.

- [ ] **Step 2: Verify Steeling Stance and write the failing forecast scenario.** Run `curl -s 'https://api.scryfall.com/cards/named?exact=Steeling%20Stance'`. Read `data/cards/steeling-stance.json` for its forecast ability's index and cost.
  - Board: the owner is active in `Upkeep`, with Steeling Stance in hand labelled `$stance` and enough ready Plains for the forecast cost; the opponent has a library.
  - Checks:
    - `Seers` on `$stance` is the owner alone;
    - `Activate` the forecast ability;
    - both seats while it is on the stack;
    - `"Pass"`, then the stack is empty, and it is still both seats (still Upkeep);
    - in `"step": "Draw"` of the same turn, the owner alone.

  Expect the post-resolution Upkeep check to fail.

- [ ] **Step 3: Stamp at activation.** After `abilId` is minted (after ~119, inside `Event.announcing`), if `revealIfHidden` revealed the card, stamp it:
  - `RevealWindow.DuringUpkeep (GameState.turnNumber gs)` when the ability is a forecast ability (CR 702.57b; read how Activate knows the ability's keyword, since `Keyword.Forecast` exists);
  - otherwise `RevealWindow.WhileOnStack abilId` (CR 602.2a, 702.49b).

  A rejected activation already restores the state from before, so the stamp rolls back with it. Confirm that by reading the code. Rewrite Activate.hs's elision (~71-79, citing #1408), including its forecast sentence.

- [ ] **Step 4: Green and mutations.** Run `-p lasting-reveal` and the full suite.
  - **m7**: drop the activation stamp. Expect the ninjutsu during-activation check to redden.
  - **m8**: always stamp `WhileOnStack`, never `DuringUpkeep`. Expect the forecast post-resolution Upkeep check to redden.
  - **m9**: in `revealedNow`, drop the phase test from `DuringUpkeep`. Expect the forecast Draw-step check to redden.

- [ ] **Step 5: Commit.** "Keep a card revealed to activate it from a hidden zone revealed, and forecast's for the upkeep".

### Task 5: Elisions, issues and the PR

- [ ] **Step 1: Merge `origin/main`.** Run `git fetch && git merge origin/main`, then rebuild and run the full suite. If the merge changes the behaviour of Tasks 1–4, stop and report.

- [ ] **Step 2: Elision upkeep.** Run `grep -rn '1408\|3045' . --include='*.hs'` and read every hit; every site the unit implements is rewritten.
  - `GameEvent.Revealed`'s haddock (~219-226): the lasting cases now live in `Object.revealed`, and its "no card in the pool asks" claim goes.
  - `Effect.Reveal`'s note (~222-225): CR 701.20a's "as long as necessary" stays the momentary event. Say so, and drop the #1408 citation if nothing else is unimplemented there.
  - Every comment the diff touches is re-read. A remaining elision must cite an open issue.

- [ ] **Step 3: File the CR 603.10a follow-up.** Before filing, search the open issues by title.
  - Title: "A revealed card leaving a hand doesn't count as one every player could see".
  - Labels: `rules-correctness`, `area:triggers` if it exists, otherwise `area:zones`.
  - Body: a dated plain-language summary (2026-10-11); the site (`Parun.Engine.Event.Match`'s CR 603.10a "an object that all players can see" read, decided from the zone alone); that it should read the departed incarnation's reveal window; and the card that would exercise it, a pool card that triggers on an object being put into a hand or library that #3064 used (find it with `gh issue view 3064`).
  - Name it in the PR's deferred line.

- [ ] **Step 4: Self-review.**
  - Re-check every CR citation the diff adds against `docs/rules.txt`.
  - Re-read every comment the diff touches.
  - Grep the construction and record-update sites of `Object` (`MkObject`, `{ Object.`) and record which were checked.
  - Grep `RevealWindow.` for every constructor's arms.
  - Confirm the codec has an arm for each constructor.

- [ ] **Step 5: Full suite, `hooky fix`, commit, push, open the PR as a DRAFT.** One line each in the body:
  - **What and why:** unit 2 of the visibility spec, a per-incarnation reveal window read by `sees`. `Closes #1408`. `Closes #3045`. Commits this plan.
  - **CR:** 103.6b, 400.7, 602.2a, 701.20a, 702.49b, 702.57b, 702.94b.
  - **Design calls:**
    - derived liveness, no sweep;
    - not `Expiry`;
    - the first turn read from `StepBegan`;
    - forecast's third window;
    - the generic trigger stamp (not miracle-specific);
    - Serum Powder dropped as a proof.
  - **Item-4 sites:** the Object construction and update sites read, and how Interchangeable treats the field.
  - **Verified:** suite count before → after; the MulliganSpec test and scenarios; m1–m9, each with its reddened assertion named.
  - **Effect identity:** the rules core cases on an effect's identity: no.
  - **Deferred:**
    - CR 603.10a's reader (the new issue);
    - #2568's inverse;
    - unproven paths (the activation cost reveal, if Task 2 found no card);
    - unblocked: what `gh api repos/tfausak/parun/issues/1408/dependencies/blocking` and the same for #3045 list.
  - End with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

  Leave it a draft; the controller marks it ready after the final review.
