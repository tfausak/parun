# Per-player visibility, unit 1: the relation and the `Seers` view

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One function, `Pawl.Engine.Visibility.sees`, answers whether a player may see an object's face now (CR 400.2, 406.3, 708.5, 723.4), and a scenario `View` (`Seers`) asserts it.

**Architecture:** `Pawl.Types.Visibility` is a two-constructor monoid (`Visible` wins). `sees` is pure and derived: a base term by zone and facing, folded over the player and every player they control. No new state. The scenario runner renders `Seers` as the seats `sees` answers `Visible` for.

**Tech Stack:** Haskell (GHC via the repo's nix flake), cabal, tasty, JSON scenarios under `data/scenarios/`.

**Spec:** `docs/superpowers/specs/2026-10-11-per-player-visibility-design.md`, section "Unit 1". Read it first.

## Global Constraints

- Work only in `/Volumes/nvme/Developer/pawl/.claude/worktrees/visibility-spec` (branch `visibility-spec`, which already holds the spec and this plan). Never `cd` to the primary checkout. Before the first build run `script/warm-worktree.sh seed /Volumes/nvme/Developer/pawl/.claude/worktrees/visibility-spec`, then confirm `ls cabal.project.local`.
- Merge `origin/main` ONCE, in Task 3 Step 1, never mid-plan.
- Prefix every `cabal` call with `script/with-build-lock.sh`; redirect output to a scratchpad file and read the file; never pipe into `head`. `$SCRATCH` below is the session scratchpad.
- Subtree run: `script/with-build-lock.sh cabal test --test-options '--timeout 120s --hide-successes -p visibility' > "$SCRATCH/x.log" 2>&1`. Scenario cases match on the file path, case-sensitively.
- Full suite: `script/with-build-lock.sh cabal test --test-options '--timeout 120s --hide-successes' > "$SCRATCH/suite.log" 2>&1`. Record the count before Task 1.
- Two new modules: `Pawl.Types.Visibility` (`source/libraries/types/`) and `Pawl.Engine.Visibility` (`source/libraries/engine/`). Read `docs/adding-a-module.md`; stage `pawl.cabal` and run `cabal-gild pawl.cabal` directly.
- The rules core never cases on an effect's identity. Nothing here reads an `Effect` constructor; `sees` reads `Object.zone`, `Object.facing`, `Object.owner`, the projected controller and `GameState.control`.
- One type per `Pawl.Types.<TypeName>` module, type and instances only. A constructor's haddock is one line plus its CR citation.
- Style: `case` over `maybe`, `let` over `where`, no backticks, no partial `head`, extensions only from `.hlint.yaml`.
- Every proving check gets a mutation: `script/with-build-lock.sh script/mutate.sh FILE @SCRIPT PATTERN`, the sed script in a scratchpad file. Name the assertion that reddened. Never edit a file while a mutation runs on it.
- Never stash. Stage, `hooky fix`, `git add` again.
- Commits: a subject line, at most two sentences of why, then the trailer lines `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01N6oeJknHeSC1oKJ3H5pihY`. A commit says "related to #1412"; never close, fix or resolve next to any issue number in a commit.
- CR text from `docs/rules.txt` by number. Checked 2026-10-11: 400.2, 401.2, 406.3, 701.20a, 701.20e, 701.31b, 708.5, 723.4.

## Divergences from the spec

- **Callers stay.** The spec moves `Exile.mayChoose` and the `Target`/`Cast` reads onto `sees` "where they ask a visibility question". Re-derived: all four ask CR 406.4's choosing question over exiled cards, where `sees`'s exile arm IS `Exile.mayLookAt`, so they agree by construction. For objects outside exile, `mayLookAt` answers yes, and moving those reads onto `sees` would hide an opponent's hand from target offering. That is #559's change (unit 6), not this one. They keep their reads; Task 3 records it in the PR.
- **Supplementary decks are elided.** Attraction, planar and scheme deck cards sit in the command zone face down (CR 701.31b, 729.5a), but no scenario board or test helper places one. Task 3 files the elision; the code site cites it.

## Review Focus

1. **A face-down creature controlled by a player who does not own it.** CR 708.5 says its controller sees it, not its owner. Test: Task 1, scenario A, the `$stolen` check.
2. **Control that is scheduled but not yet working.** Mindslaver resolves on turn 1, and alice controls bob only from his turn (CR 723.1). Until then she sees nothing of his. Test: Task 2, scenario D, the post-resolution turn-1 check.
3. **The controlled player's own hand.** CR 723.4 lets the controller see it too. Test: Task 2, scenario D, `$b-hand` on turn 2.
4. **A library under control.** It stays hidden from everyone; control widens a view, it does not open a library. Test: Task 2, scenario D, `$b-top` on turn 2.
5. **A public zone.** A graveyard card is seen by every seat. Test: Task 1, scenario A, `$dead`.

---

### Task 1: The relation and the `Seers` view

**Files:**
- Create: `source/libraries/types/Pawl/Types/Visibility.hs`
- Create: `source/libraries/engine/Pawl/Engine/Visibility.hs`
- Modify: `source/libraries/types/Pawl/Types/View.hs` (new constructor after `OwnershipChanges`)
- Modify: `source/libraries/scenario/Pawl/Scenario.hs` (`renderView`, new arm after `View.OwnershipChanges`)
- Modify: `data/scenarios/README.md` (the views paragraph)
- Modify: `pawl.cabal` (via `cabal-gild`)
- Create: `data/scenarios/visibility/cr-400-2-708-5-a-face-down-creature-is-seen-by-its-controller-alone.json` (A)
- Create: `data/scenarios/visibility/cr-708-5-a-face-down-spell-is-seen-by-its-caster-alone.json` (B)
- Create: `data/scenarios/visibility/cr-406-3-a-foretold-card-is-seen-by-its-owner-alone.json` (C)

**Interfaces:**
- Produces: `Pawl.Types.Visibility.Visibility` (`Visible | Obscured`, `Semigroup`/`Monoid`); `Pawl.Engine.Visibility.sees :: PlayerId -> ObjectId -> GameState -> Visibility`; `Pawl.Engine.Visibility.controlledBy :: PlayerId -> GameState -> [PlayerId]`; `View.Seers`.

- [ ] **Step 1: Baseline.** Seed the worktree (Global Constraints), run the full suite, and record the count.

- [ ] **Step 2: Write scenario A (it will fail to load: `Seers` is unknown).**

```json
{
  "description": "CR 400.2 / 708.5 a face-down creature is seen by its controller alone",
  "note": "Hand: its owner. Library: nobody. Graveyard: everyone. A face-down creature: its controller, not its owner, until Break Open turns it face up.",
  "board": {
    "seats": [
      { "name": "alice",
        "battlefield": [ { "card": "Mountain", "label": "m1", "ready": true }, { "card": "Mountain", "label": "m2", "ready": true } ],
        "hand": [ { "card": "Break Open", "label": "break" } ],
        "library": [ { "card": "Goblin Piker" } ] },
      { "name": "bob",
        "battlefield": [
          { "card": "Ainok Tracker", "label": "victim", "faceDown": { "type": "Manifested" } },
          { "card": "Goblin Piker", "label": "stolen", "controller": "alice", "faceDown": { "type": "Manifested" } } ],
        "hand": [ { "card": "Hill Giant", "label": "b-hand" } ],
        "graveyard": [ { "card": "Hill Giant", "label": "dead" } ],
        "library": [ { "card": "Goblin Piker", "label": "b-top" } ] }
    ],
    "active": "alice",
    "step": "PrecombatMain"
  },
  "timeline": [
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "check": { "View": { "of": "Seers", "object": "$victim", "is": ["bob"] } } },
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "check": { "View": { "of": "Seers", "object": "$stolen", "is": ["alice"] } } },
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "check": { "View": { "of": "Seers", "object": "$b-hand", "is": ["bob"] } } },
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "check": { "View": { "of": "Seers", "object": "$b-top", "is": [] } } },
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "check": { "View": { "of": "Seers", "object": "$dead", "is": ["alice", "bob"] } } },
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "check": { "View": { "of": "Seers", "object": "$break", "is": ["alice"] } } },
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "do": { "Cast": { "object": "$break", "targets": ["$victim"], "mana": ["$m1", "$m2"] } } },
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "do": "Pass" },
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "check": { "View": { "of": "Stack", "is": [] } } },
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "check": { "View": { "of": "Seers", "object": "$victim", "is": ["alice", "bob"] } } }
  ]
}
```

The `$stolen` placement sits in bob's seat (he owns it) with `"controller": "alice"`. If the runner rejects a controller on a face-down placement, say so and drop that one entry; do not change the expectation of the others. Then run `script/format-json.sh` on the file, if hooky does not.

- [ ] **Step 3: Write scenario C** (foretell, adapted from `data/scenarios/special-action/cr-702-143a-the-foretold-card-is-castable-only-by-its-owner-only-later-and-only-f.json`):

```json
{
  "description": "CR 406.3 a foretold card is seen by its owner alone",
  "note": "Augury Raven foretold is exiled face down; CR 702.143 lets its owner look, nobody else.",
  "board": {
    "seats": [
      { "name": "alice",
        "battlefield": [ { "card": "Island", "label": "island", "ready": true }, { "card": "Island", "label": "island-2", "ready": true } ],
        "hand": [ { "card": "Augury Raven", "label": "raven" } ],
        "library": [ { "card": "Island" } ] },
      { "name": "bob", "library": [ { "card": "Island" } ] }
    ],
    "active": "alice",
    "step": "PrecombatMain"
  },
  "timeline": [
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "check": { "View": { "of": "Seers", "object": "$raven", "is": ["alice"] } } },
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "do": { "Take": { "action": "Foretell $raven", "mana": ["$island", "$island-2", null] } } },
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "check": { "View": { "of": "Zone", "player": "alice", "zone": "Exile", "is": ["Augury Raven"] } } },
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "check": { "View": { "of": "Seers", "object": "Augury Raven", "is": ["alice"] } } }
  ]
}
```

- [ ] **Step 4: Write scenario B, probing the face-down cast's spelling first.** Board: alice with three ready Mountains `m1`–`m3`, Ainok Tracker in hand labelled `tracker`, and an Island in her library; bob with a Goblin Piker in his library; `active` alice, `PrecombatMain`. The first timeline entry is a probe, `{ "View": { "of": "Offered", "player": "alice", "is": [] } }`. Run it, then read the failure's actual list for the action that casts the Tracker face down (CR 702.37c). Replace the probe with:

```json
{ "turn": 1, "step": "PrecombatMain", "player": "alice", "do": { "Take": { "action": "<the face-down cast, as the probe printed it>", "mana": ["$m1", "$m2", "$m3"] } } },
{ "turn": 1, "step": "PrecombatMain", "player": "alice", "check": { "View": { "of": "Seers", "object": "spell of $tracker", "is": ["alice"] } } },
{ "turn": 1, "step": "PrecombatMain", "player": "alice", "do": "Pass" },
{ "turn": 1, "step": "PrecombatMain", "player": "alice", "check": { "View": { "of": "Stack", "is": [] } } }
```

If `spell of $tracker` does not resolve to the face-down spell, take the reference the `Stack` view prints for it. Description "CR 708.5 a face-down spell is seen by its caster alone".

- [ ] **Step 5: Run to see it fail.** `-p visibility`. Expected: all three fail on decoding `"of": "Seers"`.

- [ ] **Step 6: The type.** `source/libraries/types/Pawl/Types/Visibility.hs`:

```haskell
module Pawl.Types.Visibility where

-- | Whether a player may see an object's face now (CR 400.2).
data Visibility
  = -- | CR 400.2: the player may see it.
    Visible
  | -- | CR 400.2: the player may not.
    Obscured
  deriving (Bounded, Enum, Eq, Ord, Show)

-- | Visible wins: a player sees an object when any reason lets them.
instance Semigroup Visibility where
  left <> right = case left of
    Visible -> Visible
    Obscured -> right

instance Monoid Visibility where
  mempty = Obscured
```

- [ ] **Step 7: The relation.** `source/libraries/engine/Pawl/Engine/Visibility.hs`. Match the import style of `Pawl.Engine.Exile` (qualified, aliased to the last component; `Pawl.Engine.Projection.View` as `View`). Fix the import list to whatever `-Werror` asks for.

```haskell
-- | What one player may see of one object (CR 400.2). The one place that asks;
-- each later source of visibility joins as a term of `sees`.
module Pawl.Engine.Visibility where

import qualified Data.Map as Map
import qualified Data.Set as Set
import qualified Pawl.Engine.Decide as Decide
import qualified Pawl.Engine.Exile as Exile
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Engine.Projection.View as View
import qualified Pawl.Types.Decider as Decider
import qualified Pawl.Types.Facing as Facing
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Object as Object
import Pawl.Types.ObjectId (ObjectId)
import Pawl.Types.PlayerId (PlayerId)
import qualified Pawl.Types.Visibility as Visibility
import qualified Pawl.Types.Zone as Zone

-- | Whether a player may see an object's face now. CR 723.4: for an object in
-- the game, a player also sees what each player they control sees; a card
-- outside the game is seen as its own seats see it, never through control.
sees :: PlayerId -> ObjectId -> GameState.GameState -> Visibility.Visibility
sees pid oid gs =
  if Set.member oid (GameState.outsideCopies gs)
    then base pid oid gs
    else foldMap (\seat -> base seat oid gs) (pid : controlledBy pid gs)

-- | CR 723.5: the players whose decisions this player makes, by the reading
-- Pawl.Engine.Decide.deciderFor makes, so a scheduled control that is not yet
-- working (CR 723.1) lends no sight.
controlledBy :: PlayerId -> GameState.GameState -> [PlayerId]
controlledBy pid gs =
  [ seat
  | seat <- Map.keys (GameState.control gs),
    seat /= pid,
    Decider.unwrap (Decide.deciderFor seat gs) == pid
  ]

-- One player's own sight, before CR 723.4.
--
-- Not implemented: a card in an Attraction, planar or scheme deck is face down
-- (CR 701.31b, 729.5a) but answers here as its facing does (#N).
base :: PlayerId -> ObjectId -> GameState.GameState -> Visibility.Visibility
base pid oid gs = case Game.lookupObject oid gs of
  Nothing -> Visibility.Obscured
  Just obj -> case Object.zone obj of
    Zone.Library -> Visibility.Obscured -- CR 401.2
    Zone.Hand -> visibleIf (Object.owner obj == pid) -- CR 400.2
    Zone.Exile -> visibleIf (Exile.mayLookAt pid oid gs) -- CR 406.3
    zone -> case Object.facing obj of
      Facing.FaceUp -> Visibility.Visible
      Facing.FaceDown _ ->
        if zone == Zone.Battlefield || zone == Zone.Stack
          then visibleIf (View.controllerOf oid gs == Just pid) -- CR 708.5
          else Visibility.Obscured -- CR 708.5

visibleIf :: Bool -> Visibility.Visibility
visibleIf seen = if seen then Visibility.Visible else Visibility.Obscured
```

`#N` is the elision issue Task 3 files; write `#N` literally now, and Task 3 replaces it. Confirm `Exile.mayLookAt` already answers yes for a face-up exiled card (it does: `not (Object.exiledFaceDown obj) || ...`). Confirm `Pawl.Engine.Visibility` creates no import cycle: nothing that `Exile`, `Decide` or `Projection.View` imports may import it.

- [ ] **Step 8: The view.** In `View.hs`, after `OwnershipChanges`:

```haskell
  | -- | CR 400.2 / 723.4: the seats that may see an object's face, in turn order.
    Seers
```

`Codec.ViewIs` reads views through `Arm.keyedEnum`, so the spelling is derived. In `Scenario.renderView`, after the `View.OwnershipChanges` arm (compile-forced), with `Pawl.Engine.Visibility` and `Pawl.Types.Visibility` imported qualified:

```haskell
        View.Seers -> do
          oid <- needObject
          let seers = [pid | pid <- GameState.turnOrder gs, Engine.Visibility.sees pid oid gs == Visibility.Visible]
          labels <- mapM labelOf seers
          pure (ReplyType.Array (fmap (ReplyType.Text . Label.unwrap) labels))
```

Pick aliases that don't clash with the module's existing `View` alias (`Pawl.Types.View`); for example, import the engine module `as Visibility` and the type module `as Visibility.Type`, matching how `Scenario.hs` already aliases `Mana.Type`.

In `data/scenarios/README.md`'s view list, after the `OwnershipChanges` clause, add: "`Seers` (the seats that may see an `object`'s face, in turn order: CR 400.2's hidden zones, CR 406.3's face-down exile, CR 708.5's face-down spells and permanents, and CR 723.4's control of a player)".

