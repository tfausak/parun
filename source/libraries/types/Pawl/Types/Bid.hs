module Pawl.Types.Bid where

import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.SlotName as SlotName

-- | The payload of Pawl.Types.Effect's Bid arm (Illicit Auction): CR 109.5's
-- "you" opens at a bid, then each player in turn order may top the high bid
-- until it stands, and the outcome is bound for the instructions after it.
data Bid = MkBid
  { -- | The bid "you start the bidding with".
    opening :: Quantity.Quantity,
    -- | Where the high bid is bound, as a number.
    highBid :: SlotName.SlotName,
    -- | Where the high bidder is bound, as a player.
    highBidder :: SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
