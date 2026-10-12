module Pawl.Types.ShownComponent where

import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.MergeComponent as MergeComponent

-- | CR 730.2i: one component of a merged permanent and the face it shows, which
-- each double-faced component keeps for itself.
data ShownComponent = MkShownComponent
  { component :: MergeComponent.MergeComponent,
    -- | CR 712.8d / 712.8e: the face this component shows, as Object.face names
    -- an unmerged permanent's; Nothing is its front.
    face :: Maybe CardName.CardName
  }
  deriving (Eq, Ord, Show)
