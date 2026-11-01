module Parun.Types.EntryTriggering where

-- | How a permanent entering changes the triggering of the abilities it causes
-- to trigger (Parun.Types.EntriesTrigger).
data EntryTriggering
  = -- | CR 603.6a / 613.11 / Hushwing Gryff: the entry doesn't cause them to
    -- trigger.
    NoTrigger
  | -- | CR 603.2d / Yarok, the Desecrated: each triggers an additional time.
    AnAdditionalTime
  deriving (Bounded, Enum, Eq, Ord, Show)
