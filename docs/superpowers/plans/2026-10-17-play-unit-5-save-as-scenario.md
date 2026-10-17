# Save a played game as a scenario (unit 5 of #5182) Implementation Plan

**Goal:** `pawl play --save FILE` writes the game as a scenario file that
`pawl scenario FILE` replays clean.

**Spec:** `docs/superpowers/specs/2026-10-17-play-portal-client-design.md`,
unit 5 and "My calls" (saved-game shape, self-contained, replays clean,
conceding and quitting).

## Rulings

- **A scenario starts from a board or from decks.** `Scenario.board`
  becomes `Scenario.start :: Start`, `FromBoard Board | FromDecks
  GameStart`. On the wire the key stays `"board"` for a board and is
  `"game"` for decks, so no existing file changes. A `GameStart` is its
  seats in turn order, each a label and its deck list's lines (`"12
  Grizzly Bears"`), read by `Pawl.DeckList`, so a saved game is
  self-contained and reads like a deck file.
- **Every answer is recorded as an `Answer` move**, the runner's existing
  "a recording can answer anything one way" path, extended to
  `ChooseAction` (by its index, `Reply.indexed`). Priority passes are
  recorded too: an omitted pass would let a later answer at the same
  moment be taken early. `Concede` records `Move.Concede` only when a
  seat concedes. Chance prompts are recorded at the active player's
  moment, which is where `takeAnswer` looks. The interpreter's
  `LookUpCard`, `ReferenceCards` and `ReferenceNames` are not recorded:
  the runner answers them from the registry.
- **Objects are named `Printed name n`**, the n-th live object with that
  card name in creation order, computed on the state the prompt was asked
  in, the same function `resolveObject` reads it back with. Players are
  named by their seat label. An object with no card fails the save.
- **A game start replays to its result, or to where the recording
  stopped.** Its run is finished when the game has a result, or when its
  timeline is spent and a prompt other than Concede arrives. The final
  checks read that state.
- **The recording survives Ctrl-C and the end of input** by appending
  through a sink in the base monad (an `IORef` in IO), not a `StateT` the
  throw would unwind.

## Tasks

1. `Start`, `GameStart`, `Entrant` types and codecs; `Scenario.start`;
   the runner stages a game start through `Setup.newGame` and the replay
   stop rule. Test: a hand-written game-start scenario (bears decks, a
   recorded shuffle and mulligan) runs.
2. `ChooseAction` answered by an `Answer` at priority, after the moment's
   leading checks. Test: a board scenario whose `ChooseAction` Answer
   index casts a spell.
3. `Pawl.Play.Record`: an observer that turns each answer into a timed
   `Answer` entry. `Game.run` takes observers. Test: a seeded
   bot-versus-bot game recorded, encoded and decoded through the scenario
   codec, then run by `Scenario.run`, ends with the same result and every
   entry consumed. A human game saved after quitting mid-turn replays to
   the same turn.
4. `pawl play --save FILE`, writing on the result, on quit and on Ctrl-C.
   Smoke-test with `pawl scenario`.

## Review Focus

1. A shuffle recorded with `Printed` names resolves to the same order on
   replay (creation order is deterministic).
2. Two prompts at one moment taken in recorded order (priority passes and
   casts within a step).
3. A partial game stops where it was saved, not at the next default answer.
4. A save naming an ability or token object fails loudly, not silently.
