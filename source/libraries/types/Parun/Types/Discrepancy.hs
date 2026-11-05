module Parun.Types.Discrepancy where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.TapState as TapState

-- | Where a stretch of the event log, replayed over the state it began on,
-- fails to give the state it ended on (Parun.Engine.Ledger).
data Discrepancy
  = -- | A logged event that changed nothing: a status the object already had,
    -- an amount of 0, a count that did not move, or an attachment to the
    -- host it already had or from one it did not have (CR 603.2e, 603.2g).
    MkIdleEvent GameEvent.GameEvent
  | -- | A permanent's tapped status, as the log replays it, then as it is.
    MkTapState ObjectId.ObjectId TapState.TapState TapState.TapState
  | -- | A player's life total, as the log replays it, then as it is (CR 119.3).
    MkLife PlayerId.PlayerId Integer Integer
  | -- | An object's count of one counter kind, as the log replays it, then as
    -- the board shows it: to the next event on that kind, or the later state
    -- (CR 122.1).
    MkCounters ObjectId.ObjectId (CounterKind.CounterKind Keyword.Keyword) Natural.Natural Natural.Natural
  | -- | What a permanent is attached to, as the log replays it, then as it is
    -- (CR 701.3a, 701.3d).
    MkAttachment ObjectId.ObjectId (Maybe Recipient.Recipient) (Maybe Recipient.Recipient)
  deriving (Eq, Ord, Show)
