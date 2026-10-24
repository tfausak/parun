# Test Suite Restructure Design

**Status:** approved (brainstorm), pending spec review
**Date:** 2026-07-17
**Topic:** split the single-file test suite by subsystem; make the property
tests durable

## Motivation

`source/test-suite/Main.hs` has grown to ~2753 lines and ~50 `TestTree` groups,
with shared fixtures, per-group helpers, answerers, and property tests all
interleaved. CLAUDE.md's "keep it a single file for now / don't split into
per-module test files yet" note has outlived its usefulness: the file is now too
large to hold in context at once, and adding a milestone's tests means appending
to an already-unwieldy file.

Two problems, addressed together:

1. **Organization.** No boundaries. A subsystem's coverage, its fixtures, and its
   helpers are scattered through one file with no locality.
2. **Property-test churn.** Three of the ten `QC.testProperty` assertions are
   *existence* checks ("across 100 seeds, at least one game does X") that serve as
   milestone exit criteria. Each milestone bolts on another `any … [1..100]` plus
   a helper, and one of them (`instants happen`) already had to be *added* this
   milestone and another (`casting actually happens`) *adapted*. These are "did
   the random generator exercise the feature yet," not invariants, and they don't
   belong in an ever-growing property list.

## Goals

- Split the suite into per-subsystem files, tracking the library's own module
  structure, with a shared `Support` module for cross-cutting fixtures.
- Keep the *universal* properties (true for all seeds, forever) as properties;
  convert the *existence* properties to targeted deterministic tests that live
  with their subsystem.
- Add one genuinely durable structural property: a lands-only mirror match always
  ends by a player decking.
- Preserve every existing assertion's coverage. No behavior changes to the
  engine. No unrelated refactoring.

## Non-goals

- No changes to `source/library` or `source/benchmark` (beyond nothing).
- No new engine coverage beyond the lands-only-decks property and the three
  existence→deterministic conversions.
- No renaming or rewording of existing test cases except where a group physically
  moves files. Assertions are preserved verbatim.

## Target module layout

Spec modules are **near-mirrors of the library's own modules**: each is named for
its primary `Parun.*` logic module, carries the `Parun.` prefix so the
correspondence is explicit (`Parun.Mana` ↔ `Parun.ManaSpec`), and opens with a
header comment listing every library module it covers. A handful of small,
tightly-coupled modules share one spec. The many `Parun.Type.*` data modules get
no spec of their own; their thin testable surface (smart constructors) folds into
the logic spec that exercises them.

Files live under `source/test-suite/Parun/`, except `Main.hs` at the test-suite
root:

```
Main.hs                -- imports each spec, builds testTree, runs defaultMain
Parun/Support.hs        -- cross-cutting shared fixtures, answerers, assertions
Parun/CoreSpec.hs       -- Parun.Type.Program (interpreter), Parun.Quantity
Parun/CardSpec.hs       -- Parun.Card: card data, type-line rules, printings, the lint
Parun/SetupSpec.hs      -- Parun.Setup, Parun.Type.Deck: setup, decks, opening hands
Parun/TurnSpec.hs       -- Parun.Turn: turn structure, phase schedule, CR 508.8 skips
Parun/GameSpec.hs       -- Parun.Game, Parun.Engine, Parun.Action: zones, legal actions, engine steps + engine-rule integration
Parun/ManaSpec.hs       -- Parun.Mana: mana payment, castability
Parun/CastSpec.hs       -- Parun.Cast, Parun.Stack: cast timing, the stack, discard, summoning sickness
Parun/CombatSpec.hs     -- Parun.Combat: attack/block legality, combat damage, keywords
Parun/DamageSpec.hs     -- Parun.Damage, Parun.Sba: the damage funnel, deathtouch, trample, SBAs
Parun/ResolveSpec.hs    -- Parun.Resolve, Parun.Target: targeting, resolution, the CR 608.2b fizzle
Parun/ReplaySpec.hs     -- Parun.Replay: record/replay round-trips
Parun/PropertySpec.hs   -- cross-cutting: universal QuickCheck invariants only
```

Note the naming choice `Parun.Resolve` + `Parun.Target` → `Parun.ResolveSpec` (not a
`Parun.TargetSpec`) deliberately avoids overloading `TargetSpec`, which is already
a type (`Parun.Type.TargetSpec`).

