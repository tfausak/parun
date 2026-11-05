module Parun.Types.CrewRole where

import qualified Parun.Types.TriggerFrequency as TriggerFrequency

-- | CR 702.122: which side of a crewing the bearer of a trigger is.
data CrewRole
  = -- | CR 702.122e: the Vehicle, crewed as its crew ability resolves (Mobilizer
    -- Mech); the frequency is Mighty Servant of Leuk-o's "for the first time
    -- each turn".
    Vehicle TriggerFrequency.TriggerFrequency
  | -- | CR 702.122b: a creature tapped to pay a Vehicle's crew cost (Gearshift
    -- Ace).
    Crewer
  deriving (Eq, Ord, Show)