- [ ] **Step 9: Build and run.** `cabal-gild pawl.cabal`, then `-p visibility`. Expected: A, B and C pass. If B's face-down spell reports `[]`, check that `View.controllerOf` answers the caster for a stack object; if it does not, stop and report.

- [ ] **Step 10: Mutations.** One sed script per mutation in `$SCRATCH`, each run with `script/with-build-lock.sh script/mutate.sh source/libraries/engine/Pawl/Engine/Visibility.hs @$SCRATCH/mN.sed visibility`. Record the assertion that reddens:
  - m1 `s/View.controllerOf oid gs == Just pid/View.controllerOf oid gs \/= Just pid/`. Expected red: A's first `$victim` check (got `["alice"]`).
  - m2 `s/Object.owner obj == pid/Object.owner obj \/= pid/`. Expected red: A's `$b-hand` check.
  - m3 `s/visibleIf (Exile.mayLookAt pid oid gs)/Visibility.Visible/`. Expected red: C's last check (got `["alice","bob"]`).
  - m4 `s/Zone.Library -> Visibility.Obscured/Zone.Library -> Visibility.Visible/`. Expected red: A's `$b-top` check.

If m1 also reddens `$stolen` first, that is the expected order. If a mutation reddens nothing, report it; do not weaken it.

