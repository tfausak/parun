module Parun.Codec.CostKeywordSpec where

import qualified Parun.Codec.CostKeyword as CostKeyword
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CostKeyword as CostKeyword

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CostKeyword" $ do
  Spec.it s "Scavenge" $
    Common.assertCodec
      s
      CostKeyword.codec
      CostKeyword.Scavenge
      " {\"type\":\"Scavenge\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s CostKeyword.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s CostKeyword.codec
