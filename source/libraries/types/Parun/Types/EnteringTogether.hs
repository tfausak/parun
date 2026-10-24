module Parun.Types.EnteringTogether where

import qualified Data.Sequence as Seq
import qualified Parun.Types.ObjectId as ObjectId

-- | CR 613.7m: the objects one CR 608.2f action has put onto the battlefield so
-- far, whose relative timestamps are ordered once the action ends
-- (Parun.Engine.Event.together).
data EnteringTogether = MkEnteringTogether
  { -- | The arrivals Parun.Engine.Restamp.settle was handed, in arrival order.
    arrivals :: Seq.Seq ObjectId.ObjectId,
    -- | The tokens (CR 111.2) and conjured cards among them, whose entry
    -- events wait for that order.
    minted :: Seq.Seq ObjectId.ObjectId
  }
  deriving (Eq, Ord, Show)

-- | Nothing has entered yet.
empty :: EnteringTogether
empty = MkEnteringTogether Seq.empty Seq.empty
