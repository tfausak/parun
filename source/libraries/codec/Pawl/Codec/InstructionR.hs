{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.InstructionR where

import qualified Pawl.Codec.ControllerRelation as ControllerRelation
import qualified Pawl.Codec.InstructionRewrite as InstructionRewrite
import qualified Pawl.Codec.PlayerInstruction as PlayerInstruction
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.InstructionR as InstructionR

codec :: Codec.Codec InstructionR.InstructionR
codec = Fields.object $ do
  instruction <- Fields.required "instruction" PlayerInstruction.codec InstructionR.instruction
  whose <- Fields.required "whose" ControllerRelation.codec InstructionR.whose
  rewrite <- Fields.required "rewrite" InstructionRewrite.codec InstructionR.rewrite
  pure
    InstructionR.MkInstructionR
      { InstructionR.instruction = instruction,
        InstructionR.whose = whose,
        InstructionR.rewrite = rewrite
      }
