module Parun.Codec.TimesSpec where

import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.Times as Times
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Times as Times

-- | Instantiated at 'Quantity.Quantity', Parun.Codec.QuotientSpec's shape and for
-- its reason: 'Parun.Codec.Quantity' passes its own recursive codec in.
codec :: Codec.Codec (Times.Times Quantity.Quantity)
codec = Times.codec Quantity.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Times" $ do
  -- CR 107.1: Blessed Reversal's 3 times a count. The inner value is a whole Quantity, so the recursion has to survive the trip.
  Spec.it s "MkTimes" $
    Common.assertCodec
      s
      codec
      ( Times.MkTimes
          { Times.factor = 3,
            Times.quantity = Quantity.Measure Measure.Power
          }
      )
      " {\"factor\":3,\"quantity\":{\"type\":\"Measure\",\"value\":{\"type\":\"Power\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
