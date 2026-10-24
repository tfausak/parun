module Parun.Types.Moved where

import qualified Data.Sequence as Seq
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Parun.Types.ZoneChange as ZoneChange

-- | CR 400.7's zone change, plus the moving object's characteristics as of the
-- move. The characteristics are stamped because CR 608.2h's last-known
-- information is gone by the time a trigger reads them.
data Moved = MkMoved
  { change :: ZoneChange.ZoneChange,
    characteristics :: ProjectedCharacteristics.ProjectedCharacteristics,
    -- | CR 712.21: "If a melded permanent leaves the battlefield, one permanent
    -- leaves the battlefield and two cards are put into the appropriate zone."
    -- One departure, several arrivals -- so `change` above names the departure
    -- and the FIRST arrival, and this names every arrival after it.
    --
    -- Empty for every move but a melded permanent's departure, which is what
    -- makes `change` alone the whole answer for an ordinary one; `moved` below
    -- is the constructor that says so. CR 730.3 restates the rule for a merged
    -- permanent, so the field is the shared carrier rather than meld's.
    --
    -- A FIELD ON THE EVENT and not the only announcement: rule 712.21's first
    -- clause makes the DEPARTURE one event, so a "whenever a creature dies"
    -- ability must see exactly one of these, while each arrival after the
    -- leading one also gets a GameEvent.CardArrived of its own so that rule's
    -- Example fires a card-arrival ability twice. What the field itself is for
    -- is CR 712.21c -- "if an effect can find the new object that a melded
    -- permanent becomes as it leaves the battlefield, it finds both cards" --
    -- which Parun.Engine.Event.Binding.eventBindings reads through `arrivals` and binds
    -- as one group off the single departure event.
    --
    -- A Seq and not a Set: the order is the one the cards arrived in, which is
    -- CR 712.21a's arrangement where the owner was asked for one
    -- (Parun.Engine.Event.arrangeComponents) and the order they melded in
    -- otherwise.
    otherArrivals :: Seq.Seq ObjectId.ObjectId,
    -- | CR 701.42a / CR 712.14c: the departure-side twin of `otherArrivals`. A
    -- meld puts several cards onto the battlefield as one permanent, so `change`
    -- names the first card that left and this names every one after it, in
    -- Parun.Engine.Event.meldable's order. Empty for every other move.
    otherDepartures :: Seq.Seq ObjectId.ObjectId,
    -- | CR 608.2n / 608.3: True only for a spell's own resolution move -- an
    -- instant or sorcery into its owner's graveyard, or a permanent spell onto
    -- the battlefield.
    --
    -- The one thing that tells those moves apart from a COUNTERED spell's (CR
    -- 701.6a), a FIZZLED one's (CR 608.2b) and a countered card put onto the
    -- battlefield instead (Desertion), which share their zone pairs. Written by
    -- Parun.Engine.Event.changeZoneResolvingReturning and Parun.Engine.Stack's
    -- CarryOver.Carried move; read by
    -- TriggerCondition.SelfPutIntoGraveyardDuringResolution and by CR 400.7d's
    -- look-backs at the cast (Quantity.WasCastFrom, Count's
    -- becamePermanents).
    duringResolution :: Bool,
    -- | CR 603.10a: all players could see the object as it left -- face up in
    -- a public zone (CR 400.2), revealed (CR 701.20a, 708.9), or in a hand or
    -- atop a library shown to everyone. False for a card face down in exile.
    -- Parun.LeavesTriggerSpec's "CR 603.10a an exiled Seeker looks back at" and
    -- "CR 603.10a the same token does not see a foretold card" cases are the
    -- proof.
    revealed :: Bool,
    -- | CR 400.2: all players could see the object as it arrived -- face up in
    -- a public zone, or shown to everyone. False for a card put onto the
    -- battlefield or into exile face down (CR 406.3, 708.2).
    seenArriving :: Bool,
    -- | CR 609.1: the controller of the spell or ability whose effect made this
    -- move, read off GameState.causing as the move happens. Nothing for a move
    -- no effect made: a cost (CR 118.12, 601.2h), a state-based action, a
    -- turn-based action, a cast. See docs/decisions.md, "What a spell or
    -- ability causes".
    causedBy :: Maybe PlayerId.PlayerId
  }
  deriving (Eq, Ord, Show)

-- | The ordinary move: one departure, one arrival, no CR 712.21 split. Every
-- construction site but Parun.Engine.Event's zone-change funnel uses this.
moved :: ZoneChange.ZoneChange -> ProjectedCharacteristics.ProjectedCharacteristics -> Moved
moved zc pc = MkMoved {change = zc, characteristics = pc, otherArrivals = Seq.empty, otherDepartures = Seq.empty, duringResolution = False, revealed = False, seenArriving = False, causedBy = Nothing}

-- | CR 400.7e's "the new object it became", in the plural CR 712.21c asks for:
-- every incarnation this move minted, first arrival first. A singleton for every
-- move but a melded permanent's departure.
arrivals :: Moved -> Seq.Seq ObjectId.ObjectId
arrivals m = ZoneChange.object (change m) Seq.<| otherArrivals m

-- | CR 400.7's departed incarnations in the plural a meld asks for (CR 701.42a):
-- every id that left its zone in this move, first departure first. A singleton
-- for every move but a meld's entry.
departures :: Moved -> Seq.Seq ObjectId.ObjectId
departures m = ZoneChange.departed (change m) Seq.<| otherDepartures m
