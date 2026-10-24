module Parun.Codec.AgainstLastCardExiledWithSpec where

import qualified Parun.Codec.AgainstLastCardExiledWith as AgainstLastCardExiledWith
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AgainstLastCardExiledWith as AgainstLastCardExiledWith
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Quantity as Quantity

-- | Instantiated at 'Quantity.Quantity', the only concrete instantiation
-- anywhere: 'Parun.Codec.Quantity' passes its own recursive codec in.
codec :: Codec.Codec (AgainstLastCardExiledWith.AgainstLastCardExiledWith Quantity.Quantity)
codec = AgainstLastCardExiledWith.codec Quantity.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AgainstLastCardExiledWith" $ do
  -- Which linked card to aim at, then what to read off it.
  Spec.it s "MkAgainstLastCardExiledWith" $
    Common.assertCodec
      s
      codec
      ( AgainstLastCardExiledWith.MkAgainstLastCardExiledWith
          { AgainstLastCardExiledWith.filter = Filter.HasCardType CardType.Creature,
            AgainstLastCardExiledWith.quantity = Quantity.Measure Measure.Power
          }
      )
      " {\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"quantity\":{\"type\":\"Measure\",\"value\":{\"type\":\"Power\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