### Intended group assignment

The default mapping below is the plan's starting point. When the plan moves a
group it confirms the fit by reading the group; a group may land in a sibling
file if that reads better, but the file list above is fixed.

| File | Groups |
| --- | --- |
| Parun.CoreSpec | programTests, quantityTests |
| Parun.CardSpec | cardTests, lintTests, m2aCardTests, m2bCardTests, m2cCardTests, basicLandTests |
| Parun.SetupSpec | setupTests, greenBlackSetupTests, deckTests |
| Parun.TurnSpec | turnTests, turnDataTests, skipTests |
| Parun.GameSpec | gameTests, actionTests, objectFactTests, engineTests, ruleTests |
| Parun.ManaSpec | manaTests, castabilityTests |
| Parun.CastSpec | castTests, castEngineTests, stackTests, discardTests, sicknessTests |
| Parun.CombatSpec | combatLegalityTests, declareTests, combatDamageTests, keywordTests, firstStrikeTests, m2bExitTests, defenderTests, vigilanceTests, hasteTests, evasionTests |
| Parun.DamageSpec | damageTests, damageEventTests, deathtouchTests, assignmentLegalityTests, trampleTests, trampleDeathtouchTests, sbaTests, creatureSbaTests, m2cPropertyTests |
| Parun.ResolveSpec | targetTests, resolveTests, fizzleTests |
| Parun.ReplaySpec | replayTests, combatReplayTests |
| Parun.PropertySpec | propertyTests (universal invariants only) + the new lands-only-decks property |

`ruleTests` is engine-rules integration (priority rounds, the CR 103.7a draw
skip, CR 514.2 discard, CR 704.5b deck-out), not card data, so it lands in
`Parun.GameSpec` alongside `Parun.Engine`'s coverage — not in `Parun.CardSpec`.

Note: `m2cPropertyTests` is misnamed — it holds deterministic HUnit fixture
tests (a deathtouch coverage case and a documentation-only assertion), not
QuickCheck properties, so it moves to `DamageSpec`, not `PropertySpec`.

## Support module

`Parun.Support` is the test suite's prelude: it holds *only* items used by two or
more spec files. Group-local helpers stay in the one spec that uses them.

Shared (into `Support`):

- Players and matchups: `alice`, `bob`, `bothPlayers`, `redRed`, `greenBlack`,
  `matchups`.
- Answerers used across areas: `identityAnswer`, `castAnswer`, `aggressiveAnswer`,
  `playLandAnswer`, `randomAnswer`, plus `runRandomGame`, `shuffleWith`, and the
  `pick`/insertion helpers those need.
- Board builders shared across areas: `addCreature`, `addPiker`, `landsInPlay`,
  `mountainsInPlay`, `handOne`, `combatBoardOf`, `combatBoard`, `pikerInHand`,
  `boltInHand`.
- Shared assertions/queries: `lifeOf`, `creaturesInPlay`, `countByName`,
  `markDamage`, `tappedCount`, `handSize`, `pikerCard`, `isCreatureRecipient`.

Group-local (stay with their spec):

