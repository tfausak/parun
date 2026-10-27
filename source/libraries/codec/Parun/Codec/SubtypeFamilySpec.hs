module Parun.Codec.SubtypeFamilySpec where

import qualified Parun.Codec.SubtypeFamily as SubtypeFamily
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.SubtypeFamily as SubtypeFamily

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SubtypeFamily" $ do
  Spec.it s "BasicLandType" $
    Common.assertCodec
      s
      SubtypeFamily.codec
      SubtypeFamily.BasicLandType
      " {\"type\":\"BasicLandType\"} "
  Spec.it s "CreatureType" $
    Common.assertCodec
      s
      SubtypeFamily.codec
      SubtypeFamily.CreatureType
      " {\"type\":\"CreatureType\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s SubtypeFamily.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s SubtypeFamily.codec
