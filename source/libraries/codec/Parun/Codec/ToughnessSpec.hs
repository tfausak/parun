module Parun.Codec.ToughnessSpec where

import qualified Parun.Codec.Toughness as Toughness
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Toughness as Toughness

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Toughness" $ do
  Spec.it s "MkToughness delegates to Quantity" $
    Common.assertCodec
      s
      Toughness.codec
      (Toughness.MkToughness (Quantity.Literal 2))
      " {\"type\":\"Literal\",\"value\":2} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Toughness.codec
