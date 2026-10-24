module Parun.Types.NinjutsuVariant where

-- | Which of CR 702.49's two ninjutsu abilities a printing has.
data NinjutsuVariant
  = -- | CR 702.49a: ninjutsu, functioning only from a hand.
    Plain
  | -- | CR 702.49d: commander ninjutsu, functioning from a hand or the command
    -- zone.
    Commander
  deriving (Bounded, Enum, Eq, Ord, Show)
