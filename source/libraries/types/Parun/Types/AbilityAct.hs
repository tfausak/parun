module Parun.Types.AbilityAct where

-- | Which happening to an ability a Parun.Types.Quantity.TimesThisTurn counts.
data AbilityAct
  = -- | CR 602.2: it was activated -- Dragon Whelp's "if this ability has been
    -- activated four or more times this turn".
    Activated
  | -- | CR 608.2n: it resolved -- Ashling the Pilgrim's "if this is the third
    -- time this ability has resolved this turn".
    Resolved
  deriving (Bounded, Enum, Eq, Ord, Show)
