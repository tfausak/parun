# Per-player visibility (#1412)

## The problem

Pawl never decides what one player may see. Every answerer is handed the whole
`GameState` (`Pawl.Types.Asked`), and nothing in the engine asks "may this
player see this card?" except `Pawl.Engine.Exile.mayLookAt`, for CR 406.3's
face-down exile alone. A family of cards waits on that question: lasting
reveals (#1408, #3045), standing looks and revealed hands (#3237, #3035),
private looks (#4391), secret choices (#4452, #3497) and targets in hidden
zones (#559). Nor can a test say what a player sees: `Pawl.ActivateSpec`
asserts on the raw log and says so.

## Two halves

1. **The rules half** (units 1–5, this spec): a relation the engine owns and
   reads, saying what each player may see *now* (CR 400.2, 406.3, 701.20,
   708.5, 723.4), plus an audience on the logged shows and secret choices. This
   is what the cards need.
2. **The honest half** (units 6–7, sketched only): a redacted `PlayerView`
   handed to answerers, so an untrusted client or a search bot cannot cheat.
   This is #1412 proper once narrowed, and #10's slices C and D.

The rules half models *permission*, not *knowledge*. What a player remembers
from an earlier look (a top card known after a scry, a card seen before a
shuffle) is no CR concept; "P has seen X" is derivable from the audience log,
and remembered knowledge is left to a client or a bot's belief model.

Prior art (`_scratch/phase`, `argentum-engine`, Forge, XMage, netrunner) agrees
on the eventual shape: one visibility source of truth shared by client masking
and the bot, and a view type built as an ALLOWLIST, since phase's
clone-then-redact denylist leaked each time a field was added.

## Units

Landed in order; this spec is committed with unit 1. Each later unit is an
existing issue, re-pointed to block on unit 1's.

1. **The relation and the `Seers` check.** New issue.
2. **Lasting reveals.** #1408 (anchor), #3045.
3. **Standing grants.** #3237, #3035.
4. **Private looks and the audience log.** #4391.
5. **Hidden choices.** #4452 (with #3717), #3497.
6. **Hidden-zone targets.** #559. Sketch.
7. **Redacted views.** #1412, narrowed. Sketch.

## Unit 1: the relation

### `Pawl.Types.Visibility`

```haskell
data Visibility = Visible | Obscured
instance Semigroup Visibility -- Visible wins
instance Monoid Visibility    -- mempty = Obscured
```

A type rather than `Bool`, because every unit adds a SOURCE of visibility and
the sources join: `sees` is an `mconcat` of terms, each unit adding one. Two
constructors only: how an obscured object is shown (a CR 708.2 face-down 2/2,
or a card back) follows from zone and facing, which the state already holds,
and no reader yet needs the reason a card is visible.

### `Pawl.Engine.Visibility.sees`

```haskell
sees :: PlayerId -> ObjectId -> GameState -> Visibility
```

Pure and derived; it adds no state. The base term, on the current incarnation's
zone and `Object.facing`:

| Case | Visible to | CR |
|---|---|---|
| Public zone, face up | everyone | 400.2 |
| Hand | its owner | 400.2 |
| Library | nobody | 400.2 |
| Face-down permanent or spell | its controller | 708.5 |
| Face-down exile | whom `Exile.mayLookAt` names | 406.3 |
| Any other face-down card | nobody | 708.5 |

The other zones that hold hidden decks (`attractionDecks`, `planarDecks`,
`schemeDecks`) answer as a library does; check each against its CR section
when writing the arm.

**CR 723.4.** For an object in the game, a player sees what any player they
control sees: `sees p o = foldMap (\q -> base q o) (p : controlledBy p)`, with
`controlledBy` read off `GameState.control` through `Pawl.Engine.Decide`'s
`effective` row, the same reading `deciderFor` makes. A card outside the game
(`InAnotherGame`, `Player.outsideTheGame`) takes the base term only.

`Exile.mayLookAt` stays, as the face-down-exile arm's implementation, and
its callers (`Exile.mayChoose`, `Pawl.Engine.Target`, `Pawl.Engine.Cast`)
keep their reads: each asks CR 406.4's choosing question over exiled cards,
where `sees` agrees by construction. Moving them onto `sees` would also hide
an opponent's hand from target offering, which is unit 6's change.

### The `Seers` view

A new `Pawl.Types.View` constructor, checked through the existing `View`
check, with no new `Check` constructor:

```json
{ "of": "Seers", "object": "$morph", "is": ["alice"] }
```

It lists every seat to which `sees` answers `Visible`, in seat order, so a
single assertion covers who does and who does not. Codec, schema and the
scenario README's views paragraph gain it.

### Proving

A scenario over a morph creature in the pool (Ainok Tracker, say) and
Mindslaver:

- cast face down: `Seers` is its caster alone, on the stack and on the
  battlefield (CR 708.5);
- while alice controls bob's turn via Mindslaver, a face-down creature of
  bob's has `Seers` alice and bob (CR 723.4);
- turned face up: both seats;
- a card in bob's hand: bob alone; bob's library top: nobody.

Mutations: dropping the 708.5 arm's controller test, and dropping the
`controlledBy` fold, must each redden a `Seers` assertion, named in the PR.

### Elision upkeep

Every `#1412` site (grep the bare number) is re-read. `Object.facing`'s and
`Game.faceOf`'s CR 708.5 notes are rewritten: the relation now exists, and what
stays unimplemented is that an answerer is still handed the printing (unit 7).
`Asked`'s note keeps citing #1412. A site that unit 1 makes true is rewritten
in the same PR.

### Concurrent work

A branch for #3348 (Opposition Agent, CR 723 control of a library search) is
in flight. If it lands first, its controlled-search reading is a second
723.4 producer for the `Seers` proof; if unit 1 lands first, #3348 gains a
`Seers` assertion.

## Unit 2: lasting reveals (#1408, #3045)

`Object.revealed :: Maybe RevealWindow`, written by `Object.new` as `Nothing`
and reset by `Object.newIncarnation`, so a zone change ends a reveal (CR 400.7)
with no code.

```haskell
data RevealWindow
  = WhileOnStack ObjectId -- 701.20a: cost, hidden-zone activation, a trigger it caused
  | UntilFirstTurn       -- 103.6b
```

`sees` adds a term: `Visible` to all while the window is live (that stack
object is still on the stack; the first turn has not begun). No sweep clears
it, so nothing can forget to. Not `Expiry`: these are rules-imposed reveal
durations, not CR 611 continuous effects. Writers: `Event.reveal` where the
reveal is a cost, an activation from a hidden zone (CR 602.2a) or a trigger's
cause; `Mulligan.handWindow` for 103.6b. CR 701.20a's "as long as necessary to
complete the effect" stays the momentary `Revealed` event.

Proof: Ninja of the Deep Hours (both seats while ninjutsu is on the stack, its
owner alone before), Thunderous Wrath (both seats while the miracle trigger is
on the stack), Serum Powder or Chancellor of the Forge (both seats until turn
1 begins).

#2568's inverse (a card hidden until a cost is paid) waits on Jester's Scepter
and its two other blockers; the window type gains an obscuring arm then.

## Unit 3: standing grants (#3237, #3035)

One `PlayerEffect` arm, per "Parameters, not siblings":

```haskell
Shows { cards :: HandOrTop, to :: Audience } -- Audience = Everyone | ThatPlayer
```

| Card | `cards` | `to` |
|---|---|---|
| Sen Triplets: plays with their hand revealed | Hand | Everyone |
| Garruk's Horde, Future Sight: top card revealed | Top | Everyone |
| Fblthp, Johann: may look at the top card any time (CR 401.5) | Top | ThatPlayer |

`sees` reads the active player effects, already re-derived, and adds `Visible`
for the audience; CR 400.2's zone classification never changes. The omitted
clauses in those cards' JSON are restored. CR 401.5's "the new top card isn't
revealed until the spell becomes cast" is elided under a new issue.

`Visible` wins and no term can veto, so the hand-revealed term must itself
exclude a card CR 121.8 keeps face down in hand (`Game.keptFaceDown`).

Proof: Sen Triplets (a card in bob's hand gains alice in `Seers`), Fblthp
(bob's top card: bob alone), Garruk's Horde (everyone).

## Unit 4: private looks and the audience log (#4391)

`LookAt` gains `looker :: PlayerRef`. A new `GameEvent.Looked { card,
characteristics, audience :: Set PlayerId }` records the look, its audience
resolved WHEN RECORDED: the looker, and whoever controlled the looker then (CR
723.4). Stored, not derived, since what counts is visibility at the time of
the look. `Revealed`'s audience is everyone, implicitly.

`Visibility.witnessed :: PlayerId -> LoggedEvent -> Visibility` reads it. A
`Witnessed` view lists the cards shown to a seat this turn by looks and
reveals, in order: `{ "of": "Witnessed", "player": "alice", "is": [...] }`.

Enhanced Surveillance's optional extra look becomes a prompt; the proof is
that alice's `Witnessed` holds the extra cards iff she accepted. The miracle
look (CR 121.9) and `Pawl.MassEffectSpec`'s look move onto `Looked`. Other
events' payloads (a library-to-hand `Moved` carries the card) stay unredacted
until unit 7.

## Unit 5: hidden choices (#4452, #3497)

A choice attached to an object inherits that object's `sees`. Hidden agenda's
name (CR 702.106b) is noted with a face-down conspiracy in the command zone,
so the work is one more row in `sees`, CR 315.7's: a face-down conspiracy is
visible to its controller alone (unit 1 leaves it under "nobody", no card in
the pool reaching it).

A free-standing secret choice is logged as an event the chooser alone
witnesses until every choice is made, then one reveal event makes them all
public; the prompt to a later chooser omits the earlier choices. Secret council
(Truth or Consequences, a vote between two words) is the producer, added to the
pool by unit 5b; Mob Verdict follows once #3717's player votes land.

## Unit 6 (sketch): hidden-zone targets (#559)

A card in a hand or library offered as a candidate must be offered blind, by
position or as "a card in bob's hand". It is the first prompt built from
`sees` rather than the raw state, which makes it the bridge into unit 7.

## Unit 7 (sketch): redacted views (#1412)

Tracked in #10 since 2026-10-12, when #1412 closed with units 1–5 landed: the
view has no consumer until #10's clients exist.

An allowlist `PlayerView` type, built from `sees` and `witnessed`, never from
a copy of `GameState`, so every new field is a compile-time decision. Fresh
view-level handles per incarnation and per shuffle, with the old-to-new link
given only to players entitled to it, since a stable `ObjectId` lets a tracker
follow a card through a shuffle. A per-player log. Prompts redacted, and
`Asked` carrying the view. The RNG and `DecisionLog` stay server-side. Then
#10's codecs (slice B), determinizing bot (C) and server (D).

## Issue bookkeeping

- File unit 1's issue; link #1408, #3045, #3237, #3035, #4391, #4452, #3497
  and #559 as blocked by it, replacing their #1412 links.
- Comment on #1412 narrowing it to unit 7; it stays blocked by #10.
- Copy units 2–5's sections into their issues as dated comments.
