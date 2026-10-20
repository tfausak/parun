module Pawl.Codec.InstructionRewrite where

import qualified Pawl.Codec.Scaling as Scaling
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.InstructionRewrite as InstructionRewrite

codec :: Codec.Codec InstructionRewrite.InstructionRewrite
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Scaled" Scaling.codec InstructionRewrite.Scaled (\x -> case x of InstructionRewrite.Scaled y -> Just y; _ -> Nothing),
      Arm.nullary "DrawInstead" InstructionRewrite.DrawInstead,
      Arm.nullary "RollD20Instead" InstructionRewrite.RollD20Instead
    ]

tagOf :: InstructionRewrite.InstructionRewrite -> String
tagOf x = case x of
  InstructionRewrite.Scaled {} -> "Scaled"
  InstructionRewrite.DrawInstead -> "DrawInstead"
  InstructionRewrite.RollD20Instead -> "RollD20Instead"