- [ ] **Step 11: Full suite, stage, `hooky fix`, re-stage, commit.** "Add a per-player visibility relation and a Seers scenario view".

### Task 2: CR 723.4, proven with Mindslaver

**Files:**
- Create: `data/scenarios/visibility/cr-723-4-the-controller-of-a-player-sees-what-that-player-sees.json` (D)

**Interfaces:**
- Consumes: `View.Seers`, `Pawl.Engine.Visibility.sees`/`controlledBy` from Task 1.

- [ ] **Step 1: Verify Mindslaver.** Run `curl -s 'https://api.scryfall.com/cards/named?exact=Mindslaver'` and confirm: `{4}, {T}, Sacrifice Mindslaver: You control target player during that player's next turn.` Read `data/cards/mindslaver.json` (one activated ability, index 0).

- [ ] **Step 2: Write scenario D.**

```json
{
  "description": "CR 723.4 the controller of a player sees what that player sees",
  "note": "Before bob's turn alice sees none of bob's hidden cards; while she controls him she sees his face-down creature and his hand, and still not his library.",
  "board": {
    "seats": [
      { "name": "alice",
        "battlefield": [
          { "card": "Mindslaver", "label": "slaver", "ready": true },
          { "card": "Mountain", "label": "m1", "ready": true }, { "card": "Mountain", "label": "m2", "ready": true },
          { "card": "Mountain", "label": "m3", "ready": true }, { "card": "Mountain", "label": "m4", "ready": true } ],
        "library": [ { "card": "Goblin Piker" } ] },
      { "name": "bob",
        "battlefield": [ { "card": "Goblin Piker", "label": "hidden", "faceDown": { "type": "Manifested" } } ],
        "hand": [ { "card": "Hill Giant", "label": "b-hand" } ],
        "library": [ { "card": "Goblin Piker" }, { "card": "Goblin Piker", "label": "b-top" } ] }
    ],
    "active": "alice",
    "step": "PrecombatMain"
  },
  "timeline": [
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "check": { "View": { "of": "Seers", "object": "$hidden", "is": ["bob"] } } },
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "do": { "Activate": { "object": "$slaver", "ability": 0, "targets": ["$bob"], "mana": ["$m1", "$m2", "$m3", "$m4"] } } },
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "do": "Pass" },
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "check": { "View": { "of": "Stack", "is": [] } } },
    { "turn": 1, "step": "PrecombatMain", "player": "alice", "check": { "View": { "of": "Seers", "object": "$hidden", "is": ["bob"] } } },
    { "turn": 2, "step": "Upkeep", "player": "alice", "check": { "View": { "of": "Seers", "object": "$hidden", "is": ["alice", "bob"] } } },
    { "turn": 2, "step": "Upkeep", "player": "alice", "check": { "View": { "of": "Seers", "object": "$b-hand", "is": ["alice", "bob"] } } },
    { "turn": 2, "step": "Upkeep", "player": "alice", "check": { "View": { "of": "Seers", "object": "$b-top", "is": [] } } }
  ]
}
```

