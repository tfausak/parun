module Parun.Types.LaterPayment where

import qualified Data.Sequence as Seq
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.Keyword as Keyword

-- | CR 116.2c: "for this long, you may pay this; if you do, this happens", an
-- action a resolution leaves its controller (Guardian Angel). Parametric in the
-- effect for Parun.Types.PreventNextDamage's reason.
data LaterPayment effect = MkLaterPayment
  { duration :: Duration.Duration,
    cost :: Cost.Cost Keyword.Keyword,
    -- | What each payment does, without the stack (CR 116.1).
    effects :: Seq.Seq effect
  }
  deriving (Eq, Ord, Show)
