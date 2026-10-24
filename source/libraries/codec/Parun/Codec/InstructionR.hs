{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.InstructionR where

import qualified Parun.Codec.ControllerRelation as ControllerRelation
import qualified Parun.Codec.InstructionRewrite as InstructionRewrite
import qualified Parun.Codec.PlayerInstruction as PlayerInstruction
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.InstructionR as InstructionR

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
