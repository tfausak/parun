module Parun.Types.ActiveLaterPayment where

import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PreventionRider as PreventionRider
import qualified Parun.Types.Timestamp as Timestamp

-- | CR 116.2c: Parun.Types.LaterPayment as the game remembers it. A payment
-- leaves the row in place: "any time ... for as long as the effect allows it".
data ActiveLaterPayment = MkActiveLaterPayment
  { cost :: Cost.Cost Keyword.Keyword,
    -- | What a payment runs, in the resolution's environment, with CR 109.5's
    -- "you" and the source baked: the spell has since left the stack (CR 400.7).
    payoff :: PreventionRider.PreventionRider,
    -- | The row's identity: Action.MakeLaterPayment names the row by it.
    createdAt :: Timestamp.Timestamp,
    expiry :: Expiry.Expiry
  }
  deriving (Eq, Ord, Show)
