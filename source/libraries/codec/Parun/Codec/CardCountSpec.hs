module Parun.Codec.CardCountSpec where

import qualified Parun.Codec.CardCount as CardCount
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardCount as CardCount

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CardCount" $ do
  Spec.it s "Exactly" $
    Common.assertCodec
      s
      CardCount.codec
      (CardCount.Exactly 2)
      " {\"type\":\"Exactly\",\"value\":2} "
  Spec.it s "Every" $
    Common.assertCodec
      s
      CardCount.codec
      CardCount.Every
      " {\"type\":\"Every\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s CardCount.codec
