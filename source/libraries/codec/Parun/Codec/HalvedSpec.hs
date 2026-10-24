module Parun.Codec.HalvedSpec where

import qualified Parun.Codec.Halved as Halved
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Halved as Halved
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Rounding as Rounding

-- | Instantiated at 'Quantity.Quantity', the only concrete instantiation
-- anywhere: 'Parun.Codec.Quantity' passes its own recursive codec in.
codec :: Codec.Codec (Halved.Halved Quantity.Quantity)
codec = Halved.codec Quantity.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Halved" $ do
  -- CR 107.1a: Malignus' half, rounded up. The inner value is a whole Quantity, so the recursion has to survive the trip.
  Spec.it s "MkHalved" $
    Common.assertCodec
      s
      codec
      ( Halved.MkHalved
          { Halved.rounding = Rounding.Up,
            Halved.quantity = Quantity.Measure Measure.Power
          }
      )
      " {\"rounding\":{\"type\":\"Up\"},\"quantity\":{\"type\":\"Measure\",\"value\":{\"type\":\"Power\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
