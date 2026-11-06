module Parun.Types.AmassKind where

import qualified Parun.Types.Subtype as Subtype

-- | Which of the two "create one if you control none, choose one, put N counters
-- on it" keyword actions a Parun.Types.Amass performs.
data AmassKind
  = -- | CR 701.47a: "amass [subtype] N", +1\/+1 counters on an Army creature.
    Army Subtype.Subtype
  | -- | CR 701.71a: "empower Jace N", loyalty counters on a Jace planeswalker token.
    EmpowerJace
  deriving (Eq, Ord, Show)