A library lists its top card first, so `$b-top` is the card under the top. The checks sit in bob's Upkeep, before his draw, so it stays in the library either way. Turn-2 entries are keyed `alice` because a check runs when its player is next offered priority, and under Mindslaver bob's priority is decided by alice (CR 723.5). If the runner never fires them under `alice`, read `Scenario.answerPrompt`'s keying (it routes on `Scenario.Prompt.deciderOf`) and use the key it actually reads; do not change the expectations. If `"mana"` is not a field of `Activate`, read `Pawl.Codec.Reply`'s `Activate` arm and pay the way it accepts.

- [ ] **Step 3: Run.** `-p cr-723-4-the-controller`. Expected: pass.

- [ ] **Step 4: Mutations** on `Pawl/Engine/Visibility.hs`, run `-p visibility`:
  - m5 `s/(pid : controlledBy pid gs)/[pid]/`. Expected red: D's turn-2 `$hidden` check (got `["bob"]`). `controlledBy` stays a top-level binding, so it is still referenced and `-Werror` holds.
  - m6 on `source/libraries/types/Pawl/Types/Visibility.hs`, `s/Visible -> Visible/Visible -> right/`. Expected red: D's turn-2 `$hidden` check.
  - m7 `s/Decider.unwrap (Decide.deciderFor seat gs) == pid/True/`. Expected red: D's turn-1 post-resolution `$hidden` check (got `["alice","bob"]`). If that check is green under m7, `GameState.control` holds no row until turn 2, and the check is guarded by the row's absence rather than by `deciderFor`; say so in the PR.

