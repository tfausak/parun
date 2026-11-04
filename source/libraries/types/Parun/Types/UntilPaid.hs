module Parun.Types.UntilPaid where

import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRef as PlayerRef

-- | CR 116.2c's offer as a card prints it: who may pay, and what.
data UntilPaid = MkUntilPaid
  { -- | Relative You for a Licid's "you may pay" (CR 109.5), InSlot for Nafs
    -- Asp's "they". Parun.Engine.Expiry.arm samples it once, as the offer begins.
    payer :: PlayerRef.PlayerRef,
    cost :: Cost.Cost Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
