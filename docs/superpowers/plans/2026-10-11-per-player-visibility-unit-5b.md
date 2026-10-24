# Per-player visibility, unit 5b: secret votes

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every vote (CR 701.38) is logged. An open vote is shown to everyone. A secret vote ("Secret council — each player secretly votes …") is shown to its voter alone until every vote is cast, and then one reveal shows them all. Prove both with real cards: Council's Judgment for an open vote, and Truth or Consequences (added to the pool) for a secret one.

**Architecture:**
- `Vote` gains `secret :: Bool`. Its codec defaults the field to `False`, so the existing vote cards need no change.
- `Parun.Types.Ballot` describes one cast vote: a voter, plus an object or a word.
- Two new events:
  - `GameEvent.Voted { ballot, audience :: Set PlayerId }`. Its audience is every player for an open vote, and the voter plus the voter's decider for a secret one (CR 723.4).
  - `GameEvent.VotesRevealed { ballots }`, logged once, after a secret vote's last ballot.
- `Visibility.witnessed` reads both. The `Witnessed` scenario view renders a vote as `"<voter> voted <choice>"`, and a reveal as one such entry per ballot.

**Tech Stack:** Haskell (GHC via the repo's nix flake), cabal, tasty, JSON scenarios under `data/scenarios/`.

**Spec:** `docs/superpowers/specs/2026-10-11-per-player-visibility-design.md`, section "Unit 5", second paragraph. Read that section only.

## Global Constraints

- **Worktree.** Work only in `/Volumes/nvme/Developer/parun/.claude/worktrees/4452-secret-vote`, on branch `4452-secret-vote`, cut from `origin/main` at fd2075afd. Never `cd` to the primary checkout or to any other worktree. Before the first build, run `script/warm-worktree.sh seed /Volumes/nvme/Developer/parun/.claude/worktrees/4452-secret-vote`, then confirm with `ls cabal.project.local`.
- **Concurrent work.** Another agent is implementing hidden agenda (#3497) in its own worktree. Its changes touch `Parun.Engine.Visibility`, `Parun.Engine.Event` and `Parun.Scenario`. Never touch that worktree. Keep this unit's edits to those three files small and local, so the end-of-work merge stays easy.
- **Merging.** Merge `origin/main` once, in Task 3 Step 1, and never mid-plan.
- **Running cabal.**
  - Prefix every `cabal` call with `script/with-build-lock.sh`.
  - Redirect output to a file in the scratchpad and read that file; never pipe into `head`.
  - `-p` patterns contain no spaces. Scenario tests are named by their bare file name, and every scenario this unit adds carries the stem `secret-vote` or `open-vote`.
  - Full suite: `script/with-build-lock.sh cabal test --test-options '--timeout 120s --hide-successes' > "$SCRATCH/suite.log" 2>&1`. Record the count before Task 1.
- **Effect identity.** The rules core must never case on an effect's identity. Logging from the `Vote` resolver arm is that arm doing its own job.
- **CLAUDE.md item 4.**
  - New `GameEvent` constructors:
    - Each needs an `Arm.tagged` arm plus a round-trip case.
    - Read `Event.Binding`'s `_ -> Map.empty` fallthrough.
    - Read every exhaustive `GameEvent` match. Mirror `Looked`, which neither triggers nor counts as a reveal, and record any site where a vote should differ.
    - `ZoneTriggerSpec` needs nothing unless a trigger condition is added.
  - New `Vote` field:
    - Grep every `MkVote` and every `{ Vote.`; `Projection.Rewrite` must carry the field through.
    - Read the `Mentions` arms for `Vote`.
- **Types and haddocks.** One type per `Parun.Types.<TypeName>` module. A constructor's haddock is one line plus its CR citation. Every new codec gets a round-trip case.
- **Style.** `case` over `maybe`, `let` over `where`, no backticks, no partial `head`, and extensions only from `.hlint.yaml`.
- **Mutations.** Every proving check gets one: `script/with-build-lock.sh script/mutate.sh FILE @SCRIPT PATTERN`, with the sed script in a scratchpad file. Keep imports and bindings used, so `-Werror` still compiles. Name the assertion that reddened. Never edit a file while a mutation runs on it.
- **Oracle text.** Verify it with `curl -s 'https://api.scryfall.com/cards/named?exact=<Name>'`. Checked 2026-10-11, Truth or Consequences: {2}{U}{R} Sorcery, "Secret council — Each player secretly votes for truth or consequences, then those votes are revealed. You draw cards equal to the number of truth votes. Then choose an opponent at random. Truth or Consequences deals 3 damage to that player for each consequences vote."
- **Never stash.** Stage, run `hooky fix`, then `git add` again.
- **Commits.** A subject line, at most two sentences of why, and the trailers `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01N6oeJknHeSC1oKJ3H5pihY`. Write "related to #4452". Never put close, fix or resolve next to an issue number in a commit.
- **CR text.** Read it from `docs/rules.txt` by number. Checked 2026-10-11: 207.2c (secret council is an ability word), 701.38a, 701.38b, 701.38d, 723.4.

## Divergences from the spec

- **The producer is Truth or Consequences, not Mob Verdict.** Mob Verdict votes for a player and needs #3717. Truth or Consequences votes between two words, which `VoteChoices.Words` already expresses. Mob Verdict inherits secrecy for free once #3717 lands. Task 3 records this on #3717 and amends the spec's Unit 5 line.
- **"The prompt to a later chooser omits the earlier choices" already holds.** `ChooseVote` and `ChooseVoteWord` carry no earlier ballots. This unit adds only the log, and it does not make an open vote's prompt carry earlier ballots the way `ChooseCardName` does (CR 101.4b). CR 701.38a does not say a vote is announced, so that is left alone.
- **An open vote is logged with every player in its audience.** CR 701.38 does not state that open votes are public, but votes are cast in turn order with no secrecy, and only a secret-council card makes one hidden. Task 1 makes the open case observable, so that the secret one has something to differ from.

## Review Focus

1. **A secret ballot stays hidden until the reveal.** Bob's `Witnessed` holds his own vote and the reveal, but not alice's individual vote. Test: Task 2, the Truth or Consequences scenario.
2. **The reveal shows every ballot to everyone,** in voting order. Test: Task 2, the same scenario's reveal entries.
3. **An open vote is seen by everyone as it is cast.** Test: Task 1, the Council's Judgment scenario.
4. **The tallies still drive the card.** Truth or Consequences draws cards equal to the truth votes and deals 3 damage per consequences vote to a random opponent. Test: Task 2, the life and hand-count checks.
5. **A vote made while controlled is witnessed by the controller too** (CR 723.4). Test: Task 1, a `Parun.VisibilitySpec` case.

---

### Task 1: Ballots and the vote log

**Files:**
- Create: `source/libraries/types/Parun/Types/Ballot.hs`, `Voted.hs`, `VotesRevealed.hs` (or one payload type per event, matching `Looked`'s style), plus their codecs and specs.
- Modify: `source/libraries/types/Parun/Types/Vote.hs`, `source/libraries/codec/Parun/Codec/Vote.hs` and its spec.
- Modify: `source/libraries/types/Parun/Types/GameEvent.hs`, `source/libraries/codec/Parun/Codec/GameEvent.hs` and its spec, and every `GameEvent` match the compiler names.
- Modify: `source/libraries/engine/Parun/Engine/Resolve/Effect.hs` (the `Vote` arm, ~6773–6824, and its `cast` helper).
- Modify: `source/libraries/engine/Parun/Engine/Visibility.hs` (`witnessed`) and `source/libraries/scenario/Parun/Scenario.hs` (the `Witnessed` arm), plus `data/scenarios/README.md`.
- Create: `data/scenarios/visibility/cr-701-38a-open-vote-council-s-judgment-votes-are-seen-by-everyone.json`.
- Test: `source/libraries/test/Parun/VisibilitySpec.hs`.

**Interfaces:**
- **Produces:**
  - `Ballot = MkBallot { voter :: PlayerId, choice :: BallotChoice }`, where `BallotChoice = ForObject ObjectId | ForWord SlotName`. Names are subject to an existing-type grep.
  - `GameEvent.Voted`, with payload `{ ballot, audience :: Set PlayerId }`.
  - `GameEvent.VotesRevealed`, with payload `{ ballots :: [Ballot] }`.
  - `Vote.secret :: Bool`.
- **JSON:** the vote's `"secret": true`, defaulted to false. Record the exact spelling in the report, because Task 2 writes card JSON with it.

- [ ] **Step 1: Baseline.** Seed the worktree, run the full suite, and record the count.

- [ ] **Step 2: Write the failing tests.**
  - **Scenario (Council's Judgment).** Copy an existing Council's Judgment board: grep `data/scenarios` for "Council's Judgment".
    - Both players vote, and their vote answers keep the existing spelling.
    - Checks after resolution, with the voter seat labels as the board names them:
      - `Witnessed` for alice lists both ballots, e.g. `["alice voted Hill Giant", "bob voted Goblin Piker"]`.
      - `Witnessed` for bob lists the same.
    - Render an object choice by its snapshot or last-known name, so a destroyed object still names itself. Record the exact rendering in the report.
  - **Spec case.** In `Parun.VisibilitySpec`, add `"a secret ballot is witnessed by its voter and the voter's controller"`. Build a state in which alice decides for bob (copy the unit-4 controlled-look case), log a secret `Voted` for bob, and assert:
    - `witnessed alice` is `Visible`;
    - `witnessed bob` is `Visible`;
    - a third seat is `Obscured`;
    - without the control row, alice is `Obscured`;
    - a `VotesRevealed` event is `Visible` to every seat.
  - Expect a compile failure first, then the scenario's check to fail.

- [ ] **Step 3: Implement.**
  - **Types and codecs.** Add the types and their codecs, and `Vote.secret` with `Fields.defaulted False`.
  - **`Vote` arm logging.**
    - Each cast ballot logs `Voted` with `audience` = every player in the game (read how the vote arm lists its voters) when not secret. When secret, it is `Set.fromList [voter, Decider.unwrap (Decide.deciderFor voter gs)]`.
    - After the last ballot of a secret vote, log one `VotesRevealed` with every ballot in voting order.
    - Extra votes (CR 701.38d) are ballots too.
    - The tally logic is unchanged.
  - **`witnessed`.** Add the arms: `Voted` is `visibleIf (Set.member pid audience)`, and `VotesRevealed` is `Visible`.
  - **`Witnessed` view.** Render `Voted` as `"<voter label> voted <choice>"`, and `VotesRevealed` as one such string per ballot, in order. Render a word choice by its `SlotName` text. Add a README clause.
  - **Remaining sites.** Fix every compile-forced `GameEvent` site, mirroring `Looked`, and read the item-4 sites.

- [ ] **Step 4: Green and mutations.** Run `-p open-vote`, `-p VisibilitySpec`, the codec specs, then the full suite.
  - **m1:** an open vote's audience becomes the voter alone. Expect the Council's Judgment bob check to redden.
  - **m2:** a secret vote's audience drops the decider. Expect the spec's controller assertion to redden.
  - **m3:** `witnessed` answers `VotesRevealed` with `Obscured`. Expect the spec's reveal assertion to redden.

- [ ] **Step 5: Commit.** "Log each vote with its audience, and reveal a secret vote's ballots at once".

### Task 2: Truth or Consequences

**Files:**
- Create: `data/cards/truth-or-consequences.json`.
- Create: `data/scenarios/visibility/cr-701-38a-secret-vote-truth-or-consequences-hides-each-ballot-until-the-reveal.json`.

**Interfaces:**
- **Consumes:** Task 1's `"secret": true` spelling and the `Witnessed` rendering of votes.

- [ ] **Step 1: Write the card.**
  - Model it on Plea for Power or Travel Through Caradhras, the pool's `Words` votes. Read both.
  - The vote has `"secret": true` and the words `truth` and `consequences`.
  - Then "You draw cards equal to the number of truth votes", reading the `truth` tally as an amount.
  - Then "choose an opponent at random": use `Effect.ChoosePlayerAtRandom`, and read Ruhan of the Fomori's JSON for its shape.
  - Then 3 damage to that player per consequences vote, using `Quantity` arithmetic (`Times` / `Arithmetic`); grep an existing "for each" damage.
  - Give it `oracleText` exactly as the verified Oracle text. If `_scratch/AtomicCards.json` exists (in the primary checkout's `_scratch/`, read by absolute path without `cd`), re-run ingest's oracle check.

- [ ] **Step 2: Write the failing scenario.**
  - **Board:** alice has {2}{U}{R} available and Truth or Consequences in hand, and both seats have enough library to draw from.
  - **Timeline:** cast it. Alice votes truth and bob votes consequences; answer `ChooseVoteWord` in each voter's key, copying a `Words` vote scenario's spelling. Answer the random opponent, the `RandomPlayer` chance prompt, keyed to the active player (README).
  - **Checks after resolution:**
    - `Witnessed` for alice: `["alice voted truth", "alice voted truth", "bob voted consequences"]`, i.e. her own ballot, then the reveal's two.
    - `Witnessed` for bob: `["bob voted consequences", "alice voted truth", "bob voted consequences"]`.
    - Alice drew 1 card, checked by a hand or library `Count`.
    - Bob's life is 17 (3 × 1 consequences vote).
  - **If the run fails:** if the real order of log entries differs because the reveal is logged differently, report the actual lists. Do not change what is proved: bob's list must not hold alice's individual ballot before the reveal.
  - Run `-p secret-vote`, and expect it to fail until the card exists.

- [ ] **Step 3: Green and mutations.** Run `-p secret-vote`, then the full suite.
  - **m4 (card JSON):** `"secret": false`. Expect bob's `Witnessed` check to redden (it gains alice's individual ballot).
  - **m5 (Resolve/Effect.hs):** drop the `VotesRevealed` log. Expect bob's check to redden (the reveal entries vanish).
  - **m6 (card JSON):** draw by the `consequences` tally instead of `truth`. Expect the draw-count check to redden.

- [ ] **Step 4: Commit.** "Add Truth or Consequences, a secret vote".

### Task 3: Issues, spec note and the PR

- [ ] **Step 1: Merge.** Merge `origin/main`, rebuild, and run the full suite. If hidden agenda (#3497) has landed and conflicts in `Visibility.hs`, `Event.hs` or `Scenario.hs`, resolve the conflict by keeping both sides' arms. If the merge changes Tasks 1–2's behaviour, stop and report.

- [ ] **Step 2: Elision upkeep.**
  - Run `grep -rn '4452' . --include='*.hs' --include='*.json'`, read every hit, and rewrite each one this unit implements.
  - Amend the spec's Unit 5 line ("Secret council (Mob Verdict) is the producer; it needs #3717 …") to name Truth or Consequences as the producer, with Mob Verdict following #3717.
  - Comment on #3717 (dated 2026-10-11): a secret vote's log and reveal now exist, so Mob Verdict needs only player votes, plus `"secret": true`.

- [ ] **Step 3: Self-review.**
  - Check the CR citations against `docs/rules.txt`.
  - Re-read every touched comment.
  - Grep the `GameEvent.Voted` and `VotesRevealed` arms against `Looked`'s.
  - Check the `MkVote` and `{ Vote.` sites.
  - Confirm every codec has a round-trip case.

- [ ] **Step 4: Full suite, `hooky fix`, commit, push, and open the PR as a DRAFT.** The body has one line each:
  - **What and why:** unit 5b of the visibility spec. Secret votes are logged and revealed, and open votes are logged too. `Closes #4452`. The PR commits this plan and the spec amendment.
  - **CR:** 207.2c, 701.38a, 701.38b, 701.38d, 723.4.
  - **Design calls:**
    - Truth or Consequences instead of Mob Verdict;
    - open votes shown to everyone;
    - one reveal event;
    - the audience is the voter plus the voter's decider;
    - prompts unchanged (CR 101.4b-style earlier choices not added to open votes).
  - **Item-4 sites:** which ones were read.
  - **Verified:** suite count before → after; the two scenarios and the spec case; m1–m6, each with the assertion it reddened, named.
  - **Effect identity:** the rules core cases on an effect's identity: no.
  - **Deferred:**
    - #3717 (Mob Verdict, Círdan);
    - Elrond of the White Council (needs each ballot's voter, which the log now holds);
    - Trap the Trespassers (per-object tallies);
    - hidden agenda (#3497), in progress elsewhere.
  - End with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

  Leave it a draft. The controller marks it ready after the final review.
