module Parun.Codec.NumberFloorSpec where

import qualified Parun.Codec.NumberFloor as NumberFloor
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.NumberFloor as NumberFloor.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.NumberFloor" $ do
  Spec.it s "HighBid" $
    Common.assertCodec s NumberFloor.codec NumberFloor.Type.HighBid " {\"type\":\"HighBid\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s NumberFloor.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s NumberFloor.codec
