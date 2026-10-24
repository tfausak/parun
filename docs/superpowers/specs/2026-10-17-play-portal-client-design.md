# Playing Portal through a text client (#5182)

## Intent

Build something you can play before building out more of the card pool. The
finish line is two people playing a whole game at one terminal through `parun
play`, and the saved game then replaying clean under `parun scenario`. Any
expressible deck counts: forty Grizzly Bears and twenty Forests is a win.
Portal theme decks are a stretch goal. Playing finds what tests don't, starting
with whether the prompts and per-player views give a human enough to decide.

The client and the scenario runner are one thing: a scenario is a game whose
answers are scripted and whose results are checked.

## Goals

- `parun play DECK DECK`, a hot-seat text client for plain two-player Magic.
- One driver with swappable deciders: scenario timeline, human, seeded random
  bot.
- A line protocol (one JSON object per line) that is the only thing a client
  ever reads: the deciding player's redacted view, plus the pending prompt.
- A played game saved as a scenario file that `parun scenario` replays.
- Stretch: the Portal set expressible in the pool, and its theme decks as
  deck files. Missing capabilities are filed as ordinary issues and never
  block this one.

## Non-goals (for this issue)

- Modes other than plain two-player: Commander, Two-Headed Giant, multiplayer.
- Stops, auto-pass, undo, layout, colours, deck building, networking,
  anything graphical, a server, WASM, the search bot, a second set.
- A cryptographically secure generator.

## Anti-goals

- **Closing the door on later modes.** Setup and the command line take a mode
  and a list of seats, even though only two seats and the plain mode are
  accepted. Nothing in the driver or protocol may assume exactly two players
  or one player per team.
- **The client making a choice for a player.** In this version the client
  answers nothing on a player's behalf, not even priority passes. Later stops
  and auto-pass are client-side answers the player has opted into, so the
  engine still asks at every point and needs no change for them.
- **A client that reads `GameState`.** Everything the renderer shows comes
  from a decoded protocol line. If the renderer needs something the protocol
  doesn't carry, that is a protocol gap, and every future client would hit it
  too.
- **Making the generator part of a file format.** Saved games store outcomes,
  never a seed.

## Constraints

- No new non-boot dependency, `random` included. The owner chose this on
  2026-10-17, reversing #10's earlier call for `random`.
- The usual CLAUDE.md rules: the rules core never cases on an effect's
  identity, the engine never makes a player's choice, and work lands one PR
  per unit.

## What already exists (derived 2026-10-17 at `origin/main` 09a11bb91)

- `Parun.Engine.Engine.runGameAsked` takes a callback, `forall r. Asked r -> m
  r`. That callback is the decider seam. `Parun.Scenario.run` already answers
  through it (`answerPrompt`), stepping `Engine.runStep` from a staged board.
- `Engine.runMatch` and `playFrom` play a whole game from a matchup of
  `(PlayerId, Deck)` pairs. `Setup.newGame` builds libraries, shuffles and
  handles mulligans. The starting player is the head of the matchup.
- `Asked` carries the whole, unredacted `GameState`. `Engine.Visibility.sees`
  and `witnessed` answer what a player may see, but nothing yet builds a
  redacted view. The visibility spec
  (`2026-10-11-per-player-visibility-design.md`, unit 7) sketches one: an
  allowlist `PlayerView`, fresh view-level handles per incarnation and per
  shuffle, and a per-player log.
- Randomness is a prompt. `Shuffle`, `RandomFirstPlayer`, `RandomObject`,
  `RandomCard`, `RandomPlayer`, `RollDie`, `RandomDepth` and `FlipCoin` are
  `Prompt` constructors, and `Scenario.Prompt.deciderOf` answers `Nothing` for
  each. `Replay.defaultAnswer` answers `Shuffle` with the identity, so no
  library is ever really shuffled today.
- `Scenario.Prompt.deciderOf` says which seat answers a prompt.
  `Scenario.Reply.shapeOf` gives every prompt's answer shape in the scenario
  vocabulary.
- `Engine.Replay.record` and `replay` keep a positional `Response`
  transcript. There is no JSON codec for `Response`, `Prompt` or `Action`.
- `Parun.DeckList.parse` reads `N Name` deck text through a `Registry`.
- `Parun.Executable.main` dispatches `schema`, `deck`, `ingest`, `scenario`,
  `bench` and `test`.

## Decided

These are the owner's decisions, as made:

- **Plain two-player only for now**, with the other modes kept possible (see
  the anti-goals).
- **What's on screen at a decision:** a board summary, then the deciding
  player's hand, then a numbered list of options. The player types a number.
  A prompt that isn't a priority decision follows the same pattern: show the
  context, list the options, pick by number, or several numbers for a
  multi-pick.
- **Players, decks and settings** come from command-line options or are asked
  for at startup.
- **No stops in the first version.** Every priority point is asked. Stops and
  auto-pass "when nothing interesting is offered" come later, as client-side
  answers.
- **One process.** `parun play` runs the engine and the text client together.
  The client reads only decoded protocol lines: each value is encoded to JSON
  and decoded back before the renderer sees it. A `--json` mode exposing the
  raw lines on stdin/stdout is wanted as good hygiene, though not strictly
  needed.
