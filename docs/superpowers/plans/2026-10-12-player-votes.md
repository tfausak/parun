# Player votes and Mob Verdict

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A vote can be for a player (CR 701.38b's "other variables"), with each player's tally readable by the card that holds the vote. Mob Verdict is the proving card: "Secret council — Each player secretly votes for another player, then those votes are revealed. For each vote an opponent received, Mob Verdict deals 2 damage to that player and each creature that player controls. For each vote you received, draw a card." It closes #3717.

**Architecture:**
- **New vote arm.** A third `VoteChoices` arm, `Players VotePlayers`, holds `{ another :: Bool, slot :: SlotName }`.
- **New prompt.** `ChooseVotePlayer`, with one candidate list per voter. When `another` is set, the voter is left out of their own list.
- **Tally storage.** A new `Binding` field holds the per-player tally `Map PlayerId Natural`, every candidate included even at zero. It is bound the way the `Words` arm binds its amounts.
- **Tally reader.** A new `Quantity` arm, `VotesReceived { slot, player :: PlayerRef }`, reads it and answers 0 for a player missing from the map.
- **Ballot.** `BallotChoice.ForPlayer`, rendered by the voted-for player's seat label.

**Tech Stack:** Haskell (GHC via the repo's nix flake), cabal, tasty, JSON scenarios under `data/scenarios/`.

**Spec:** none; this is a card-driven capability, and #3717's body is the design record. Read `gh issue view 3717 --comments`. The visibility spec's Unit 5 names Mob Verdict as following this issue.

## Global Constraints

- **Worktree.** Work only in `/Volumes/nvme/Developer/pawl/.claude/worktrees/3717-player-votes`, on branch `3717-player-votes`, cut from `origin/main` at c4ecea7a4. Never `cd` to the primary checkout or to any other worktree. Before the first build, run `script/warm-worktree.sh seed /Volumes/nvme/Developer/pawl/.claude/worktrees/3717-player-votes`, then confirm with `ls cabal.project.local`.
- **Merging.** Merge `origin/main` ONCE, in Task 3 Step 1. Never mid-plan.
- **cabal.** Prefix every `cabal` call with `script/with-build-lock.sh`. Redirect output to a scratchpad file and read the file; never pipe into `head`.
- **Test selection.** `-p` patterns contain NO spaces. Scenario tests are named by bare file name, and this plan's scenarios carry the stem `player-vote`.
- **Full suite:** `script/with-build-lock.sh cabal test --test-options '--timeout 120s --hide-successes' > "$SCRATCH/suite.log" 2>&1`. Record the count before Task 1.
- **Effect identity.** The rules core never cases on an effect's identity. The `Vote` arm resolving its own `Players` case is that arm's job.
- **CLAUDE.md item 4** applies to:
  - a new `VoteChoices` arm: codec, `Resolve/Slots` (`slotsOf` and `boundSlots`), `Interchangeable/Mentions`, `Projection/Rewrite` and `CardSpec`;
  - a new `Prompt` and `Response`: `Replay` encode, decode and `defaultAnswer`; `Scenario.Prompt` `deciderOf` and `kindOf`; `Scenario/Reply`; the `withinOffer` legality check in `Scenario.hs`; and `test/Pawl/VoteSpec.hs`'s answerer. Mirror `ChooseVoteWord` end to end.
  - a new `Binding` field: `Codec.Binding`; `Engine.Binding`'s `mergeBinding` and its sibling functions; and every `MkBinding` construction and `{ Binding.` update. `Object`-held bindings travel with the object, so read how `amount` survives `newIncarnation`.
  - a new `Quantity` arm: codec, `QuantitySlot`, `Star`, `Projection`, `Projection/Rewrite`, `Mentions`, `Engine/Quantity` evaluation, `CardSpec`, `EffectLintSpec` and `QuantitySpec`. Use `UniqueVowelsOnSticker`'s commit, `212cfd24a`, as the site map.
  - a new `BallotChoice` arm: its codec, the `Witnessed` rendering in `Scenario.hs`, and `Event/Trigger.hs` `ballotParticipants` and `rereadBallot`.
- **Types.** One type per `Pawl.Types.<TypeName>` module. A constructor's haddock is one line plus its CR citation. Every new codec gets a round-trip case.
- **Style.** `case` over `maybe`, `let` over `where`, no backticks, no partial `head`, and extensions only from `.hlint.yaml`.
- **Mutations.** Every proving check gets one: `script/with-build-lock.sh script/mutate.sh FILE @SCRIPT PATTERN`, with the sed script in a scratchpad file, keeping imports and bindings used (`-Werror`). Name the assertion that reddened. Never edit a file while a mutation runs on it.
- **Oracle text.** Verify it with `curl -s 'https://api.scryfall.com/cards/named?exact=Mob%20Verdict'`. Ruling: "Each player must vote for another player. They can't abstain."
- **Never stash.** Stage, run `hooky fix`, then `git add` again.
- **Commits.** A subject line, at most two sentences of why, and the trailers `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01N6oeJknHeSC1oKJ3H5pihY`. Write "related to #3717". Never put close, fix or resolve next to an issue number in a commit.
- **CR text.** Read it from `docs/rules.txt` by number: 701.38a, 701.38b, 701.38d, 120.3, 120.4.

## Decisions

- **Mob Verdict's damage is one event per opponent per recipient.** It deals `2 × votes` to that player and to each creature they control, as one `DealDamage` with two parts, the shape `soul-immolation.json` uses. The card reads "for each vote … deals 2 damage", and no ruling splits it into separate events. Record the reading in the PR, and say that per-vote events would differ only for a "whenever a source deals damage" counter.
- **Círdan the Shipwright is deferred.** It needs an "enters or attacks" trigger and a per-player "may put a permanent card" gated on a zero tally. File it in Task 3 with the capabilities it lacks.
- **The tally includes zeros.** Every candidate player is keyed, so `VotesReceived` never confuses "not a candidate" with "no votes". It answers 0 for both anyway.

## Review Focus

1. **"Another player":** a voter is never offered themself. Test: Task 1, a VoteSpec case.
2. **Extra votes (CR 701.38d)** count toward the tally. Test: Task 1, a VoteSpec case with Brago's Representative or the existing extra-vote helper.
3. **Each opponent's damage scales with that opponent's own tally,** not the total. Test: Task 2, a three-player scenario where the opponents receive different numbers of votes.
4. **The caster draws for their own votes received,** and a player who received none draws nothing. Test: Task 2's draw checks.
5. **A secret player vote hides each ballot until the reveal,** and the `Witnessed` rendering names players by seat label. Test: Task 2.

---

### Task 1: The player vote, its tally and `VotesReceived`

**Files:**
- Create: `source/libraries/types/Pawl/Types/VotePlayers.hs` and its codec and spec
- Modify:
  - `Types/VoteChoices.hs` and its codec and spec; rewrite the #3717 elision haddock at ~13-15
  - `Types/BallotChoice.hs` and its codec
  - `Types/Binding.hs`, `Codec/Binding.hs`, `Engine/Binding.hs`
  - `Types/Quantity.hs` and its codec
  - `Types/Prompt.hs`, `Types/Response.hs`, `Engine/Replay.hs`
  - `Scenario/Prompt.hs`, `Scenario/Reply.hs`, `Scenario.hs` (legality and the `Witnessed` ballot rendering)
  - `Resolve/Effect.hs` (the `Vote` arm's new `Players` case, ~6805)
  - `Engine/Quantity.hs` (the evaluation)
  - every item-4 site in Global Constraints
- Test: `source/libraries/test/Pawl/VoteSpec.hs`

**Interfaces:**
- Produces:
  - `VoteChoices.Players VotePlayers`, with `VotePlayers = MkVotePlayers { another :: Bool, slot :: SlotName }`
  - `Prompt.ChooseVotePlayer :: Decider -> PlayerId -> ObjectId -> NonEmpty PlayerId -> Prompt PlayerId`
  - `Response.ChoseVotePlayer PlayerId`
  - `BallotChoice.ForPlayer PlayerId`
  - the `Binding` tally field `Maybe (Map PlayerId Natural)`
  - `Quantity.VotesReceived { slot :: SlotName, player :: PlayerRef }`
  - Record the JSON spellings in the report; Task 2 writes Mob Verdict with them.

- [ ] **Step 1: Baseline.** Seed the worktree, run the full suite, and record the count.

- [ ] **Step 2: Write failing VoteSpec cases.** Read how `VoteSpec` builds a vote and answers prompts (its answerer at ~163-180). Add:
  - `"a player vote binds each candidate's tally, zeros included"`: a three-seat vote where alice and bob vote carol and carol votes alice. Expect the tally `{alice: 1, bob: 0, carol: 2}`, read through `VotesReceived` for each seat.
  - `"another player: a voter is never offered themself"`: assert each voter's offered list leaves out that voter.
  - `"an extra vote counts toward the tally (CR 701.38d)"`: reuse the existing extra-vote setup.

  Expect compile failures first.

- [ ] **Step 3: Implement the types, codecs and prompt plumbing.** Mirror `ChooseVoteWord` at every site. `Replay.defaultAnswer` takes the first offered player.

- [ ] **Step 4: Implement the resolver case.**
  - Candidates per voter: every player still in the game, minus the voter when `another` is set. If that leaves a voter with no candidates, the voter casts no ballot; read how the `Objects` arm handles an empty candidate list.
  - Each ballot goes through `cast` with `BallotChoice.ForPlayer`, so it is logged and, if secret, revealed exactly as the other arms are.
  - Tally the picks over every candidate, zeros included, and bind the map to the tally field on the holder the `Words` arm uses (`bindAmountSlot`'s holder chain).
  - `VotesReceived` evaluates through the evaluation context. Follow `UniqueVowelsOnSticker`'s `slotStickers` path: add the context field, fill it where `slotStickers` is filled, and resolve the `PlayerRef` with `playersOf`. It answers 0 for a missing player or slot.

- [ ] **Step 5: The ballot rendering.** In `Scenario.hs`'s `Witnessed` arm, `ForPlayer pid` renders the voted-for seat's label. In `ballotParticipants`, `ForPlayer pid` is a participant. In `rereadBallot`, `ForPlayer` passes through unchanged.

- [ ] **Step 6: Green and mutations.** Run `-p VoteSpec`, the codec specs, then the full suite. Mutations, naming the assertion each reddens:
  - **m1:** stop excluding the voter. Expect the "another player" case to redden.
  - **m2:** tally only non-zero players. If the zero-tally assertion still passes because `VotesReceived` answers 0 for a missing key, say so, and keep the assertion on the bound map itself.
  - **m3:** drop extra votes from the tally. Expect the CR 701.38d case to redden.

- [ ] **Step 7: Commit.** "Let a vote be for a player, with a per-player tally a card can read".

### Task 2: Mob Verdict

**Files:**
- Create: `data/cards/mob-verdict.json`
- Create: `data/scenarios/vote/cr-701-38b-player-vote-mob-verdict-damages-each-opponent-by-their-own-votes.json`. Put it in an existing scenarios directory if `vote/` doesn't exist; grep for where Council's Judgment's scenarios live.

- [ ] **Step 1: Write the card.** Verify the Oracle text first.
  - The vote: `"secret": true`, `Players { another: true, slot: "votes" }`, started by `Relative You`.
  - The damage: a `ForEach` over `EachOpponent` with slot `"player"`. Its body is one `DealDamage` with two parts, each with quantity `Times 2 (VotesReceived "votes" (InSlot "player"))`:
    - `Players (InSlot "player")`;
    - `EachMatching (Creature ∧ ControlledByBound "player")`.
    - Copy the shapes from `data/cards/covetous-elegy.json` (the `ForEach` over players) and `data/cards/soul-immolation.json` (the two-part `DealDamage`).
  - The draw: `Draw (Relative You) (VotesReceived "votes" (Relative You))`.
  - `oracleText` matches the Oracle text exactly. Re-run ingest's oracle check if `_scratch/AtomicCards.json` exists in the primary checkout's `_scratch/`; read it by absolute path, never `cd`.

- [ ] **Step 2: Write the failing scenario.**
  - **Board:** three seats. Alice has {2}{R}{R} and Mob Verdict. Bob has a Hill Giant (3/3) and carol a Goblin Piker (2/1). Every seat has a library.
  - **Votes:** alice votes bob, bob votes carol, carol votes bob. So bob has 2, carol has 1 and alice has 0. Answer each `ChooseVotePlayer` in the voter's key with the Answer spelling the README gives for a player.
  - **Checks after resolution:**
    - Bob's life is 16 (2 × 2).
    - The Hill Giant has 4 damage, so it died: check that it is in bob's graveyard.
    - Carol's life is 18, and the Goblin Piker died.
    - Alice drew 0 cards.
    - `Witnessed` for carol is `["carol voted bob", "alice voted bob", "bob voted carol", "carol voted bob"]`: her own ballot, then the reveal. Use the actual rendering and order from Task 1.
  - **A second scenario,** to prove the draw: change the votes so alice receives votes (bob votes alice, carol votes alice), and check that alice drew 2.
  - Run `-p player-vote` and expect failures until the card exists.

- [ ] **Step 3: Green and mutations.** Run `-p player-vote`, then the full suite.
  - **m4 (card):** the damage quantity uses the total votes instead of `InSlot "player"`'s. Expect carol's life check to redden.
  - **m5 (card):** draw by `VotesReceived` for an opponent. Expect the draw scenario's check to redden.
  - **m6 (card):** `"secret": false`. Expect carol's `Witnessed` check to redden.

- [ ] **Step 4: Commit.** "Add Mob Verdict, a secret vote for a player".

### Task 3: Issues and the PR

- [ ] **Step 1: Merge `origin/main`.** Rebuild and run the full suite. If the merge changes the behaviour of Tasks 1–2, stop and report.

- [ ] **Step 2: Elision upkeep.** `grep -rn '3717' . --include='*.hs' --include='*.json'` and rewrite every site this change implements.

- [ ] **Step 3: File Círdan the Shipwright.** Search titles first.
  - Labels: `gap`, `area:effects`, `expires:card-driven`.
  - Body:
    - a dated summary (2026-10-12);
    - its Oracle text;
    - the capabilities it lacks: an "enters or attacks" trigger (check whether one exists before claiming), a draw for each player by `VotesReceived` (now possible), and "each player who received no votes may put a permanent card from their hand onto the battlefield" (a per-player optional gated on a zero tally).

- [ ] **Step 4: Self-review.**
  - Re-check every CR citation against `docs/rules.txt`.
  - Re-read every touched comment.
  - Grep every new constructor's sibling sites and record each one.
  - Confirm every new codec has a round-trip case.

- [ ] **Step 5: Full suite, `hooky fix`, commit, push, open the PR as a DRAFT.** The body has one line for each of:
  - **What and why:** `Closes #3717`; this plan is committed with it.
  - **CR:** 701.38a/b/d.
  - **Design calls:**
    - one prompt per vote kind;
    - the tally includes zeros;
    - damage is one event of 2 × votes per recipient;
    - Círdan is deferred.
  - **Item-4 sites read.**
  - **Verified:** the suite count before and after, and m1–m6, each with the assertion it reddened, named.
  - **Effect identity:** the rules core cases on an effect's identity: no.
  - **Deferred:** Círdan (the new issue), and anything else found.
  - End with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

  Leave it a draft. The controller marks it ready after the final review.
