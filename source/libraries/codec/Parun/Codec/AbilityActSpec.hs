module Parun.Codec.AbilityActSpec where

import qualified Parun.Codec.AbilityAct as AbilityAct
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityAct as AbilityAct

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AbilityAct" $ do
  Spec.it s "Activated" $
    Common.assertCodec
      s
      AbilityAct.codec
      AbilityAct.Activated
      " {\"type\":\"Activated\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s AbilityAct.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s AbilityAct.codec
