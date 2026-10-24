module Parun.Types.OwnershipChange where

import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PrintingId as PrintingId

-- | CR 108.3 / 407.3: one card whose owner is not the player who began the game
-- owning it -- an object, or one card of a merged or melded one (CR 730.2,
-- 701.42a).
data OwnershipChange = MkOwnershipChange
  { -- | The object that is the card, or that the card is one of.
    object :: ObjectId.ObjectId,
    -- | The card's printing.
    card :: PrintingId.PrintingId,
    -- | CR 108.3: who began the game owning it, or brought it in.
    startingOwner :: PlayerId.PlayerId,
    -- | Who owns it now.
    owner :: PlayerId.PlayerId
  }
  deriving (Eq, Ord, Show)
