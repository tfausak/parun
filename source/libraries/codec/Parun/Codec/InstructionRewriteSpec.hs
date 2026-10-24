module Parun.Codec.InstructionRewriteSpec where

import qualified Parun.Codec.InstructionRewrite as InstructionRewrite
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.InstructionRewrite as InstructionRewrite
import qualified Parun.Types.Scaling as Scaling

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.InstructionRewrite" $ do
  -- Bruvac the Grandiloquent's "they mill twice that many cards instead".
  Spec.it s "Scaled" $
    Common.assertCodec
      s
      InstructionRewrite.codec
      (InstructionRewrite.Scaled (Scaling.Multiply 2))
      " {\"type\":\"Scaled\",\"value\":{\"type\":\"Multiply\",\"value\":2}} "
  -- Eligeth, Crossroads Augur's "draw that many cards instead".
  Spec.it s "DrawInstead" $
    Common.assertCodec
      s
      InstructionRewrite.codec
      InstructionRewrite.DrawInstead
      " {\"type\":\"DrawInstead\"} "
  -- Pokey, the Scallywagg's "you may instead roll a d20".
  Spec.it s "RollD20Instead" $
    Common.assertCodec
      s
      InstructionRewrite.codec
      InstructionRewrite.RollD20Instead
      " {\"type\":\"RollD20Instead\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s InstructionRewrite.codec