- **Randomness:**
  - Chance prompts are answered by a small hand-rolled generator, SplitMix64,
    tested against its published reference outputs. It offers only a uniform
    integer below n, using rejection sampling, and a Fisher–Yates shuffle.
  - It is seeded from `--seed`, or from the clock when no seed is given.
  - Saved games record outcomes (each shuffle's order, each die or coin
    result), so replaying needs no generator, and the generator can be swapped
    without breaking any saved game.
  - A secure generator is a later concern for networked play against an
    untrusted opponent.

## My calls (the owner may override any of them)

- **Hot-seat hiding.** When the deciding seat changes, the client clears the
  screen and waits on "pass to <player>, press Enter" before drawing the next
  view.
- **Starting player.** CR 103.1 lets the players use "any mutually agreeable
  method" to decide who chooses the first player. That happens before the
  engine starts, so it is the client's job. The client asks at setup, or
  takes `--first`, then orders the matchup to match. It is not an engine
  prompt.
- **Saved-game shape.** The scenario format gains a second kind of start: a
  *game start*, made of seats, decks and a mode, used in place of a *board*.
  It replays setup itself, so shuffles and mulligans are reproduced. The
  timeline records every answer in the existing scenario vocabulary, chance
  outcomes included. Checks attach by `When`, as they do today. The goal is
  that a human can read and edit the file and add an expectation; a
  positional `Response` dump fails that test.
- **Unfamiliar prompts.** The first cut renders the prompts a Portal game
  actually reaches: action choice, attackers, blockers, targets, discard,
  mulligan, mana payment and trigger order. Every other prompt falls back to
  a generic renderer, which lists the offered options or, for a free-form
  shape such as a name or a number, takes typed input checked against
  `Reply.shapeOf`.
- **What a seat sees after the handoff.** The view carries a per-player log of
  what that seat witnessed (`Visibility.witnessed`) since it last decided:
  spells cast, blocks, revealed cards. Without it a human can't decide well.
  This puts the visibility spec's per-player log in unit 2.
- **Unit 2 settles the visibility spec's unit 7 sketch** (allowlist
  `PlayerView`, fresh handles per incarnation and per shuffle). Approving this
  doc approves that; no separate sign-off.
- **Saved games are self-contained.** The game-start form inlines each seat's
  card list rather than pointing at a deck file, so editing a deck file never
  breaks a saved game. Boards already inline their cards.
- **"Replays clean"** means every recorded answer is consumed in order, no
  desync, and the same result. Recording writes no automatic checks; the
  player adds expectations by hand.
- **Conceding and quitting.** Concession (CR 104.3a) is a typed command
  available at any prompt, not a numbered option at every priority point.
  Ctrl-C or end of input saves the partial game, which replays as far as it
  goes.
- **Theme-deck source.** MTGJSON's Portal deck lists are the source of truth.
- **The bot** picks uniformly among the options the prompt itself offers,
  layered over `Replay.defaultAnswer` the way `Engine.Script` overlays are. It
  never reads the game state.

## Units, in order

Each unit is one PR. This spec is committed with unit 1.

1. **Driver, answerers, observers.** Split `Parun.Scenario`'s loop so that the
   timeline is one answerer among others (`Parun.Types.Decider` already names
   CR 723.5's seat, so the type is `Answerer`). Every existing scenario passes
   unchanged. The timeline's checks stay inside its answerer: they share a
   moment's queue with its moves, and a check behind a refused move becomes
   due only once the answerer takes that move.
2. **Redacted view and the line protocol.** Build `PlayerView` (unit 7 of the
   visibility spec), JSON codecs for the view, the prompt and the answer, and
   the line framing. A test proves a hidden card's identity never appears in
   the other seat's lines.
3. **`parun play`.** Setup (seats, decks via `DeckList`, mode, starting
   player), the human decider, the renderer, hot-seat hiding and `--json`.
4. **Seeded chance and the random bot.** SplitMix64, chance prompts answered
   from it, and the random decider for either seat. This is #10's slice A,
   minus `random`.
5. **Save as scenario.** The game-start form and recording a played game into
   it. Proven by a seeded bot-versus-bot game that saves, then replays clean.
6. **Stretch: Portal census.** Compare the Portal set list against the pool,
   add every card that's already expressible, and file a capability issue for
   each gap, naming its Portal card. Independent of the others; can run in
   parallel.
7. **Stretch: Portal theme decks** as deck files, for whichever decks are
   fully expressible.

Done when two humans finish a game through `parun play`, with any expressible
decks, and the saved game replays clean under `parun scenario`. Units 6 and 7
don't gate it.

## Left to the builder

- Module and sublibrary placement (`docs/adding-a-module.md`). The likely
  shape is a `play` library between `scenario`/`registry` and `executable`,
  with `deciderOf` moved to wherever both the scenario runner and the client
  can reach it.
- The JSON shapes of the view and the prompt, and how a view refers to
  objects.
- The exact board-summary layout.
- How the game-start form names objects in its timeline: labels assigned at
  setup, names with zones, or view handles.
- Whether unit 4 lands before unit 3. A bot makes unit 3's tests easier to
  write.
