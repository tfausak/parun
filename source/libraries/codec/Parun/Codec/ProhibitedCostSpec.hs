module Parun.Codec.ProhibitedCostSpec where

import qualified Parun.Codec.ProhibitedCost as ProhibitedCost
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ProhibitedCost" $ do
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s ProhibitedCost.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s ProhibitedCost.codec
