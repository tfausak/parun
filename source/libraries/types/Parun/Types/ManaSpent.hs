module Parun.Types.ManaSpent where

import qualified Parun.Types.ManaType as ManaType

-- | The payload of Parun.Types.Quantity's ManaSpent arm: which of the mana spent
-- to pay for the object it counts (Parun.Types.Object.manaSpent).
data ManaSpent
  = -- | CR 202.1a: all of it -- rule 702.191a's "the amount of mana spent to
    -- cast that spell".
    Total
  | -- | CR 107.3 / 601.2h: the mana of that type spent on X -- Soul Burn's "the
    -- amount of {B} spent on X" (Parun.Types.Object.manaSpentOnX).
    OfTypeOnX ManaType.ManaType
  deriving (Eq, Ord, Show)
