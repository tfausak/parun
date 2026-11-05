module Parun.Types.BecomesTapState where

import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.TapState as TapState

-- | CR 701.26a / 701.26b: which permanent's transition into which tapped status
-- fires the ability, and per permanent or per tapping (CR 603.2c) -- City of
-- Brass's "whenever this land becomes tapped", Mesmeric Orb's "whenever a
-- permanent becomes untapped", Deeproot Pilgrimage's "whenever one or more
-- nontoken Merfolk you control become tapped".
data BecomesTapState = MkBecomesTapState
  { status :: TapState.TapState,
    actor :: ActingPermanent.ActingPermanent,
    batching :: Batching.Batching
  }
  deriving (Eq, Ord, Show)
