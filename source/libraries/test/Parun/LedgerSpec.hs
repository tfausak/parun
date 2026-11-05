-- Covers: Parun.Engine.Ledger, the replay audit every scenario runs between
-- priority prompts (Parun.Scenario's `made`), over hand-built state pairs: a
-- write with no record, a record of no change, a counter chain broken between
-- two records, and the clean cases, a shared team life total (CR 810.9) and a
-- turn handoff among them.
module Parun.LedgerSpec where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import Numeric.Natural (Natural)
import qualified Parun.Engine.Event as Event
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Ledger as Ledger
import qualified Parun.Engine.Setup as Setup
import qualified Parun.Registry as Registry
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.CounterCause as CounterCause
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CountersPlaced as CountersPlaced
import qualified Parun.Types.Discrepancy as Discrepancy
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.GameSettings as GameSettings
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.LifeChange as LifeChange
import qualified Parun.Types.Object as Object
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Player as Player
import qualified Parun.Types.TapState as TapState

-- A write that skips its funnel: the status set with nothing logged.
setTapped :: ObjectId.ObjectId -> TapState.TapState -> GameState.GameState -> GameState.GameState
setTapped oid status gs = gs {GameState.objects = Map.adjust (\o -> o {Object.tapped = status}) oid (GameState.objects gs)}

-- A counter write that skips its funnel: the kind's count set with nothing
-- logged.
setCounters :: ObjectId.ObjectId -> CounterKind.CounterKind Keyword.Keyword -> Natural -> GameState.GameState -> GameState.GameState
setCounters oid kind n gs = gs {GameState.objects = Map.adjust (\o -> o {Object.counters = Map.insert kind n (Object.counters o)}) oid (GameState.objects gs)}

-- alice and bob on one team sharing a life total (CR 810.4).
sharedLife :: GameState.GameState
sharedLife =
  let gs = S.inTeams [[S.alice, S.bob]] (Setup.emptyGame S.bothPlayers)
   in gs {GameState.settings = (GameState.settings gs) {GameSettings.sharedTeamLife = True}}

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "Ledger" $ do
  Spec.it s "CR 701.26a: a tap through its funnel is accounted for" $ do
    plains <- S.printingOf s registry "Plains"
    let (land, before) = S.addPermanent plains S.alice (S.landsInPlay plains 0)
        after = S.runPure S.identityAnswer before (Event.tap land)
    Spec.assertEqWith s "no discrepancy" (Ledger.discrepancies before after) []
  Spec.it s "CR 701.26a: a tap with no event is named" $ do
    plains <- S.printingOf s registry "Plains"
    let (land, before) = S.addPermanent plains S.alice (S.landsInPlay plains 0)
        after = setTapped land TapState.Tapped before
    Spec.assertEqWith s "the unlogged tap" (Ledger.discrepancies before after) [Discrepancy.MkTapState land TapState.Untapped TapState.Tapped]
  Spec.it s "CR 603.2e: an event on an already tapped permanent is named" $ do
    plains <- S.printingOf s registry "Plains"
    let (land, untapped) = S.addPermanent plains S.alice (S.landsInPlay plains 0)
        before = setTapped land TapState.Tapped untapped
        after = Event.recordEvent (GameEvent.BecameTapped land) before
    Spec.assertEqWith s "the idle tap" (Ledger.discrepancies before after) [Discrepancy.MkIdleEvent (GameEvent.BecameTapped land)]
  Spec.it s "CR 701.26b: an untap through its funnel, then a tap, is accounted for" $ do
    plains <- S.printingOf s registry "Plains"
    let (land, untapped) = S.addPermanent plains S.alice (S.landsInPlay plains 0)
        before = setTapped land TapState.Tapped untapped
        after = S.runPure S.identityAnswer before (Event.untap land >> Event.tap land)
    Spec.assertEqWith s "no discrepancy" (Ledger.discrepancies before after) []
  Spec.it s "CR 119.3: a life change through its funnel is accounted for" $ do
    plains <- S.printingOf s registry "Plains"
    let before = S.landsInPlay plains 0
        after = S.runPure S.identityAnswer before (Event.changeLife S.alice (-3) >> Event.changeLife S.bob 2)
    Spec.assertEqWith s "no discrepancy" (Ledger.discrepancies before after) []
  Spec.it s "CR 119.3: a life change with no event is named" $ do
    plains <- S.printingOf s registry "Plains"
    let before = S.landsInPlay plains 0
        after = Game.adjustLife S.alice (-3) before
    Spec.assertEqWith s "the unlogged loss" (Ledger.discrepancies before after) [Discrepancy.MkLife S.alice 20 17]
  Spec.it s "CR 119.9: a record of 0 life is named" $ do
    plains <- S.printingOf s registry "Plains"
    let before = S.landsInPlay plains 0
        none = GameEvent.LifeGained LifeChange.MkLifeChange {LifeChange.player = S.alice, LifeChange.amount = 0, LifeChange.first = True}
        after = Event.recordEvent none before
    Spec.assertEqWith s "the idle gain" (Ledger.discrepancies before after) [Discrepancy.MkIdleEvent none]
  Spec.it s "CR 810.9: one member's loss moves the team's shared total" $ do
    let after = S.runPure S.identityAnswer sharedLife (Event.changeLife S.alice (-4))
    Spec.assertEqWith s "the teammate's total moved too" (S.lifeOf S.bob after) (Just 16)
    Spec.assertEqWith s "no discrepancy" (Ledger.discrepancies sharedLife after) []
  Spec.it s "CR 810.9: a loss written to one member alone is named at the teammate" $ do
    let lost = LifeChange.MkLifeChange {LifeChange.player = S.alice, LifeChange.amount = 4, LifeChange.first = True}
        alone = sharedLife {GameState.players = Map.adjust (\p -> p {Player.life = Player.life p - 4}) S.alice (GameState.players sharedLife)}
        after = Event.recordEvent (GameEvent.LifeLost lost) alone
    Spec.assertEqWith s "the teammate named" (Ledger.discrepancies sharedLife after) [Discrepancy.MkLife S.bob 16 20]
  Spec.it s "CR 122.6: a placement and a removal through their funnels are accounted for" $ do
    plains <- S.printingOf s registry "Plains"
    let (land, before) = S.addPermanent plains S.alice (S.landsInPlay plains 0)
        after = S.runPure S.identityAnswer before (Event.putCounters (CounterCause.ByEffect S.alice) land CounterKind.PlusOnePlusOne 3 >> Event.removeCounters land CounterKind.PlusOnePlusOne 3)
    Spec.assertEqWith s "no discrepancy" (Ledger.discrepancies before after) []
  Spec.it s "CR 122.1: counters with no event are named" $ do
    plains <- S.printingOf s registry "Plains"
    let (land, before) = S.addPermanent plains S.alice (S.landsInPlay plains 0)
        after = setCounters land CounterKind.PlusOnePlusOne 2 before
    Spec.assertEqWith s "the unlogged counters" (Ledger.discrepancies before after) [Discrepancy.MkCounters land CounterKind.PlusOnePlusOne 0 2]
  Spec.it s "CR 122.1: a write between two records is named at the later one" $ do
    plains <- S.printingOf s registry "Plains"
    let (land, before) = S.addPermanent plains S.alice (S.landsInPlay plains 0)
        after = S.runPure S.identityAnswer before (State.modify' (setCounters land CounterKind.PlusOnePlusOne 2) >> Event.putCounters (CounterCause.ByEffect S.alice) land CounterKind.PlusOnePlusOne 1)
    Spec.assertEqWith s "the count the placement found" (Ledger.discrepancies before after) [Discrepancy.MkCounters land CounterKind.PlusOnePlusOne 0 2]
  Spec.it s "CR 603.2g: a placement that left the count where it was is named" $ do
    plains <- S.printingOf s registry "Plains"
    let (land, before) = S.addPermanent plains S.alice (S.landsInPlay plains 0)
        none = GameEvent.CountersPut CountersPlaced.MkCountersPlaced {CountersPlaced.putter = S.alice, CountersPlaced.object = land, CountersPlaced.kind = CounterKind.PlusOnePlusOne, CountersPlaced.before = 0, CountersPlaced.after = 0}
        after = Event.recordEvent none before
    Spec.assertEqWith s "the idle placement" (Ledger.discrepancies before after) [Discrepancy.MkIdleEvent none]
  Spec.it s "CR 122.1: a kind stored at 0 reads as absent" $ do
    plains <- S.printingOf s registry "Plains"
    let (land, before) = S.addPermanent plains S.alice (S.landsInPlay plains 0)
        after = setCounters land CounterKind.Loyalty 0 before
    Spec.assertEqWith s "no discrepancy" (Ledger.discrepancies before after) []
  Spec.it s "CR 608.2i: the log carried across a turn handoff is read from both halves" $ do
    plains <- S.printingOf s registry "Plains"
    let (land, before) = S.addPermanent plains S.alice (S.landsInPlay plains 0)
        tapped = S.runPure S.identityAnswer before (Event.tap land)
        handedOff = tapped {GameState.turnNumber = GameState.turnNumber tapped + 1, GameState.eventsLastTurn = GameState.events tapped, GameState.events = Seq.empty}
        untapped = setTapped land TapState.Untapped handedOff
    Spec.assertEqWith s "the tap last turn is read" (Ledger.discrepancies before handedOff) []
    Spec.assertEqWith s "an unlogged untap this turn is named" (Ledger.discrepancies before untapped) [Discrepancy.MkTapState land TapState.Tapped TapState.Untapped]
  Spec.it s "CR 727.1: states from different games are not compared" $ do
    plains <- S.printingOf s registry "Plains"
    let (land, before) = S.addPermanent plains S.alice (S.landsInPlay plains 0)
        after = (setTapped land TapState.Tapped before) {GameState.gameNumber = GameState.gameNumber before + 1}
    Spec.assertEqWith s "no comparison" (Ledger.discrepancies before after) []
