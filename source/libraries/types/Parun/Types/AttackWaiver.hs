module Parun.Types.AttackWaiver where

-- | The rule barring an attack that a Parun.Types.AttackPermission lifts.
data AttackWaiver
  = -- | CR 702.3b: "as though it didn't have defender".
    Defender
  | -- | CR 302.6's attack half: "as though it had haste". Its {T} half stands.
    SummoningSickness
  deriving (Bounded, Enum, Eq, Ord, Show)
