module Pawl.Types.AbilityView where

import qualified Pawl.Types.ObjectId as ObjectId

-- | CR 113.7a / 602.2a: an ability on the stack as one seat sees it, by the
-- object it came from where the seat may know that object, and Nothing for an
-- inherent trigger (CR 725.2) or a source in a zone hidden from the seat.
newtype AbilityView = MkAbilityView
  { source :: Maybe ObjectId.ObjectId
  }
  deriving (Eq, Show)
