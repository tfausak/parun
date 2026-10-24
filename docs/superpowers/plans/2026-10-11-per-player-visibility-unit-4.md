# Per-player visibility, unit 4: private looks and the audience log

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A look (CR 701.20e) is logged with its audience: the looker, plus whoever controlled the looker at the time (CR 723.4). `Visibility.witnessed` reads that audience, and a `Witnessed` scenario view lists the cards shown to a seat this turn. Enhanced Surveillance's optional extra look becomes a real choice, and the proof is that what the player has seen differs with the answer.

**Architecture:**
- A new `GameEvent.Looked` carries `{ card, characteristics, audience :: Set PlayerId }`. The audience is stored rather than derived, because what counts is visibility at the time of the look.
- `Revealed` keeps its implicit audience of everyone.
- `Effect.LookAt` gains a `looker :: PlayerRef`, defaulting to `Relative You` in the codec.
- The look sites emit `Looked`: the `LookAt` resolver, surveil, and the miracle look (CR 121.9).

**Tech Stack:** Haskell (GHC via the repo's nix flake), cabal, tasty, JSON scenarios under `data/scenarios/`.

**Spec:** `docs/superpowers/specs/2026-10-11-per-player-visibility-design.md`, section "Unit 4". Read that section only.

## Global Constraints

- **Worktree:** work only in `/Volumes/nvme/Developer/parun/.claude/worktrees/4391-private-looks`, on branch `4391-private-looks`, cut from `origin/main` at 35ea3e142. Never `cd` to the primary checkout. Before the first build, run `script/warm-worktree.sh seed /Volumes/nvme/Developer/parun/.claude/worktrees/4391-private-looks` and confirm `ls cabal.project.local`.
- **Merging:** merge `origin/main` ONCE, in Task 4 Step 1, never mid-plan.
- **cabal:** prefix every `cabal` call with `script/with-build-lock.sh`. Redirect output to a scratchpad file and read the file; never pipe into `head`.
- **Test selection:** `-p` patterns contain NO spaces. Scenario tests are named by bare file name; every scenario this unit adds carries the stem `private-look`, so `-p private-look` selects them.
- **Full suite:** `script/with-build-lock.sh cabal test --test-options '--timeout 120s --hide-successes' > "$SCRATCH/suite.log" 2>&1`. Record the count before Task 1.
- **Effect identity:** the rules core never cases on an effect's identity. Emitting `Looked` from the `LookAt` resolver arm is the arm doing its own job; no classification reads `Effect.LookAt` elsewhere.
- **CLAUDE.md item 4, new `GameEvent` constructor:**
  - `Parun.Codec.GameEvent` is `Arm.tagged`, so give it an arm and a round-trip case.
  - `Parun.Engine.Event.Binding.eventBindingsOver` has a `_ -> Map.empty` fallthrough. Read it and record why `Looked` binds nothing, or add an arm.
  - Read the exhaustive matches in `Event/Match.hs`, `Event/Trigger.hs`, `Game.hs`, `Count.hs` and `Cost.hs`, and record what each does with `Looked`.
  - **`Looked` is NOT a reveal.** It must not count wherever `Revealed` is judged: CR 400.7j findability in `Count.hs`, reversal in `Cost.hs`, the lasting-reveal stamp in `Engine.placeBorne`, and miracle's trigger matching.
  - `ZoneTriggerSpec`'s `representativeEvents` and `everyTriggerCondition` need nothing unless a trigger condition is added.
  - `Fragmented.historyReaders` applies only to card constructs; say so in the PR.
- **CLAUDE.md item 4, the `LookAt` field:**
  - `{}` patterns that absorb it silently: `Slots.hs effectPlayerRefs` (~957) must return the looker; `Slots.hs slotsOf` (~1278) must return the looker's slot if it names one; also `ManaAbility.hs` (~360, 554, 692), `EffectZone.hs` (~191), `Resolve/Effect.hs` (~3311), `CardSpec.hs` (~1300, 1827, 2359, 2877) and `EffectLintSpec.hs` (~307).
  - Positional patterns that break the compile (fix each one): `Slots.hs`, `Mentions.hs` (~1873, which must also read the PlayerRef's slot names), `Projection/Rewrite.hs` (~670, CR 612.1's walk; a record update must carry the new field), `CardSpec.hs`, `EffectLintSpec.hs` and `EffectSpec.hs`.
  - Grep `{ LookAt.` and `MkLookAt` for every construction and update.
- **CLAUDE.md item 4, a new `Prompt` constructor (Task 2):** if one is added, it owes `Scenario.Prompt.deciderOf` and `kindOf`, a `Response` constructor, `Replay.encode`, `Replay.decode` and `Replay.defaultAnswer`, the scenario `Answer` reply decoding, and every exhaustive match the compiler names. Read how `OfferedMiracleReveal` is wired end to end and mirror it.
- **Types:** one type per `Parun.Types.<TypeName>` module. A constructor's haddock is one line plus its CR citation. Every new codec gets a round-trip case.
- **Style:** `case` over `maybe`, `let` over `where`, no backticks, no partial `head`. Extensions only from `.hlint.yaml`.
- **Mutations:** every proving check gets one. Run `script/with-build-lock.sh script/mutate.sh FILE @SCRIPT PATTERN`, with the sed script in a scratchpad file, keeping imports and bindings used (`-Werror`). Name the assertion that reddened. Never edit a file while a mutation runs on it.
- **Card text:** verify Oracle text with `curl -s 'https://api.scryfall.com/cards/named?exact=<Name>'` before relying on a card.
- **Never stash.** Stage, run `hooky fix`, then `git add` again.
- **Commits:** a subject line, at most two sentences of why, and the trailers `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01N6oeJknHeSC1oKJ3H5pihY`. Write "related to #4391"; never put close, fix or resolve next to an issue number in a commit.
- **CR text:** read it from `docs/rules.txt` by number. Checked 2026-10-11: 121.9, 701.20a, 701.20e, 701.22a, 701.23a, 701.25a, 701.25b, 701.29a, 723.4, 723.5.

## Divergences from the spec

- **Scry, fateseal and search stay unlogged.** Each is a look in CR terms (701.22a, 701.29a, 701.23a), but the spec names only `LookAt`, surveil (for the proof) and the miracle look. Task 4 files one issue for the rest, with producers.
- **Every `looker` in the pool is `Relative You`.** No card in the pool says "target player looks at". The codec defaults the field, so the 29 `LookAt` cards need no JSON change. Hideaway's minted `LookAt` (`Keyword.hs` ~7534) sets it explicitly.
- **The audience is the looker plus the looker's DECIDER**, i.e. `Decider.unwrap (Decide.deciderFor looker gs)`. That is the reverse of `Visibility.controlledBy`, which lists the seats a player controls.

## Review Focus

1. **A look shows the looker alone.** The opponent's `Witnessed` stays empty. Test: Task 1, the Ponder (or Into the Wilds) scenario.
2. **A look while controlled.** The controller witnesses it too (CR 723.4). Test: Task 1, a `Parun.VisibilitySpec` case that records a look while `GameState.control` makes alice bob's decider.
3. **Declining Enhanced Surveillance's look.** The extra cards are not witnessed, and they stay in place unnamed (CR 701.25b). Test: Task 2, the decline scenario.
4. **A look is not a reveal.** No lasting-reveal stamp, and miracle's trigger and findability are unaffected. Test: Task 3, the miracle scenario's decline path, where the Wrath is witnessed by its drawer and `Seers` stays the drawer alone.
5. **Two Enhanced Surveillances each ask** (per the 2018-10-05 ruling). Test: Task 2, the existing two-copies scenario, updated with two answers.

---

### Task 1: The `Looked` event, the `looker`, `witnessed`, and the `Witnessed` view

**Files:**
- Create: `source/libraries/types/Parun/Types/Looked.hs`, `source/libraries/codec/Parun/Codec/Looked.hs`, `.../LookedSpec.hs`. Use `Parun.Types.Revealed` and its codec as the template.
- Modify: `source/libraries/types/Parun/Types/GameEvent.hs`, `source/libraries/codec/Parun/Codec/GameEvent.hs` and its spec
- Modify: `source/libraries/types/Parun/Types/LookAt.hs`, `source/libraries/codec/Parun/Codec/LookAt.hs` and its spec, plus every site in Global Constraints' `LookAt` bullet
- Modify: `source/libraries/engine/Parun/Engine/Event.hs` (a `look` recorder beside `reveal`), `source/libraries/engine/Parun/Engine/Resolve/Effect.hs` (the `LookAt` arm, ~6117), `source/libraries/engine/Parun/Engine/Keyword.hs` (hideaway's `LookAt`)
- Modify: `source/libraries/engine/Parun/Engine/Visibility.hs` (`witnessed`)
- Modify: `source/libraries/types/Parun/Types/View.hs`, `source/libraries/scenario/Parun/Scenario.hs` (`renderView`), `data/scenarios/README.md`
- Create: `data/scenarios/visibility/cr-701-20e-private-look-ponder-shows-the-top-cards-to-its-caster-alone.json`
- Test: `source/libraries/test/Parun/VisibilitySpec.hs`

**Interfaces:**
- Produces:
  - `Parun.Types.Looked`: `data Looked = MkLooked { card :: ObjectId, characteristics :: ProjectedCharacteristics, audience :: Set PlayerId }`
  - `GameEvent.Looked Looked.Looked`
  - `LookAt.looker :: PlayerRef`
  - `Parun.Engine.Event.look :: PlayerId -> ObjectId -> Game ()`, which records the looker plus the looker's decider
  - `Parun.Engine.Visibility.witnessed :: PlayerId -> LoggedEvent -> Visibility`
  - `View.Witnessed`

- [ ] **Step 1: Baseline.** Seed the worktree, run the full suite, and record the count.

- [ ] **Step 2: Write the failing scenario.** Verify Ponder's Oracle text ("Look at the top three cards of your library, then put them back in any order. You may shuffle. Draw a card."). If Ponder's answer flow is awkward, use another `LookAt` card from the pool that looks at the caster's own library, such as Into the Wilds, and say so.
  - Board: alice has the mana and Ponder in hand. Her library is labelled top first: `$l1`, `$l2`, `$l3`, `$l4`. Bob has a library.
  - Timeline: cast Ponder, then answer its order and shuffle prompts. Find their kinds in an existing Ponder scenario; grep `data/scenarios` for "Ponder".
  - Checks, after resolution:
    - `{ "View": { "of": "Witnessed", "player": "alice", "is": [<the three names, in look order>] } }`
    - `{ "View": { "of": "Witnessed", "player": "bob", "is": [] } }`
  - Give the four library cards distinct names so the rendered names discriminate.
  - Run `-p private-look` and expect a failure decoding `Witnessed`.

- [ ] **Step 3: Write the failing spec case.** In `Parun.VisibilitySpec`, add `"a look while controlled is witnessed by the controller too"`. Build a state in which alice is bob's decider: copy how the unit-1 Mindslaver or Word of Command spec support writes `GameState.control`, or build the row directly. Record `Event.look` for bob on a card, then assert:
  - `witnessed alice` on the logged event is `Visible`;
  - `witnessed bob` is `Visible`;
  - a third seat, if the support offers one, is `Obscured`.

  Without the control row, `witnessed alice` is `Obscured`.

- [ ] **Step 4: Implement.**
  - **Types and codecs.** `Looked` and its codec, plus the `GameEvent` arm and its round-trip. `LookAt` gains `looker :: PlayerRef.PlayerRef`; its codec uses `Fields.defaulted` with `PlayerRef.Relative PlayerRelation.You` (match the real constructor names), plus a round-trip case with a non-default looker.
  - **`Event.look`.** Model it on `reveal` and `revealedOn`: record `GameEvent.Looked (MkLooked oid (Projection.project oid gs) audience)` only if the object exists, where `audience = Set.fromList [pid, Decider.unwrap (Decide.deciderFor pid gs)]`.
  - **The `LookAt` resolver arm.** Resolve `looker` through the resolution's PlayerRef resolver (`Slots.playerRefPlayers`, or whatever its neighbours use). For each named card and each looker, call `Event.look`. Keep the slot binding. Rewrite the arm's comment: it now records a `Looked`, and a `Revealed` would still be wrong (CR 701.20a).
  - **Hideaway.** Set `looker` explicitly to `Relative You`.
  - **`witnessed pid logged`.** It is `Visible` for a `Revealed`, `visibleIf (Set.member pid audience)` for a `Looked`, and `Obscured` for anything else. Here a `_` arm over `GameEvent` is legitimate.
  - **The `Witnessed` view.** Add `View.Witnessed` with a one-line haddock citing CR 701.20a / 701.20e. Its `renderView` arm folds `GameState.events gs` in order, keeps the events that `witnessed pid` answers `Visible` for, and renders each card by its snapshot's name (`ProjectedCharacteristics.names`; take the single name, or join them deterministically), because the card's id is usually dead after a move. Add the README clause.
  - **Fix every site** in Global Constraints' `LookAt` bullet.

- [ ] **Step 5: Green and mutations.** Run `-p private-look` and `-p VisibilitySpec`, the codec specs, then the full suite. Mutations, naming the assertion each reddens:
  - **m1** (Event.hs): `audience = Set.fromList [pid]` only. Expect the spec's controller assertion to redden.
  - **m2** (Resolve/Effect.hs): drop the `Event.look` call. Expect the scenario's alice check to redden.
  - **m3** (Visibility.hs): `Looked` answers `Visible` for everyone. Expect the scenario's bob check to redden.

- [ ] **Step 6: Commit.** "Log a look with its audience, and add a Witnessed scenario view".

### Task 2: Surveil's looks, and Enhanced Surveillance asks

**Files:**
- Modify: `source/libraries/engine/Parun/Engine/Resolve/Effect.hs` (the Surveil arm ~6174 and `decideSurveil` ~11355), `source/libraries/engine/Parun/Engine/PlayerEffect.hs` (`surveilExtra`, ~2744, and its #4391 note), plus the prompt plumbing if a prompt is added
- Modify: `data/scenarios/library-order/cr-701-25b-*.json` (the three Enhanced Surveillance scenarios) and `source/libraries/test/Parun/LibraryOrderSpec.hs` wherever their flow changes
- Create: `data/scenarios/library-order/cr-701-25b-private-look-declining-enhanced-surveillance-leaves-the-extra-cards-unseen.json`

- [ ] **Step 1: Decide the question's shape.**
  - Per the 2018-10-05 ruling, two copies add four, so each grant is its own "may": ask once per grant, keyed by the granting permanent.
  - Look for an existing source-keyed yes/no prompt that fits "a static ability lets you look at more cards". `OfferedMiracleReveal`'s shape (a decider, a player, a source object, then Exercises or Declines) is the nearest.
  - If no existing prompt fits without lying about its meaning, add one: `OfferedExtraLook :: Decider -> PlayerId -> ObjectId -> Natural -> Prompt OptionalDecision`, where the Natural is the grant's count. Wire it per Global Constraints' Prompt bullet.
  - Record the choice and the reason in the report.
  - `surveilExtra` must answer per grant, as `(source, count)` pairs, for the prompt to be asked per grant. Widen it and grep its callers (CLAUDE.md: widening a function's result has no tripwire).

- [ ] **Step 2: Write the failing scenarios.**
  - **Decline (new).** Copy `cr-701-25b-alice-s-enhanced-surveillance-makes-the-extra-two-cards-hers-to-bin-o.json`'s board, with distinctly named library cards.
    - Answer the new question with Declines, then answer `ChooseSurveil` over the surveil's own N cards only.
    - Check that `Witnessed` for alice lists exactly the N looked cards, and that the library's order below them is unchanged (the unnamed extra cards stay in place, CR 701.25b).
  - **Accept.** Update the existing scenario: add an Exercises answer before its `ChooseSurveil` answer, and a `Witnessed` check listing all N+2 cards.
  - Update the two-copies scenario with two Exercises answers, and the bob's-copy scenario as its flow requires. Bob's Enhanced Surveillance must ask alice nothing.
  - Run `-p 701-25b` and expect failures.

- [ ] **Step 3: Implement.** Before the surveil, ask each grant's question of the surveiling player, and sum the accepted counts. Then emit `Event.look` for every card the surveil looks at, own and extra, before `ChooseSurveil` is asked. Give the prompt (if one was added) `Replay.defaultAnswer` Exercises, so that `Script`-driven specs keep today's behaviour, and say so. Rewrite the #4391 note on `surveilExtra`. Update `LibraryOrderSpec` where its flow changed.

- [ ] **Step 4: Green and mutations.** Run `-p 701-25b`, `-p LibraryOrder` and `-p private-look`, then the full suite.
  - **m4**: always accept, ignoring the answer. Expect the decline scenario's `Witnessed` check to redden.
  - **m5**: drop the surveil `Event.look`. Expect the accept scenario's `Witnessed` check to redden.

- [ ] **Step 5: Commit.** "Log surveil's looks, and let Enhanced Surveillance's extra look be declined".

### Task 3: The miracle look

**Files:**
- Modify: `source/libraries/engine/Parun/Engine/Event.hs` (`offerMiracleReveal`, ~8743, and its #1412 note)
- Modify: `source/libraries/test/Parun/MassEffectSpec.hs` (the Carth look note ~1244 and its `revealed` helper, ~1279–1288; Ancestral Memories ~1000)
- Create: `data/scenarios/event-trigger/cr-121-9-private-look-the-miracle-card-is-seen-by-its-drawer-before-the-reveal.json`

- [ ] **Step 1: Write the failing scenario.** Copy the unit-2 miracle scenario `data/scenarios/event-trigger/cr-702-94b-lasting-reveal-the-miracle-card-stays-revealed-while-its-trigger-is-on-the-stack.json`, but answer `OfferedMiracleReveal` with Declines. Then check:
  - `Witnessed` for alice is `["Thunderous Wrath"]`;
  - `Witnessed` for bob is `[]`;
  - `Seers` on `"Thunderous Wrath"` is `["alice"]`: a look is not a reveal.

  Expect the alice `Witnessed` check to fail.

- [ ] **Step 2: Implement.** In `offerMiracleReveal`, record `Event.look pid card` before asking `Prompt.OfferedMiracleReveal`. Rewrite the CR 121.9 note: the look is now logged, and the prompt still names the card to its answerer (#1412). Run the existing miracle scenarios: an accepted reveal now logs a `Looked` and then a `Revealed`, so `Witnessed` would list the Wrath twice, which is correct (shown twice). Confirm that no existing check counts events in a way this breaks.

- [ ] **Step 3: MassEffectSpec.** Carth's look and Ancestral Memories' look now log `Looked`. Rewrite the notes that say "the look records nothing". Keep the `revealed` helper counting `Revealed` only, which is still right, and add one assertion that the look logged a `Looked` with the caster alone in its audience, where cheap.

- [ ] **Step 4: Green and mutations.** Run `-p private-look`, `-p 121-9`, `-p 702-94b` and `-p MassEffect`, then the full suite.
  - **m6**: drop the miracle `Event.look`. Expect the alice `Witnessed` check to redden.
  - **m7** (Visibility.hs, from Task 1): `witnessed` treats `Looked` as `Revealed`. Expect the bob `Witnessed` check to redden.

- [ ] **Step 5: Commit.** "Log the miracle look before its reveal is offered".

### Task 4: Issues, elisions and the PR

- [ ] **Step 1: Merge `origin/main`.** Run `git fetch && git merge origin/main`, rebuild, and run the full suite. If the merge changes the behaviour of Tasks 1–3, stop and report.

- [ ] **Step 2: Elision upkeep.** Run `grep -rn '4391' . --include='*.hs'` and read every hit. Each site the unit implements gets rewritten:
  - the `Effect.LookAt` haddock;
  - `Parun.Types.LookAt`;
  - `PlayerEffect.surveilExtra`;
  - the `LookAt` resolver arm.

  Also grep `#1412` for notes about private looks that are now untrue: the `ChosenCardFromAmong` CR 701.20e note, Foretell's CR 702.143e note and the FaceDown notes. A note about answerers being handed the whole state stays.

- [ ] **Step 3: File the follow-up.** Search titles first.
  - Title: "Scry, fateseal and searching a library don't record what the player saw".
  - Labels: `gap`, `area:effects`, `expires:card-driven`.
  - Body: a dated summary (2026-10-11), CR 701.22a, 701.29a and 701.23a, the three sites, and that each should call `Event.look`. Name the producers in the pool: a scry card, a fateseal card (grep `Fateseal` in `data/cards`), and a tutor.
  - Name the issue in the PR's deferred line.

- [ ] **Step 4: Self-review.**
  - Re-check every CR citation against `docs/rules.txt`.
  - Re-read every touched comment.
  - Grep `GameEvent.Looked` arms against `GameEvent.Revealed`'s, and record each site where `Looked` deliberately differs.
  - Grep `LookAt` construction and update sites.
  - Confirm every new codec has a round-trip case.

- [ ] **Step 5: Full suite, `hooky fix`, commit, push, open the PR as a DRAFT.** One line each in the body:
  - **What and why:** unit 4 of the visibility spec, private looks and the audience log. `Closes #4391`. Commits this plan.
  - **CR:** 121.9, 701.20a, 701.20e, 701.25a, 701.25b, 723.4, 723.5.
  - **Design calls:**
    - the stored audience;
    - the looker's decider, not the seats the looker controls;
    - the defaulted `looker`;
    - `Looked` is not a reveal anywhere;
    - one question per grant, and the prompt choice;
    - scry, fateseal and search deferred.
  - **Item-4 sites:** the `GameEvent`, `LookAt` and `Prompt` sites read.
  - **Verified:** suite count before → after; the scenarios and spec case; m1–m7, each with its reddened assertion named.
  - **Effect identity:** the rules core cases on an effect's identity: no.
  - **Deferred:**
    - the scry/fateseal/search issue;
    - other events' payloads unredacted until unit 7 (#1412);
    - unblocked: what `gh api repos/tfausak/parun/issues/4391/dependencies/blocking` lists.
  - End with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

  Leave it a draft; the controller marks it ready after the final review.
