module Parun.Types.BecomesTapState where

import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.TapState as TapState

-- | CR 701.26a / 701.26b: which permanent's transition into which tapped status
-- fires the ability -- City of Brass's "whenever this land becomes tapped",
-- Mesmeric Orb's "whenever a permanent becomes untapped".
data BecomesTapState = MkBecomesTapState
  { status :: TapState.TapState,
    actor :: ActingPermanent.ActingPermanent
  }
  deriving (Eq, Ord, Show)
