module Parun.Types.NextDamageOutcome where

-- | What a "the next time a source of your choice would deal damage" effect does
-- to that one instance of damage.
data NextDamageOutcome
  = -- | CR 615.8: the instance is prevented (Deflecting Palm).
    Prevented
  | -- | CR 614.1a: the instance still happens, and the effect's source deals that
    -- much to the damage source's controller as well (Eye for an Eye).
    AlsoToSourceController
  deriving (Bounded, Enum, Eq, Ord, Show)
