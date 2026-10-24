module Parun.Types.InstructionR where

import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.InstructionRewrite as InstructionRewrite
import qualified Parun.Types.PlayerInstruction as PlayerInstruction

-- | The payload of Parun.Types.ReplacementEffect's InstructionR arm: which
-- instruction it intercepts, whose (CR 109.5), and what happens instead (CR
-- 614.1a).
--
-- A bare ControllerRelation and nothing else to narrow by: each of these
-- instructions concerns the player it names and has no source, amount or
-- destination -- CR 705.2's last sentence says so outright of a flip. A row that
-- needs more is its own arm: DrawCountR's threshold, AssembleR's permanent.
data InstructionR = MkInstructionR
  { instruction :: PlayerInstruction.PlayerInstruction,
    whose :: ControllerRelation.ControllerRelation,
    rewrite :: InstructionRewrite.InstructionRewrite
  }
  deriving (Eq, Ord, Show)
