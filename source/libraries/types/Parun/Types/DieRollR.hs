module Parun.Types.DieRollR where

import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.DieRollRewrite as DieRollRewrite

-- | The payload of Parun.Types.ReplacementEffect's DieRollR arm: whose die rolls
-- are intercepted (CR 706.1 / 614.1a), and what happens instead.
--
-- A bare ControllerRelation beside the rewrite rather than a pattern RECORD,
-- Parun.Types.InstructionR's shape and for its reason: the roller is the only seat
-- rule 706.1's instruction concerns, and the rest of the roll -- the die's size
-- and the count -- belongs to the instruction rather than to anything a row here
-- would narrow by. Not the die's size either: Pixie Guide's sentence says "one
-- or more dice" and names no dN, and Pokey, the Scallywagg's "a d20" is part of
-- its rewrite's own meaning (DieRollRewrite.FlipCoinInstead), whose "heads is
-- 20" presupposes the die. The record appears when a card needs one.
data DieRollR = MkDieRollR
  { whose :: ControllerRelation.ControllerRelation,
    rewrite :: DieRollRewrite.DieRollRewrite
  }
  deriving (Eq, Ord, Show)