- `tramplingAnswer` (`Parun.DamageSpec`), `discardLastAnswer` (`Parun.CastSpec`),
  `recordingAnswer`/`askedPlayers` (`Parun.GameSpec` or `Parun.CastSpec`, per its
  group), `boltAnswer`/`twoBoltState` (`Parun.ResolveSpec`),
  `boltAtBobsPiker`/`pikerOf` (`Parun.ResolveSpec`), `fightWith`/`resolvedCreature`
  (their sole user's spec), and any other helper the migration finds is
  referenced from exactly one spec.

The plan determines each helper's home by grep: a helper referenced from ≥2 spec
files goes to `Support`; a helper referenced from exactly one goes to that spec.

## Property module and the existence→deterministic conversions

`PropertySpec` keeps only the universal QuickCheck invariants (true for every
seed):

- conservation: 120 objects at end;
- every game terminates with a result;
- at least 120 ids were minted;
- no mana floats at the end;
- life never increases above the starting total;
- **new:** a lands-only mirror match (both decks 60 basic lands) always ends by a
  player decking themselves (`Result.Won`/`Drawn` reached with each library
  empty and no other loss condition having fired) — a durable structural property
  that stays true no matter what cards later exist.

The three existence properties are converted to deterministic tests, each moving
to its subsystem's spec:

| Was (existence property) | Becomes (deterministic test) | Lands in |
| --- | --- | --- |
| `combat happens: some seed changes a life total` | a scripted or fixed-seed game in which combat provably changes a life total | CombatSpec |
| `green-black: some seed sends a creature to the graveyard` | a scripted or fixed-seed green-black game in which a creature provably dies | DamageSpec |
| `instants happen: some seed casts a Bolt` | a scripted or fixed-seed red-red game in which a Bolt provably reaches a graveyard | ResolveSpec |

Each conversion prefers a hand-built/scripted scenario; a single fixed seed
(`runRandomGame redRed 7`, etc.) is acceptable where scripting the full game is
disproportionate, provided the chosen seed is asserted to exhibit the behavior
deterministically. The helpers `someLifeChanged`, `creatureDied`, `boltCast_`
are inlined or reduced to the single-case form; no `any … [1..100]` survives for
these three. Future milestones add a targeted deterministic test for their new
feature, not another existence property.

## Conventions

- Each `Parun.*Spec` exposes a single `tests :: TestTree` — a `testGroup` named for
  the subsystem, holding that file's subgroups — and opens with a header comment
  listing the library modules it covers. `Main` imports each spec qualified (alias
  to last component, e.g. `import qualified Parun.CombatSpec`) and references
  `CombatSpec.tests` in `testTree`.
- `Parun.Support` is imported qualified under the short alias `S`
  (`import qualified Parun.Support as S`), so call sites read `S.alice`,
  `S.lifeOf`, `S.combatBoardOf`. This is a deliberate, documented exception to the
  alias-to-last-component rule, chosen because these names appear on nearly every
  test line; the short alias keeps the qualified-import discipline without the
  noise of `Support.` everywhere.
- Test modules follow the same Haskell 2010 / no-explicit-export-list /
  qualified-import / no-partial-function style as the library.
- The test-suite cabal stanza gains `other-modules:` with a
  `-- cabal-gild: discover source/test-suite` directive so new `Parun.*Spec` files
  are auto-registered; `Main.hs` stays `main-is`. The plan's first task verifies
  cabal-gild's discover excludes the `main-is` module; if it does not, the stanza
  hand-lists `other-modules` instead (a fixed ~13-entry list).

## Migration strategy

Incremental, with the full suite green after every commit — never a big-bang
move. Roughly:

1. Add `Parun/Support.hs` with the cross-cutting fixtures/answerers/assertions;
   make `Main.hs` import it (`as S`) and drop the now-duplicated definitions.
   Suite green.
2. For each subsystem file, in turn: create `Parun/<Area>Spec.hs`, move its groups
   and group-local helpers out of `Main.hs`, expose `tests`, wire
   `<Area>Spec.tests` into `Main`'s `testTree`. Suite green after each file. (~12
   small commits.)
3. Convert the three existence properties to deterministic tests in their new
   homes; add the lands-only-decks universal property to `Parun.PropertySpec`.
   Suite green.
4. `Main.hs` ends as imports + `testTree` + `defaultMain` only.
5. Update CLAUDE.md: replace the "single file / don't split" guidance with the
   new layout and the rule "spec modules near-mirror library modules
   (`Parun.Foo` ↔ `Parun.FooSpec`, `Parun.` prefixed, each exposing `tests` and
   heading a comment listing covered modules); shared fixtures → `Parun.Support`
   (aliased `S`); group-local helpers stay with their group; a new subsystem gets
   a new `Parun.<Area>Spec`."

## Verification

- After each migration commit: warning-clean
  `cabal build all --enable-tests --enable-benchmarks` and a green `cabal test`.
- Test-count guard: the total case count is preserved across pure moves. The net
  change over the whole restructure is well-defined — the three existence
  properties collapse from 3 QC properties to 3 deterministic cases (count of
  test *cases* as reported by tasty may shift by a small, enumerated amount), and
  the lands-only-decks property adds one. The plan states the expected final
  count and asserts it, so an accidentally-dropped group is caught.
- Final: `cabal clean` then a warning-free build, and a green suite.
