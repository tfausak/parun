# Per-player view (unit 2a of #5182) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `PlayerView.viewFor pid gs` is everything seat `pid` may see of a
game and nothing else, with a JSON codec. A client reads this instead of
`GameState`.

**Architecture:** The view is built as an allowlist: each field is read
deliberately from `GameState` and passed through `Engine.Visibility.sees`.
It is never a redacted copy of the state. The parts are:

- **Public zones** (battlefield, stack, graveyards, exile): every object is
  listed with its public status. Its characteristics appear only when the
  viewer may see it.
- **Hidden zones** (hand, library): sizes, plus only the members the viewer
  may see.
- **Witnessed entries:** this turn's log entries that pass
  `Visibility.witnessed`.

**Tech Stack:** Haskell; the `types`, `engine`, `codec` and `test`
sublibraries; `Pawl.Spec`.

**Spec:** `docs/superpowers/specs/2026-10-17-play-portal-client-design.md`,
unit 2. Unit 2 is split in two:

- **2a (this plan):** the view.
- **2b:** the line protocol (a prompt codec, the answer read through
  `Scenario.Reply.shapeOf`, and the framing).

## Global Constraints

- No new non-boot dependency.
- One type per module under `Pawl.Types.<TypeName>`. Constructors take a
  `Mk` prefix, and haddocks are one line with their CR citation.
- Every read of a permanent's card goes through the projection
  (`Projection.project`), never `Game.cardOf`.
- The rules core does not change. This unit only reads the state.

## Rulings carried in from the spec

- **No separate handle layer.** The visibility spec's unit 7 sketch asks for
  fresh handles per incarnation and per shuffle, but `ObjectId`s are already
  fresh on every zone change (`Event.placeObject`). A shuffle keeps its ids,
  but a library is never itemised beyond what the viewer may see, so a
  shuffled id never reaches an opponent. A test pins this down.
- **Per-player log.** The view carries the witnessed entries
  (`Visibility.witnessed`, so reveals, looks and votes) from this turn's log.
  Public changes, such as a spell cast or life lost, show up as differences
  between successive views. Accumulating entries across turns, since the
  seat last decided, belongs to the driver in unit 3, because
  `GameState.events` is cleared at turn handoff.
- **No Oracle text.** The view carries projected names, and the client looks
  the text up by name. That keeps a Clone showing its copied card's text.

## Review Focus

1. **A card in the opponent's hand or library.** Its name appears nowhere in
   the encoded view (Task 2 test `leak`).
2. **A face-up spell on the stack.** Both seats see its characteristics
   (Task 2 test `stack`).
3. **A look with an audience of one.** It reaches only that seat (Task 2
   test `looked`).
4. **The viewer's own library.** It is hidden from them too, and only its
   size shows (Task 2 test `own library`).
5. **A shuffled library.** No library `ObjectId` reaches the opponent (Task
   2 test `leak` asserts on ids as well as names).

---

### Task 1: The view types and their codecs

**Files:**
- Create: `source/libraries/types/Pawl/Types/ObjectView.hs`
- Create: `source/libraries/types/Pawl/Types/SeatView.hs`
- Create: `source/libraries/types/Pawl/Types/PlayerView.hs`
- Create: `source/libraries/codec/Pawl/Codec/ObjectView.hs` and its
  `ObjectViewSpec.hs`
- Create: `source/libraries/codec/Pawl/Codec/SeatView.hs` and its
  `SeatViewSpec.hs`
- Create: `source/libraries/codec/Pawl/Codec/PlayerView.hs` and its
  `PlayerViewSpec.hs`
- Modify: `source/libraries/test/Pawl/Test.hs` (wire the three codec specs)
- Modify: `pawl.cabal` (stage it, then run `cabal-gild`)

**Interfaces (produced):**

```haskell
-- | CR 400.2 / 708.2: an object as one seat sees it: its public status
-- always, its characteristics only when that seat may see them.
data ObjectView = MkObjectView
  { object :: ObjectId, owner :: PlayerId, controller :: Maybe PlayerId,
    tapped :: TapState, damage :: Natural,
    counters :: Map (CounterKind Keyword) Natural,
    attachedTo :: Maybe Recipient,
    characteristics :: Maybe ProjectedCharacteristics }
-- | CR 400.2: one player's zones and totals as one seat sees them.
data SeatView = MkSeatView
  { player :: PlayerId, life :: Integer,
    counters :: Map PlayerCounterKind Natural,
    handSize :: Natural, hand :: [ObjectView],
    librarySize :: Natural, library :: [ObjectView],
    graveyard :: [ObjectView], exile :: [ObjectView], manaPool :: Mana }
-- | Everything one seat may see of a game (CR 400.2, 723.4).
data PlayerView = MkPlayerView
  { viewer :: PlayerId, turn :: Natural, phase :: Phase,
    active :: PlayerId, priority :: Maybe PlayerId,
    seats :: [SeatView], battlefield :: [ObjectView], stack :: [ObjectView],
    witnessed :: [LoggedEvent], result :: Maybe Result }
```

All three derive `Eq, Show`. Each codec is a `Fields.object` with every key
`required`, following `Pawl.Codec.Looked`'s shape:

