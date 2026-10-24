module Parun.Types.ShownComponent where

import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.Facing as Facing
import qualified Parun.Types.MergeComponent as MergeComponent

-- | CR 730.2i: one component of a merged permanent and the face it shows, which
-- each double-faced component keeps for itself.
data ShownComponent = MkShownComponent
  { component :: MergeComponent.MergeComponent,
    -- | CR 712.8d / 712.8e: the face this component shows, as Object.face names
    -- an unmerged permanent's; Nothing is its front.
    face :: Maybe CardName.CardName,
    -- | CR 730.2e: this component's own status. The topmost component's is the
    -- permanent's, which Object.facing carries.
    facing :: Facing.Facing
  }
  deriving (Eq, Ord, Show)
