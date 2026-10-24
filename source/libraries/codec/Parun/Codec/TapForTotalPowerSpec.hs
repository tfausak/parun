module Parun.Codec.TapForTotalPowerSpec where

import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.TapForTotalPower as TapForTotalPower
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.TapForTotalPower as TapForTotalPower

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (TapForTotalPower.TapForTotalPower Keyword.Keyword)
codec = TapForTotalPower.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TapForTotalPower" $ do
  -- CR 702.122a: crew 6. The 6 is a THRESHOLD on an aggregate, not a count -- the key name is where that differs from Sacrifice.
  Spec.it s "MkTapForTotalPower" $
    Common.assertCodec
      s
      codec
      ( TapForTotalPower.MkTapForTotalPower
          { TapForTotalPower.totalPower = 6,
            TapForTotalPower.whichPermanents = Filter.HasCardType CardType.Creature
          }
      )
      " {\"totalPower\":6,\"whichPermanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
