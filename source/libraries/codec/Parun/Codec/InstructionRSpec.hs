module Parun.Codec.InstructionRSpec where

import qualified Parun.Codec.InstructionR as InstructionR
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.InstructionR as InstructionR
import qualified Parun.Types.InstructionRewrite as InstructionRewrite
import qualified Parun.Types.PlayerInstruction as PlayerInstruction
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Scaling as Scaling

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.InstructionR" $ do
  -- CR 705.1: Krark's Thumb.
  Spec.it s "MkInstructionR" $
    Common.assertCodec
      s
      InstructionR.codec
      (InstructionR.MkInstructionR PlayerInstruction.FlipCoin (ControllerRelation.Related PlayerRelation.You) (InstructionRewrite.Scaled (Scaling.Multiply 2)))
      " {\"instruction\":{\"type\":\"FlipCoin\"},\"whose\":{\"type\":\"You\"},\"rewrite\":{\"type\":\"Scaled\",\"value\":{\"type\":\"Multiply\",\"value\":2}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s InstructionR.codec
