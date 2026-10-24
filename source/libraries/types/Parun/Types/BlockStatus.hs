module Parun.Types.BlockStatus where

-- | CR 509.1h: the status the declaration of blockers confers on an attacking
-- creature. Before blockers are declared it has neither, so "unblocked" is not
-- "not blocked".
data BlockStatus
  = -- | CR 509.1h: one or more creatures were declared blocking it, or an
    -- effect said it becomes blocked.
    Blocked
  | -- | CR 509.1h, CR 508.4d: blockers have been declared and none were
    -- declared for it.
    Unblocked
  deriving (Bounded, Enum, Eq, Ord, Show)