- `counters` uses `Common.multiset`, as `Pawl.Codec.Object` and
  `Pawl.Codec.Player` do;
- `characteristics` uses `Common.maybe ProjectedCharacteristics.codec`;
- `attachedTo` uses `Common.maybe Recipient.codec`.

- [ ] **Step 1: Write the three codec specs.** Each one gets an
  `assertCodec` round trip, with one representative value and its exact
  JSON, plus `assertHasSchema`. The `ObjectView` spec covers both a seen
  object (reuse `ProjectedCharacteristicsSpec.testCharacteristics`) and a
  hidden one (`characteristics = Nothing`, encoded as `null`).
- [ ] **Step 2: Build and watch it fail** (the modules don't exist).
- [ ] **Step 3: Create the types and codecs.**
- [ ] **Step 4: Run `-p ObjectView`, `-p SeatView` and `-p PlayerView`;
  expect them to pass.**
- [ ] **Step 5: Commit:** `Add the per-player view types and their codecs`.

### Task 2: `Pawl.Engine.PlayerView.viewFor`

**Files:**
- Create: `source/libraries/engine/Pawl/Engine/PlayerView.hs`
- Create: `source/libraries/test/Pawl/PlayerViewSpec.hs`, wired into
  `Pawl.Test`

**Interfaces:**
- Produces `viewFor :: PlayerId -> GameState -> PlayerView`, used by units
  2b and 3.
  - `objectView pid gs oid` fills the status from the object, and fills
    `characteristics` with `Just (Projection.project oid gs)` exactly when
    `Visibility.sees pid oid gs == Visible`. `controller` is
    `Projection.controllerOf`.
  - A public zone lists all of its members. A hidden zone lists only the
    members the viewer sees, with `handSize` and `librarySize` counting all
    of them.
  - `witnessed` keeps `GameState.events` entries whose
    `Visibility.witnessed pid` is `Visible`.
  - `seats` follows `GameState.turnOrder`.

- [ ] **Step 1: Write `Pawl.PlayerViewSpec`** under `describe "PlayerView"`.
  Use a game after setup, with red for alice and green for bob:
  `snd (Engine.runGamePure S.castAnswer (Setup.gameWith GameSettings.plain [alice, bob]) (Setup.newGame (Resolve.performHandAction Engine.playSubgame) matchup))`,
  where `matchup` pairs alice with `Cards.redDeck` and bob with
  `Cards.greenDeck`. Tests:
  - `leak`: "an opponent's hidden cards reach no part of the encoded view".
    Render `Common.render (PlayerView.codec.encode (viewFor S.bob gs))` to
    text. Assertions:
    - `"no name"`: no card name in alice's hand or library that isn't also
      in bob's hand or library is an infix of the text;
    - `"no id"`: none of alice's hand or library `ObjectId`s appears as an
      `"object":N` key-value in the text;
    - `"own hand"`: every name in bob's own hand is an infix of the text.
  - `sizes`: "an opponent's hand and library show only their sizes". In
    bob's view, alice's seat has `handSize == 7` and `hand == []`, and
    `librarySize` equals her library's length.
  - `own library`: "a seat's own library is hidden from it too". In alice's
    view, her seat has `library == []` and a `librarySize` above zero.
  - `stack`: "a spell on the stack is seen by both seats". Use
    `S.cast S.alice` on a red spell from her hand, under `S.castAnswer`.
    The stack top has `characteristics /= Nothing` in both alice's and
    bob's views.
  - `looked`: "a look reaches only its audience". Append a
    `GameEvent.Looked` entry with audience `{alice}` to `GameState.events`.
    Alice's `witnessed` has length 1; bob's has length 0.
- [ ] **Step 2: Build and watch it fail.**
- [ ] **Step 3: Implement `Pawl.Engine.PlayerView`.**
- [ ] **Step 4: Run `-p PlayerView` and the full suite; expect both to
  pass.**
- [ ] **Step 5: Mutate** with `script/mutate.sh` and an `@FILE` script, then
  record each assertion that reddens:
  - characteristics always `Just`: expect `"no name"`;
  - the hidden-zone filter dropped: expect `"sizes"`, or `"no id"`, or say
    which;
  - the witnessed filter dropped: expect `looked`'s bob assertion.
- [ ] **Step 6: Commit:** `Build each seat's view of a game`.

### Task 3: Self-review and PR

- [ ] Commit this plan. Merge `origin/main` once, then run `hooky fix`.
- [ ] Self-review:
  - re-check every CR citation against `docs/rules.txt`;
  - grep `ProjectedCharacteristics` builders. This unit adds none, so CLAUDE.md
    item 4's "fill every builder" does not apply. Say so.
- [ ] Open the PR with a body that has, a line each:
  - what changed, "related to #5182 (unit 2a)";
  - the CR citations: 400.2, 708.2, 723.4 and 701.20e (via `witnessed`);
  - the rulings above;
  - verification: the suite count before → after, and each mutation with
    its named assertion;
  - identity casing: no;
  - deferred: 2b, plus a face-down permanent's view test, deferred because
    Portal has no face-down cards.
