module Pawl.Codec.InstructionRewriteSpec where

import qualified Pawl.Codec.InstructionRewrite as InstructionRewrite
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.InstructionRewrite as InstructionRewrite
import qualified Pawl.Types.Scaling as Scaling

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.InstructionRewrite" $ do
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
  Spec.it s "has a schema" $ Common.assertHasSchema s InstructionRewrite.codec
