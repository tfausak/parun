module Parun.Codec.CounterGroupingSpec where

import qualified Parun.Codec.CounterGrouping as CounterGrouping
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CounterGrouping as CounterGrouping

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CounterGrouping" $ do
  Spec.it s "EachCounter" $
    Common.assertCodec
      s
      CounterGrouping.codec
      CounterGrouping.EachCounter
      " \"EachCounter\" "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s CounterGrouping.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s CounterGrouping.codec
