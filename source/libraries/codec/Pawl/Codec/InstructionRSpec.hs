module Pawl.Codec.InstructionRSpec where

import qualified Pawl.Codec.InstructionR as InstructionR
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ControllerRelation as ControllerRelation
import qualified Pawl.Types.InstructionR as InstructionR
import qualified Pawl.Types.InstructionRewrite as InstructionRewrite
import qualified Pawl.Types.PlayerInstruction as PlayerInstruction
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.Scaling as Scaling

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.InstructionR" $ do
  -- CR 705.1: Krark's Thumb.
  Spec.it s "MkInstructionR" $
    Common.assertCodec
      s
      InstructionR.codec
      (InstructionR.MkInstructionR PlayerInstruction.FlipCoin (ControllerRelation.Related PlayerRelation.You) (InstructionRewrite.Scaled (Scaling.Multiply 2)))
      " {\"instruction\":{\"type\":\"FlipCoin\"},\"whose\":{\"type\":\"You\"},\"rewrite\":{\"type\":\"Scaled\",\"value\":{\"type\":\"Multiply\",\"value\":2}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s InstructionR.codec
