# Line protocol (unit 2b of #5182) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A seat's decision crosses a one-JSON-object-per-line boundary:
out goes a `Request` (that seat's `PlayerView` plus a `Question`), back comes
the answer, decoded through `Scenario.Reply.shapeOf`.

**Architecture:** A new `play` library holds `Pawl.Play.Protocol`. It wraps
the seats' side of an `Answerer` so that each player prompt is rendered to a
line, handed to a transport (`Text -> m Text`), and the reply line decoded.
Chance and interpreter prompts (no seat) go to a fallback answerer. Objects
on the wire are references `"$<id>"` and players are labels `"<id>"`, so
`shapeOf`'s existing encode and decode serve the protocol unchanged, through
a protocol `Namer` and a resolver that reads ids back.

**Tech Stack:** Haskell; the `types`, `codec`, `scenario`, new `play`, and
`test` sublibraries.

**Spec:** `docs/superpowers/specs/2026-10-17-play-portal-client-design.md`,
unit 2 (2a, the view, landed in #5224).

## Global Constraints

- No new non-boot dependency.
- One type per module under `Pawl.Types.<TypeName>`; `Mk` constructors;
  one-line haddocks with their CR citation.
- An exhaustive list exists once: the protocol's answer shapes ARE
  `Reply.shapeOf`, never a second per-prompt table beside it.
- The rules core does not change.

## Rulings

- **Index answers for list offers.** `shapeOf` answers `ChooseAction`,
  `ChooseManaYield`, `ChooseCost`, `ChooseLearn` and
  `ChooseFromOutsideTheGame` with "no Answer for". Each offers a finite list
  of values that carry no wire name, so each is answered by position in that
  list (`Reply.indexed`). That fixes them in `shapeOf` itself, which keeps
  the one exhaustive list. `LookUpCard` stays unsupported: it is the
  interpreter's, not a seat's.
- **Offers for the prompts a Portal game reaches first.** `Question.offer`
  is filled for `ChooseAction`, `DeclareMulligan`, `Bottom`,
  `ChooseDiscard`, `DeclareAttackers`, `DeclareBlockers`, `ChooseTargets`,
  `ChooseManaSource`, `ChooseX` and `ChooseOptional`. Every other prompt
  sends `null`, so a client can only take typed input for it. Filed as an
  elision issue that names the next ones unit 3 will want
  (`ChooseManaYield`, `OrderTriggers`, `AssignCombatDamage`, `ChooseToPay`)
  and an activated ability's identity in an action offer.
- **A malformed answer is asked again.** The next `Request` for the same
  prompt carries `problem`, the decoder's message. The engine never sees a
  malformed answer.

## Review Focus

1. A hidden card's name or id in any line sent to the other seat (test
   `leak`).
2. Every prompt a played game reaches round-trips through the protocol's
   encode and decode (test `round trip`).
3. A malformed reply is re-asked with `problem`, and the game goes on (test
   `malformed`).
4. An out-of-range index fails to decode rather than wrapping (Task 1 test).
5. A seatless prompt never reaches the transport (test `leak` counts lines
   per seat and asserts no `Shuffle` line).

---

### Task 1: `Reply.indexed` and the list-offer arms

**Files:**
- Modify: `source/libraries/scenario/Pawl/Scenario/Reply.hs`
- Create: `source/libraries/scenario/Pawl/Scenario/ReplySpec.hs`, wired into
  `Pawl.Test`

**Interfaces (produced):**
`indexed :: (Eq a) => [a] -> Shape a`: decodes a natural `i` to the `i`th
element (0-based), failing with `"expected an index below N"`; encodes an
element as its first position, or `R.Null` when absent.

- [ ] **Step 1: Write `Pawl.Scenario.ReplySpec`**, `describe "Reply"`:
  - `ChooseAction` offering `[Pass, ActivateManaAbility 7]` decodes `1` to
    the second; encodes it back to `1`.
  - index `2` on that offer is `Failed`.
  - `ChooseLearn` decodes `null` to `Nothing`.
- [ ] **Step 2: Run `-p /Reply/`; expect a compile failure.**
- [ ] **Step 3: Add `indexed`; switch the five arms.**
- [ ] **Step 4: Run `-p /Reply/` and `-p /Scenario/`; expect both green.**
- [ ] **Step 5: Commit** `Answer a list offer by position`.

### Task 2: `Question` and `Request`

**Files:**
- Create: `source/libraries/types/Pawl/Types/Question.hs`,
  `source/libraries/types/Pawl/Types/Request.hs`
- Create: `source/libraries/codec/Pawl/Codec/Question.hs`,
  `source/libraries/codec/Pawl/Codec/Request.hs` and their specs, wired into
  `Pawl.Test`

**Interfaces (produced):**

```haskell
-- | A prompt as the seat answering it is shown it.
data Question = MkQuestion { seat :: PlayerId, kind :: Text, offer :: Reply }
-- | One line to a client: what its seat sees, and what it is asked.
data Request = MkRequest { view :: PlayerView, question :: Question, problem :: Maybe Text }
```

Codecs are `Fields.object`, every key required; `offer` uses
`Codec.Reply.codec`, `problem` uses `Common.maybe Common.text`.

- [ ] **Step 1: Codec specs** with exact JSON and `assertHasSchema`.
- [ ] **Step 2: Run; expect a compile failure.**
- [ ] **Step 3: Create the types and codecs.**
- [ ] **Step 4: Run `-p /Question/` and `-p /Request/`; expect green.**
- [ ] **Step 5: Commit** `Add the protocol's question and request`.

### Task 3: `Pawl.Play.Protocol`

**Files:**
- Modify: `pawl.cabal` (a `library play` stanza after `library interpreter`,
  depending on `codec`, `engine`, `json-codec`, `scenario`, `types`; `test`
  depends on it)
- Create: `source/libraries/play/Pawl/Play/Protocol.hs`
- Create: `source/libraries/test/Pawl/ProtocolSpec.hs`, wired into `Pawl.Test`

**Interfaces (produced, used by unit 3):**

```haskell
namer :: Reply.Namer                       -- oid -> Labelled "<id>", pid -> "<id>"
questionOf :: Prompt r -> Maybe Question   -- Nothing when Driver.deciderOf is
requestFor :: Asked r -> Maybe Request     -- viewFor the seat, problem Nothing
decodeAnswer :: Prompt r -> Reply -> Either Text r
encodeAnswer :: Prompt r -> r -> Reply
render :: Request -> Text                  -- one line
over :: Monad m => (Text -> m Text) -> Answerer m -> Answerer m
```

`over send fallback` answers a seated prompt by sending `render request` and
decoding the line it gets back (`Common.parse`, then `decodeAnswer`); a reply
that fails either is sent again with `problem`. A seatless prompt goes to
`fallback`.

Offers (`Reply.encode` under `namer` for every object and player):
- `ChooseAction`: an array, one object per action:
  `{"action": <constructor name>, "object": "$id"}` (no `object` for `Pass`
  and `RollPlanarDie`), plus `"name"` for `Play` (when `Just`), `Cast` and
  `Unlock`.
- `DeclareMulligan`: `{"taken": n, "bottom": n}`.
- `Bottom`, `ChooseDiscard`: `{"from": [objects], "count": n}`.
- `DeclareAttackers`: `[objects]`. `DeclareBlockers`:
  `{"blockers": [...], "attackers": [...]}`.
- `ChooseTargets`: `{"source": obj, "slots": [[slot, count, [recipients]]]}`.
- `ChooseManaSource`: `[objects]`. `ChooseX`: `{"source": obj, "min": n,
  "max": n}` in the constructor's argument order. `ChooseOptional`:
  `{"source": obj}`.
- Every other arm: `null`, with the elision comment.

- [ ] **Step 1: Write `Pawl.ProtocolSpec`**, `describe "Protocol"`:
  - `round trip`: play red vs green with `Driver.match`, an answerer that
    takes `S.castAnswer`'s answer for each seated prompt and asserts
    `Replay.encode prompt (decodeAnswer prompt (encodeAnswer prompt a)) ==
    Replay.encode prompt a`; count the checked prompts, expect > 0.
  - `leak`: `Driver.drive` from a started game to turn 5 under
    `over transport defaultAnswerer`, where the transport is a line-only
    client (parses the request; answers `Concede` "Continues",
    `ChooseAction` the index of `Pass` in the offer, `DeclareMulligan`
    "Keep", `ChooseDiscard` the first `count` of `from`; anything else fails
    the test). It logs `(Asked state, line)`. For each line to bob, no name
    held only in alice's hand or library (minus every name bob can see) is
    an infix, and no such id appears as `"$id"`. Lines reach both seats; no
    line is `Shuffle`.
  - `malformed`: a transport that answers `"nonsense"` once then behaves as
    the line-only client; the second line carries a `problem`.
- [ ] **Step 2: Run; expect a compile failure.**
- [ ] **Step 3: Add the library and implement.** File the offers elision
  issue first and cite it.
- [ ] **Step 4: Run `-p /Protocol/` and the full suite; expect green.**
- [ ] **Step 5: Mutate**, recording the reddened assertion: offers carry
  alice's hand; `questionOf` seats chance prompts; `over` drops `problem`.
- [ ] **Step 6: Commit** `Carry each seat's decisions over a line protocol`.

### Task 4: Self-review and PR

- [ ] Commit this plan; merge `origin/main` once; `hooky fix`.
- [ ] Self-review: CR citations, touched comments, the five `shapeOf` arms'
  callers (`Scenario.answerGeneric` path), and `withinOffer` for the same
  prompts.
- [ ] PR: related to #5182 (unit 2b); rulings; mutations; identity casing
  no; deferred offers issue.
