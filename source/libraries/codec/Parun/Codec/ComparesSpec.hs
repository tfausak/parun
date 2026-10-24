module Parun.Codec.ComparesSpec where

import qualified Parun.Codec.Compares as Compares
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Quantity as Quantity

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Compares" $ do
  -- The measured side is 3 and the threshold 5 deliberately: the two are the
  -- same type, so only an asymmetric fixture catches a codec that reads them in
  -- the wrong order. Naming them is what the record buys.
  Spec.it s "MkCompares, asymmetric sides" $
    Common.assertCodec
      s
      Compares.codec
      (Compares.MkCompares (Quantity.Literal 3) Comparison.AtLeast (Quantity.Literal 5))
      " {\"measured\":{\"type\":\"Literal\",\"value\":3},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":5}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Compares.codec
