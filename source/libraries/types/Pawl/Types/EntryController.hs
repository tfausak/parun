module Pawl.Types.EntryController where

import qualified Pawl.Types.PlayerRef as PlayerRef

-- | Whose control a permanent an effect puts onto the battlefield enters under
-- (CR 110.2a).
data EntryController
  = -- | CR 110.2a: the player the effect instructs to put it there -- the
    -- resolving controller by default (Relative You), Endless Whispers' "that
    -- player puts" and Thieves' Auction's "each player ... puts".
    Instructed PlayerRef.PlayerRef
  | -- | CR 110.2a's "unless the effect states otherwise": each object's owner --
    -- undying's and persist's "under its owner's control".
    Owner
  deriving (Eq, Ord, Show)
