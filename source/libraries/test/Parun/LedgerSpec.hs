-- Covers: Parun.Engine.Ledger, the replay audit every scenario runs between
-- priority prompts (Parun.Scenario's `made`), over hand-built state pairs: a
-- write with no record, a record of no change, a counter chain broken between
-- two records, and the clean cases, a shared team life total (CR 810.9), a turn
-- handoff and phasing in unattached (CR 702.26j) among them.
module Parun.LedgerSpec where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import Numeric.Natural (Natural)
import qualified Parun.Engine.Event as Event
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Ledger as Ledger
import qualified Parun.Engine.Phasing as Phasing
import qualified Parun.Engine.Setup as Setup
import qualified Parun.Registry as Registry
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.BecameAttached as BecameAttached
import qualified Parun.Types.BecameUnattached as BecameUnattached
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
import qualified Parun.Types.PhasedOut as PhasedOut
import qualified Parun.Types.Player as Player
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.TapState as TapState

-- A write that skips its funnel: the status set with nothing logged.
setTapped :: ObjectId.ObjectId -> TapState.TapState -> GameState.GameState -> GameState.GameState
setTapped oid status gs = gs {GameState.objects = Map.adjust (\o -> o {Object.tapped = status}) oid (GameState.objects gs)}

-- A counter write that skips its funnel: the kind's count set with nothing
-- logged.
setCounters :: ObjectId.ObjectId -> CounterKind.CounterKind Keyword.Keyword -> Natural -> GameState.GameState -> GameState.GameState
setCounters oid kind n gs = gs {GameState.objects = Map.adjust (\o -> o {Object.counters = Map.insert kind n (Object.counters o)}) oid (GameState.objects gs)}

-- An attachment write that skips its funnel: the host set with nothing logged.
setAttached :: ObjectId.ObjectId -> Maybe Recipient.Recipient -> GameState.GameState -> GameState.GameState
setAttached oid host gs = gs {GameState.objects = Map.adjust (\o -> o {Object.attachedTo = host}) oid (GameState.objects gs)}

-- alice's Short Sword and two Grizzly Bears, the Sword unattached.
equipped :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> m (ObjectId.ObjectId, ObjectId.ObjectId, ObjectId.ObjectId, GameState.GameState)
equipped s registry = do
  plains <- S.printingOf s registry "Plains"
  sword <- S.printingOf s registry "Short Sword"
  bears <- S.printingOf s registry "Grizzly Bears"
  let (equipment, gs1) = S.addPermanent sword S.alice (S.landsInPlay plains 0)
      (first, gs2) = S.addPermanent bears S.alice gs1
      (second, gs3) = S.addPermanent bears S.alice gs2
  pure (equipment, first, second, gs3)

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
  Spec.it s "CR 701.3a: an attachment, then a move to another host, through the funnel is accounted for" $ do
    (equipment, first, second, before) <- equipped s registry
    let after = S.runPure S.identityAnswer before (Event.attach equipment (Recipient.ToObject first) >> Event.attach equipment (Recipient.ToObject second))
    Spec.assertEqWith s "moved" (fmap (Recipient.objectOf =<<) (Map.lookup equipment (Ledger.hostsOf after))) (Just (Just second))
    Spec.assertEqWith s "no discrepancy" (Ledger.discrepancies before after) []
  Spec.it s "CR 701.3d: an unattachment through its funnel is accounted for" $ do
    (equipment, first, _, unattached) <- equipped s registry
    let before = S.runPure S.identityAnswer unattached (Event.attach equipment (Recipient.ToObject first))
        after = S.runPure S.identityAnswer before (Event.detach equipment)
    Spec.assertEqWith s "no discrepancy" (Ledger.discrepancies before after) []
  Spec.it s "CR 701.3a: an attachment with no event is named" $ do
    (equipment, first, _, before) <- equipped s registry
    let host = Recipient.ToObject first
        after = setAttached equipment (Just host) before
    Spec.assertEqWith s "the unlogged attachment" (Ledger.discrepancies before after) [Discrepancy.MkAttachment equipment Nothing (Just host)]
  Spec.it s "CR 701.3b: an attachment to the host it already has is named" $ do
    (equipment, first, _, unattached) <- equipped s registry
    let host = Recipient.ToObject first
        before = setAttached equipment (Just host) unattached
        again = GameEvent.BecameAttached BecameAttached.MkBecameAttached {BecameAttached.attachment = equipment, BecameAttached.host = host}
        after = Event.recordEvent again before
    Spec.assertEqWith s "the idle attachment" (Ledger.discrepancies before after) [Discrepancy.MkIdleEvent again]
  Spec.it s "CR 701.3d: an unattachment from a host it does not have is named" $ do
    (equipment, first, second, unattached) <- equipped s registry
    let before = setAttached equipment (Just (Recipient.ToObject first)) unattached
        wrong = GameEvent.BecameUnattached BecameUnattached.MkBecameUnattached {BecameUnattached.attachment = equipment, BecameUnattached.host = Recipient.ToObject second}
        after = setAttached equipment Nothing (Event.recordEvent wrong before)
    Spec.assertEqWith s "the idle unattachment" (Ledger.discrepancies before after) [Discrepancy.MkIdleEvent wrong]
  Spec.it s "CR 702.26j: phasing in unattached is not an unattachment" $ do
    (equipment, first, _, unattached) <- equipped s registry
    let attached = setAttached equipment (Just (Recipient.ToObject first)) unattached
        phased = Phasing.phaseOut (PhasedOut.Directly S.alice) equipment attached
        before = phased {GameState.objects = Map.delete first (GameState.objects phased)}
        after = Phasing.phaseIn S.alice equipment before
    Spec.assertEqWith s "phased in unattached" (fmap Object.attachedTo (Map.lookup equipment (GameState.objects after))) (Just Nothing)
    Spec.assertEqWith s "no discrepancy" (Ledger.discrepancies before after) []
  Spec.it s "CR 608.2i: the log carried across a turn handoff is read from both halves" $ do
    plains <- S.printingOf s registry "Plains"
    let (land, before) = S.addPermanent plains S.alice (S.landsInPlay plains 0)
        tapped = S.runPure S.identityAnswer before (Event.tap land)
        handedOff = tapped {GameState.turnNumber = GameState.turnNumber tapped + 1, GameState.eventsLastTurn = GameState.events tapped, GameState.events = Seq.empty}
        untapped = setTapped land TapState.Untapped handedOff
    Spec.assertEqWith s "the tap last turn is read" (Ledger.discrepancies before handedOff) []
    Spec.assertEqWith s "an unlogged untap this turn is named" (Ledger.discrepancies before untapped) [Discrepancy.MkTapState land TapState.Tapped TapState.Untapped]
  Spec.it s "CR 728.1: states from different games are not compared" $ do
    plains <- S.printingOf s registry "Plains"
    let (land, before) = S.addPermanent plains S.alice (S.landsInPlay plains 0)
        after = (setTapped land TapState.Tapped before) {GameState.gameNumber = GameState.gameNumber before + 1}
    Spec.assertEqWith s "no comparison" (Ledger.discrepancies before after) []
