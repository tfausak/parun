module Parun.Types.Amass where

import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Subtype as Subtype

-- | The payload of Parun.Types.Effect's Amass arm: CR 701.47a's two printed
-- variables, "amass [subtype] N".
--
-- The subtype is a printed WORD, so CR 612.1 reaches it and
-- Parun.Engine.Projection.Rewrite.rewriteEffect swaps it; the Army type beside it is the
-- rulebook's and appears nowhere here. CR 701.47d's older amass without a subtype
-- has Oracle errata reading "amass Zombies N", so every printing writes one.
--
-- N is a Quantity rather than a Natural: Summons of Saruman
-- prints "amass Orcs X" and Saruman, the White Hand "amass Orcs X, where X is that
-- spell's mana value", so the count is an expression over game state.
data Amass = MkAmass
  { quantity :: Quantity.Quantity,
    subtype :: Subtype.Subtype,
    -- | CR 701.47c: the Army the amassing player chose, bound for a later effect
    -- of the same resolution to name -- Surrounded by Orcs' "where X is the
    -- amassed Army's power". Absent for every amass nothing looks back at.
    --
    -- Bound whether or not the Army received counters, which is rule 701.47c's
    -- own sentence, and bound for the ONE amassing player: rule 701.47a's
    -- instruction is the resolving controller's alone, so there is no group here
    -- as there is on a Mill.
    slot :: Maybe SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
