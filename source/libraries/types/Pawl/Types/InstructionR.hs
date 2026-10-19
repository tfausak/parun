module Pawl.Types.InstructionR where

import qualified Pawl.Types.ControllerRelation as ControllerRelation
import qualified Pawl.Types.InstructionRewrite as InstructionRewrite
import qualified Pawl.Types.PlayerInstruction as PlayerInstruction

-- | The payload of Pawl.Types.ReplacementEffect's InstructionR arm: which
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