- [ ] **Step 5: Full suite, stage, `hooky fix`, re-stage, commit.** "Prove CR 723.4's shared sight with Mindslaver".

### Task 3: Elisions, issues and the PR

**Files:**
- Modify: every site `grep -rn '1412' . --include='*.hs'` lists, where unit 1 makes a note untrue
- Modify: `source/libraries/engine/Pawl/Engine/Visibility.hs` (`#N`)
- Modify: `source/libraries/types/Pawl/Types/MulliganOffer.hs` (its stale "never the GameState" sentence)

- [ ] **Step 1: Merge `origin/main`.** `git fetch && git merge origin/main`, resolve, then rebuild and run the full suite.

- [ ] **Step 2: File the issues.** Each body opens with a dated plain-language summary (2026-10-11); no CR number in a title; no `@`.
  1. Unit 1's issue. Title: "Nothing says which players may see a given card". Labels: `gap`, `area:zones`, `area:prompts`. Body: the spec's unit-1 section in brief, the proving scenarios, and the spec path. Call it `#U`.
  2. The deck elision. Title: "A card in an Attraction, planar or scheme deck reads as visible to everyone". Labels: `elision`, `area:zones`, `expires:card-driven`. Body: the code site, CR 701.31b / 729.5a, and that it waits on a scenario board that can place a supplementary deck. Name the card that would exercise it: an Attraction producer in the pool (find one under `data/scenarios/attraction/`, e.g. Deadbeat Attendant). Call it `#D`, and replace `#N` in `Visibility.hs` with it.

