module Parun.Codec.RoomHalfSpec where

import qualified Parun.Codec.RoomHalf as RoomHalf
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.RoomHalf as RoomHalf

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RoomHalf" $ do
  Spec.it s "LeftHalf" $
    Common.assertCodec
      s
      RoomHalf.codec
      RoomHalf.LeftHalf
      " {\"type\":\"LeftHalf\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s RoomHalf.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s RoomHalf.codec
