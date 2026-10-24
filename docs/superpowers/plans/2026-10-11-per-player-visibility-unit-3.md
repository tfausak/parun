# Per-player visibility, unit 3: standing grants

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** An effect that makes a player play with their hand revealed (Sen Triplets), play with the top card of their library revealed (Garruk's Horde, Future Sight), or lets them look at their top card any time (Fblthp, Johann; CR 401.5) widens who `sees` that card. Prove it with the real cards, and restore the clauses their JSON omits.

**Architecture:**
- One `PlayerEffect` arm, `Shows Shows.Shows`, carries a record: `MkShows { cards :: ShownCards, to :: Audience }`. It is one arm with parameters, not siblings.
- It is carried the ways every player effect already is: printed as a face's `playerAbilities` row, or stored by `Effect.AffectPlayers` with a duration.
- `Parun.Engine.Visibility.base` gains a term that asks `Parun.Engine.PlayerEffect.applying` for the card's owner. Because `base` is per seat, CR 723.4's lift applies for free.

**Tech Stack:** Haskell (GHC via the repo's nix flake), cabal, tasty, JSON scenarios under `data/scenarios/`.

**Spec:** `docs/superpowers/specs/2026-10-11-per-player-visibility-design.md`, section "Unit 3", including its "Visible wins and no term can veto" paragraph. Read that section only.

## Global Constraints

- **Worktree:** work only in `/Volumes/nvme/Developer/parun/.claude/worktrees/3237-standing-grants`, on branch `3237-standing-grants`, cut from `origin/main` at 0cf9a2941. Never `cd` to the primary checkout. Before the first build, run `script/warm-worktree.sh seed /Volumes/nvme/Developer/parun/.claude/worktrees/3237-standing-grants` and confirm `ls cabal.project.local`.
- **Merging:** merge `origin/main` ONCE, in Task 3 Step 1, never mid-plan.
- **Running cabal:**
  - Prefix every `cabal` call with `script/with-build-lock.sh`.
  - Redirect output to a scratchpad file and read the file. Never pipe it into `head`.
  - `-p` patterns contain NO spaces, because a space does not survive `--test-options`.
  - Scenario tests are named by their bare file name. Every scenario this unit adds carries the stem `standing-grant`, so select them with `-p standing-grant`.
  - Full suite: `script/with-build-lock.sh cabal test --test-options '--timeout 120s --hide-successes' > "$SCRATCH/suite.log" 2>&1`. Record the count before Task 1.
- **Effect identity:** the rules core never cases on an effect's identity. Reading the new `PlayerEffect.Shows` arm inside `Parun.Engine.Visibility` is the classification the closed half is allowed: it asks what a player effect lets someone see, the way `Parun.Engine.PlayerEffect` already reads its own arms. No `Effect` constructor is read.
- **New-arm sites (CLAUDE.md item 4):** a new `PlayerEffect` constructor owes a case at every site below.
  - Compile-forced cases in `Parun.Engine.PlayerEffect` (about 30 of them).
  - `Parun.Engine.Interchangeable.Mentions.playerEffectNames`.
  - `Parun.Engine.Projection.Rewrite` (~522).
  - `Parun.CardSpec.playerEffectFilters`. It returns `[]`, since `Shows` carries no Filter.
  - `Parun.EffectLintSpec`'s `unpreventableScopeOffends` and `unpreventablePatternOffends`.
  - The `Parun.Codec.PlayerEffect` arm. It is `Arm.tagged`: the tag is compile-forced, the arm is not, so add a round-trip case to `PlayerEffectSpec`.
  - Grep every `_` arm over `PlayerEffect` and record what each one does with `Shows`.
- **Type modules:** one type per `Parun.Types.<TypeName>` module, holding the type and its instances only.
  - Before creating `Audience` or `ShownCards`, grep for an existing type with the same meaning. If one exists, use it; if the name alone is taken, pick another name.
  - Constructors take `Mk` where they wrap a record.
  - A constructor's haddock is one line plus its CR citation.
- **Style:** `case` over `maybe`, `let` over `where`, no backticks, no partial `head`, extensions only from `.hlint.yaml`.
- **Mutations:** every proving check gets one. Run `script/with-build-lock.sh script/mutate.sh FILE @SCRIPT PATTERN`, with the sed script in a scratchpad file, keeping imports and bindings used (`-Werror`). Name the assertion that reddened. Never edit a file while a mutation runs on it.
- **Card text:** verify the Oracle text of every card you touch with `curl -s 'https://api.scryfall.com/cards/named?exact=<Name>'` before writing its JSON. Re-run ingest's oracle check (CLAUDE.md: `jq -f script/ingest/candidates.jq` over `AtomicCards.json`, then `parun ingest`) if `_scratch/AtomicCards.json` exists. It is a skipped step otherwise.
- **Git hygiene:** never stash. Stage, run `hooky fix`, then `git add` again.
- **Commits:** a subject line, at most two sentences of why, and the trailers `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01N6oeJknHeSC1oKJ3H5pihY`. Say "related to #3237". Never put close, fix or resolve next to an issue number in a commit.
- **CR text:** read it from `docs/rules.txt` by number. Checked 2026-10-11: 400.2, 401.2, 401.5, 401.6, 601.2i, 723.4.

## Divergences from the spec

- **The term sits in `base`, not in `sees`.**
  - `base` is per seat, so a `ThatPlayer` grant answers `Visible` to the card's owner, and through CR 723.4's fold to whoever controls them.
  - An `Everyone` grant answers `Visible` to every seat.
- **CR 401.6 is not modelled.** A top card that stops being revealed and is revealed again becomes a new object. Nothing in the pool observes that; record it in the deferred line.

## Review Focus

1. **A grant reaches its own player only.** Garruk's Horde reveals ITS controller's top card, not the opponent's (scope `You`). Test: Task 2, the Garruk's Horde scenario's opponent-library check.
2. **Only the top card.** The second card down stays hidden. Test: Task 2, the Garruk's Horde scenario's second-card check.
3. **A look is not a reveal.** Fblthp's grant shows bob's top card to bob alone, and its zone stays hidden (CR 400.2). Test: Task 2, the Fblthp scenario.
4. **A stored grant expires.** Sen Triplets' "this turn" reveal ends at the turn's end. Test: Task 2, the Sen Triplets scenario's next-turn check.
5. **CR 121.8 still wins over a revealed hand.** A card drawn mid-cast is kept face down even while the hand is revealed (the spec's no-veto note). Test: Task 1, a `Parun.VisibilitySpec` case.

---

### Task 1: The `Shows` player effect and the `sees` term

**Files:**
- Create: `source/libraries/types/Parun/Types/Shows.hs`, `.../ShownCards.hs`, `.../Audience.hs` (names subject to the collision grep)
- Create: matching `source/libraries/codec/Parun/Codec/{Shows,ShownCards,Audience}.hs` plus their `*Spec.hs` (patterns: a record codec such as `Parun.Codec.CastFromZone`, and an enum codec such as one using `Arm.enum`/`Arm.keyedEnum`)
- Modify: `source/libraries/types/Parun/Types/PlayerEffect.hs`, `source/libraries/codec/Parun/Codec/PlayerEffect.hs`, `source/libraries/codec/Parun/Codec/PlayerEffectSpec.hs`
- Modify: every site in Global Constraints' "New-arm sites" bullet
- Modify: `source/libraries/engine/Parun/Engine/Visibility.hs`
- Test: `source/libraries/test/Parun/VisibilitySpec.hs`

**Interfaces:**
- Produces:
  - `Parun.Types.ShownCards`: `data ShownCards = Hand | TopOfLibrary`
  - `Parun.Types.Audience`: `data Audience = Everyone | ThatPlayer`
  - `Parun.Types.Shows`: `data Shows = MkShows { cards :: ShownCards, to :: Audience }`
  - `PlayerEffect.Shows Shows.Shows`
  - JSON: `{"type": "Shows", "value": {"cards": {"type": "Hand"}, "to": {"type": "Everyone"}}}`. The exact enum shape follows the codec style you pick; record it in the report, because Task 2 writes card JSON with it.

- [ ] **Step 1: Baseline.** Seed the worktree, run the full suite, and record the count.

- [ ] **Step 2: Write the failing spec cases.** In `Parun.VisibilitySpec`, beside the CR 121.8 case unit 1 added (it builds a board through `Parun.Support`), add three cases. Each builds a `GameState` with an `ActivePlayerEffect` stored in `GameState.playerEffects`; read `Parun.Types.ActivePlayerEffect` and copy how an existing spec stores one (grep `playerEffects =` under `source/libraries/test/`). The cases:
  - `"a revealed hand is seen by every player"`: a stored `Shows (MkShows Hand Everyone)` row naming alice. `sees bob` on a card in alice's hand is `Visible`; without the row it is `Obscured`.
  - `"a card CR 121.8 keeps face down stays hidden in a revealed hand"`: the same row, with the card marked in `GameState.keptFaceDown`. `sees bob` and `sees alice` are both `Obscured`.
  - `"a look at the top card is the owner's alone"`: a `Shows (MkShows TopOfLibrary ThatPlayer)` row naming alice. `sees alice` on her top library card is `Visible`, and `sees bob` is `Obscured`; `sees alice` on her second card is `Obscured`.

  Expect them not to compile yet: `Shows` does not exist.

- [ ] **Step 3: The types and the arm.** Write the three type modules. Add to `PlayerEffect`:

```haskell
  | -- | CR 401.5 / 400.2: cards of this player's that are shown, and to whom.
    Shows Shows.Shows
```

Add the codec arm and its round-trip case. Then build, and fix every compile-forced site.
  - In `Parun.Engine.PlayerEffect`, give each forced case the neutral answer its neighbours give a non-restricting arm. Read the arms for `AdditionalSurveilCards` and `PlotFrom`, which are neighbours that restrict nothing.
  - Handle `Mentions`, `Rewrite`, `CardSpec`, `EffectLintSpec`, and every `_` arm you grep.

- [ ] **Step 4: The term.** In `Parun.Engine.Visibility`, define the term the way `revealedNow` is defined, then join it in `base` per seat. For the hand case, put it inside the hand branch AFTER the `keptFaceDown` test, so a kept-face-down card returns `Obscured` before the grant is consulted. The `Everyone`/`ThatPlayer` logic:

```haskell
-- | CR 401.5 / 400.2: a player effect showing the owner's hand or top card.
shownTo :: PlayerId -> ObjectId -> GameState.GameState -> Visibility.Visibility
shownTo seat oid gs = case Game.lookupObject oid gs of
  Nothing -> Visibility.Obscured
  Just obj ->
    let owner = Object.owner obj
        shown = Maybe.mapMaybe showsOf (fmap snd (PlayerEffect.applying owner gs))
        showsOf effect = case effect of
          PlayerEffect.Type.Shows s -> Just s
          _ -> Nothing
        isTop = case Game.zoneMembers Zone.Library owner gs of
          top : _ -> top == oid
          [] -> False
        reaches s = case Shows.to s of
          Audience.Everyone -> True
          Audience.ThatPlayer -> seat == owner
        covers s = case (Shows.cards s, Game.zoneOf oid gs) of
          (ShownCards.Hand, Just Zone.Hand) -> True
          (ShownCards.TopOfLibrary, Just Zone.Library) -> isTop
          _ -> False
     in visibleIf (any (\s -> covers s && reaches s) shown)
```

Match the real module aliases. `PlayerEffect.applying`'s exact name and result type are in `Parun.Engine.PlayerEffect` (~444); read it. The `_` arms here are over `PlayerEffect` and over a pair, and are legitimate.

Wire the term in:
- **Hand:** `if Game.keptFaceDown oid gs then Obscured else visibleIf (Object.owner obj == pid) <> shownTo pid oid gs`.
- **Library:** `shownTo pid oid gs` in place of the bare `Obscured`, keeping the CR 401.2 comment and adding CR 401.5.

Above the library arm, add this elision paragraph: "Not implemented: CR 401.5's new top card, changed while a spell is being cast or an ability activated or a special action taken, is shown at once rather than after (#N)." Task 3 files `#N`; write it literally for now.

- [ ] **Step 5: Green and mutations.** Run `-p VisibilitySpec`, `-p PlayerEffect`, `-p Shows`, `-p Audience` and `-p ShownCards` (whatever the spec groups' `describe` names are), then the full suite. Mutations on `Visibility.hs`, naming the assertion that reddens for each:
  - **m1**: `Audience.Everyone -> True` becomes `-> False`. Expect the revealed-hand case to redden.
  - **m2**: `Audience.ThatPlayer -> seat == owner` becomes `-> True`. Expect the look case's `sees bob` to redden.
  - **m3**: replace the `isTop` match with `True`. Expect the look case's second-card assertion to redden.
  - **m4**: move the hand term ahead of the `keptFaceDown` test, `(... <> shownTo ...)` outside the `if`. Expect the CR 121.8 case to redden.

- [ ] **Step 6: Commit.** "Add a player effect that shows a hand or top card, read by sees".

### Task 2: The cards

**Files:**
- Modify: `data/cards/sen-triplets.json`, `data/cards/garruks-horde.json`, `data/cards/future-sight.json`, `data/cards/fblthp-lost-on-the-range.json`, `data/cards/johann-apprentice-sorcerer.json` (confirm exact file names with `ls data/cards | grep -i`)
- Create: `data/scenarios/visibility/cr-401-5-standing-grant-garruk-s-horde-shows-its-controller-s-top-card-to-everyone.json`
- Create: `data/scenarios/visibility/cr-401-5-standing-grant-fblthp-lets-its-controller-alone-look-at-the-top-card.json`
- Create: `data/scenarios/visibility/cr-400-2-standing-grant-sen-triplets-reveals-the-target-s-hand-this-turn.json`
- Modify: the omission notes in `source/libraries/test/Parun/CastRestrictionSpec.hs` (~1956, #3237), `CastPermissionSpec.hs` (~690 Garruk's Horde, ~824 Future Sight, ~941 Johann), `SpecialActionSpec.hs` (~507 Fblthp); `source/libraries/engine/Parun/Engine/Cast.hs` `pileCandidates`' comment (~1517)

**Interfaces:**
- Consumes: Task 1's JSON shape for `Shows` (read Task 1's report or the codec), `View.Seers`.

- [ ] **Step 1: Verify the Oracle text.** Curl the five cards. The sentences, per the research:
  - Sen Triplets: "This turn, that player can't cast spells or activate abilities and plays with their hand revealed."
  - Garruk's Horde and Future Sight: "Play with the top card of your library revealed."
  - Fblthp, Lost on the Range and Johann, Apprentice Sorcerer: "You may look at the top card of your library any time."

  Confirm each one.

- [ ] **Step 2: Write the failing scenarios.** Copy the `Seers` form from `data/scenarios/visibility/cr-406-3-a-foretold-card-is-seen-by-its-owner-alone.json`. Libraries list their top card first.
  - **Garruk's Horde.** Board: alice has Garruk's Horde on the battlefield. Her library is `[{"card": "Llanowar Elves", "label": "a-top"}, {"card": "Forest", "label": "a-second"}]` and bob's is `[{"card": "Island", "label": "b-top"}]`. Checks at turn 1 PrecombatMain:
    - `$a-top` is `["alice", "bob"]`;
    - `$a-second` is `[]`;
    - `$b-top` is `[]`.
  - **Fblthp.** Board: bob has Fblthp on the battlefield and a labelled top library card `$b-top`; alice has a labelled top library card `$a-top`. Checks:
    - `$b-top` is `["bob"]`;
    - `$a-top` is `[]`.
  - **Sen Triplets.** Alice controls Sen Triplets. Bob holds a labelled card `$b-hand`, and both seats have libraries.
    - The trigger is "At the beginning of your upkeep, choose target opponent." Start where alice's upkeep is still to begin: read `data/scenarios/README.md` for whether `"step"` can be an earlier step, such as `"Untap"`. If it cannot, start in bob's turn with `"active": "bob"` and advance to alice's turn 2.
    - Answer the trigger's target with bob, using the `ChooseTargets` form from the README.
    - Checks:
      - before the trigger resolves, `$b-hand` is `["bob"]`;
      - after it resolves and the stack is empty, `["alice", "bob"]`;
      - in bob's next turn, once "this turn" has ended, `["bob"]` again.
    - If `$b-hand` has to survive bob's draw, label a card that stays.

  Run `-p standing-grant` and expect each scenario's grant check to fail.

- [ ] **Step 3: Restore the clauses.**
  - Garruk's Horde and Future Sight: add a `playerAbilities` row `{"effect": <Shows TopOfLibrary Everyone>, "scope": {"type": "You"}}` beside the existing ones.
  - Fblthp and Johann: add the same with `ThatPlayer`.
  - Sen Triplets: add one more `AffectPlayers` effect to the clause that already holds `CantCastSpells` and `CantActivateAbilities`, with the same `duration` and `players`, and the effect `Shows Hand Everyone`.
  - Re-run ingest's oracle check if the dump exists.
  - Run `-p standing-grant`; expect green.

- [ ] **Step 4: Rewrite the omission notes.**
  - The CastRestrictionSpec, CastPermissionSpec and SpecialActionSpec notes that say a clause is omitted now say it is implemented. Prefer a note naming the scenario that proves it, or drop the note.
  - Update `pileCandidates`' comment: parun's relation now hides the top card from a player who may not see it, but an answerer is still handed the whole state (#1412).
  - Grep `3237`, `3035` and `#1412` under `source/libraries/test/` and read every hit.

- [ ] **Step 5: Mutations, run against the card data.** For each, copy the card file aside, edit it, run the scenario, and move it back. You may also do this with `mutate.sh` on the JSON.
  - **m5**: drop Garruk's Horde's `Shows` row. Expect `$a-top is ["alice","bob"]` to redden.
  - **m6**: Fblthp's `ThatPlayer` becomes `Everyone`. Expect `$b-top is ["bob"]` to redden.
  - **m7**: drop Sen Triplets' `Shows` effect. Expect the after-resolution check to redden.
  - **m8** (on `Visibility.hs`): replace `PlayerEffect.applying owner gs` with an empty list. Expect all three scenarios to redden; name the first.

- [ ] **Step 6: Full suite, commit.** "Show Sen Triplets' target's hand and the top card under Garruk's Horde, Future Sight, Fblthp and Johann".

### Task 3: Issues, elisions and the PR

- [ ] **Step 1: Merge `origin/main`.** Run `git fetch && git merge origin/main`, rebuild, and run the full suite. If the merge changes the behaviour of Tasks 1–2, stop and report.

- [ ] **Step 2: File the CR 401.5 mid-cast elision.** Search titles first.
  - Title: "A new top card is shown at once when it changes in the middle of casting a spell".
  - Labels: `elision`, `area:zones`, and `expires:card-driven` or `expires:synthetic`.
  - Body:
    - a dated summary (2026-10-11);
    - the site;
    - CR 401.5's three cases (casting, activating, special action);
    - that `GameState.keptFaceDown`'s `Just` marks casting and activating already;
    - a producer: a pool card that draws or mills during casting beside Garruk's Horde or Fblthp. Search the pool; otherwise draft a synthetic per CLAUDE.md.
  - Replace `#N` in `Visibility.hs` with the new issue's number.

- [ ] **Step 3: Self-review.**
  - Re-check every CR citation against `docs/rules.txt`.
  - Re-read every touched comment.
  - Grep `PlayerEffect.` `_` arms and record each.
  - Confirm every new codec has a round-trip case.
  - Confirm `parun ingest`'s oracle check is clean, if it ran.

- [ ] **Step 4: Full suite, `hooky fix`, commit, push, open the PR as a DRAFT.** One line each in the body:
  - **What and why:** unit 3 of the visibility spec, standing grants. `Closes #3237`. `Closes #3035`. Commits this plan.
  - **CR:** 400.2, 401.2, 401.5, 723.4.
  - **Design calls:**
    - one parameterised arm, not siblings;
    - the term in `base`, so CR 723.4 lifts it;
    - the CR 121.8 guard ahead of the grant;
    - CR 401.6 not modelled.
  - **Item-4 sites:** every new-arm site read.
  - **Verified:** suite count before → after; the spec cases and three scenarios; m1–m8, each with its reddened assertion named.
  - **Effect identity:** the rules core cases on an effect's identity: no. It reads a `PlayerEffect` classification arm; no `Effect` constructor.
  - **Deferred:**
    - the CR 401.5 mid-cast elision (the new issue);
    - CR 401.6;
    - unblocked issues: what `gh api repos/tfausak/parun/issues/3237/dependencies/blocking` and the same for 3035 list.
  - End with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

  Leave it a draft. The controller marks it ready after the final review.