- [ ] **Step 3: Re-point the dependents.** For each of 1408, 3045, 3237, 3035, 4391, 4452, 3497, 559:

```
gh api -X POST repos/tfausak/pawl/issues/<N>/dependencies/blocked_by -F issue_id="$(gh api repos/tfausak/pawl/issues/<U> --jq .id)"
gh api -X DELETE repos/tfausak/pawl/issues/<N>/dependencies/blocked_by/"$(gh api repos/tfausak/pawl/issues/1412 --jq .id)"
```

Run the DELETE only where `gh api repos/tfausak/pawl/issues/<N>/dependencies/blocked_by` lists #1412. Then add a dated comment to each of #1408, #3045, #3237, #3035, #4391 and #4452 copying its unit's section from the spec (units 2–5). Add a dated comment to #1412 narrowing it to unit 7 (redaction: an allowlist `PlayerView`, a per-player log, handles reissued per incarnation and per shuffle, redacted prompts, `Asked` carrying the view), citing the spec path. Its #10 link stays.

- [ ] **Step 4: Elision upkeep.** `grep -rn '1412' . --include='*.hs'` and read every hit. Rewrite each note unit 1 makes untrue. Expected:
  - `Pawl.Types.Object`'s `facing` note and `Pawl.Engine.Game.faceOf`'s CR 708.5 note: the relation exists (`Pawl.Engine.Visibility.sees`); what stays unimplemented is that an answerer is still handed the printing (#1412).
  - `Pawl.Types.LookAt`'s "there is no per-player view of the game state at all": say instead that nothing records who looks (#4391's unit).
  - Every other hit is about answerers or private looks, and stays.
  Fix `MulliganOffer.hs`'s "An answerer sees only this payload, never the GameState", which has been false since `Asked` carried the state. Grep `PlayerView` too; `docs/design.md` stays as it is.

