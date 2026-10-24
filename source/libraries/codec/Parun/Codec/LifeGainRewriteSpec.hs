module Parun.Codec.LifeGainRewriteSpec where

import qualified Parun.Codec.LifeGainRewrite as LifeGainRewrite
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.LifeGainRewrite as LifeGainRewrite
import qualified Parun.Types.Scaling as Scaling

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LifeGainRewrite" $ do
  -- Boon Reflection's "you gain twice that much life instead".
  Spec.it s "Scaled" $
    Common.assertCodec
      s
      LifeGainRewrite.codec
      (LifeGainRewrite.Scaled (Scaling.Multiply 2))
      " {\"type\":\"Scaled\",\"value\":{\"type\":\"Multiply\",\"value\":2}} "
  -- Lich's "draw that many cards instead".
  Spec.it s "DrawInstead" $
    Common.assertCodec
      s
      LifeGainRewrite.codec
      LifeGainRewrite.DrawInstead
      " {\"type\":\"DrawInstead\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LifeGainRewrite.codec
