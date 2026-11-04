module Parun.Types.ProhibitedCost where

-- | Which activation costs an activation prohibition reaches (CR 602.5).
data ProhibitedCost
  = -- | Any cost: Arrest's "its activated abilities can't be activated".
    EveryCost
  | -- | A cost with CR 107.5's tap symbol: Serra Bestiary's "its activated
    -- abilities with {T} in their costs".
    WithTapSymbol
  deriving (Bounded, Enum, Eq, Ord, Show)
