module Parun.Codec.MeasureSpec where

import qualified Parun.Codec.Measure as Measure
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Measure as Measure

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Measure" $ do
  Spec.it s "ManaValue" $
    Common.assertCodec
      s
      Measure.codec
      Measure.ManaValue
      " {\"type\":\"ManaValue\"} "
  -- Parun.Codec.DamageKindSpec's reason: Arm.enum derives the arm list from the
  -- type, so this is what would catch a constructor the derivation missed or two
  -- that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Measure.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s Measure.codec
