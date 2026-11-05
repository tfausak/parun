module Parun.Types.Discrepancy where

import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.TapState as TapState

-- | Where a stretch of the event log, replayed over the state it began on,
-- fails to give the state it ended on (Parun.Engine.Ledger).
data Discrepancy
  = -- | A logged event that changed nothing: a status the object already had,
    -- or an amount of 0 (CR 603.2e, 603.2g).
    MkIdleEvent GameEvent.GameEvent
  | -- | A permanent's tapped status, as the log replays it, then as it is.
    MkTapState ObjectId.ObjectId TapState.TapState TapState.TapState
  | -- | A player's life total, as the log replays it, then as it is (CR 119.3).
    MkLife PlayerId.PlayerId Integer Integer
  deriving (Eq, Ord, Show)
