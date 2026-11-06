module Parun.Types.Unblocking where

-- | What removing a blocking creature from combat leaves of the blocked status
-- of the attackers it was blocking (CR 509.1h).
data Unblocking
  = -- | CR 509.1h: they remain blocked (Labyrinth of Skophos).
    StayBlocked
  | -- | CR 509.1h: those that had become blocked by only that creature this
    -- combat become unblocked (False Orders).
    SoleBlockedUnblocked
  deriving (Bounded, Enum, Eq, Ord, Show)
