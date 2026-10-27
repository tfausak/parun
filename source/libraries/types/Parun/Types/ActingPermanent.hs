module Parun.Types.ActingPermanent where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | Which object a Parun.Types.TriggerCondition watches: PermanentActs'
-- actor, or the object a damage condition's damage was dealt by or to -- a
-- permanent, or a spell as the source (CR 120.2).
data ActingPermanent
  = -- | CR 603.2: the bearer itself ("when this creature evolves"), compared by
    -- id, so a bearer that has since left is still answered about the event.
    Self
  | -- | CR 603.2 read by a bystander ("whenever a creature you control
    -- explores", "whenever a creature is dealt damage"), the Filter judging the
    -- object as it stood at the event or last was.
    Matching (Filter.Filter Keyword.Keyword)
  deriving (Eq, Ord, Show)
