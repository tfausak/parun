module Parun.Codec.AttackWaiverSpec where

import qualified Parun.Codec.AttackWaiver as AttackWaiver
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackWaiver" $ do
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s AttackWaiver.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s AttackWaiver.codec
