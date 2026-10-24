module Parun.Codec.CostDirectionSpec where

import qualified Parun.Codec.CostDirection as CostDirection
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CostDirection as CostDirection

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CostDirection" $ do
  Spec.it s "Less" $
    Common.assertCodec
      s
      CostDirection.codec
      CostDirection.Less
      " {\"type\":\"Less\"} "
  Spec.it s "More" $
    Common.assertCodec
      s
      CostDirection.codec
      CostDirection.More
      " {\"type\":\"More\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s CostDirection.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s CostDirection.codec
