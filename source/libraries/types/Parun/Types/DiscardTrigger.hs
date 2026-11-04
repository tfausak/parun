module Parun.Types.DiscardTrigger where

import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.DiscardSubject as DiscardSubject
import qualified Parun.Types.DiscardWay as DiscardWay

-- | CR 603.2 over CR 701.9a's discard: whose, which way, and per card or per
-- discard event (CR 603.2c).
data DiscardTrigger = MkDiscardTrigger
  { subject :: DiscardSubject.DiscardSubject,
    way :: DiscardWay.DiscardWay,
    batching :: Batching.Batching
  }
  deriving (Eq, Ord, Show)
