module Parun.Codec.DrawCountRewriteSpec where

import qualified Parun.Codec.DrawCountRewrite as DrawCountRewrite
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DrawCountRewrite as DrawCountRewrite

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DrawCountRewrite" $ do
  -- CR 121.2a: Alms Collector.
  Spec.it s "EachDrawOne" $
    Common.assertCodec
      s
      DrawCountRewrite.codec
      DrawCountRewrite.EachDrawOne
      " {\"type\":\"EachDrawOne\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DrawCountRewrite.codec