- [ ] **Step 5: Self-review.** Re-check every CR citation the diff adds against `docs/rules.txt`. Re-read every comment the diff touches. Re-derive the four callers of `Exile.mayLookAt`/`mayChoose` (`Target.hs` ×2, `Cast.hs` ×2) and record why each keeps its read (see Divergences). Grep `View.OwnershipChanges` to confirm `renderView` is the only arm site. Grep every `{ GameState.` construction to confirm no field was added (none should be).

- [ ] **Step 6: Full suite, `hooky fix`, commit, push, open the PR.** Body, one line each:
  - What changed and why: unit 1 of the visibility spec, a pure `sees` relation plus a `Seers` scenario view. `Closes #U`. Commits the spec and this plan.
  - CR: 400.2, 401.2, 406.3, 708.5, 723.4, 723.5.
  - Design calls: `Visibility` as a two-constructor monoid, not `Bool`; derived, not stored; callers of `Exile.mayLookAt`/`mayChoose` kept (#559's change); supplementary decks elided (`#D`).
  - Verified: suite count before → after; scenarios A–D; mutations m1–m7, each with the assertion it reddened, named.
  - The rules core cases on an effect's identity: no.
  - Deferred: units 2–5 (#1408, #3237, #4391, #4452), which this unblocks; unit 7 is #1412. Outside-the-game objects in `sees` are unproven: no scenario places one.
  - End with the attribution line `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

  Mark it ready once the suite is green and the self-review fixes are pushed, then stop.
