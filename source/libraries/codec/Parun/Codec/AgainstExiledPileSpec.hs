module Parun.Codec.AgainstExiledPileSpec where

import qualified Parun.Codec.AgainstExiledPile as AgainstExiledPile
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AgainstExiledPile as AgainstExiledPile
import qualified Parun.Types.ExiledPile as ExiledPile
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Quantity as Quantity

-- | Instantiated at 'Quantity.Quantity', the only concrete instantiation
-- anywhere: 'Parun.Codec.Quantity' passes its own recursive codec in.
codec :: Codec.Codec (AgainstExiledPile.AgainstExiledPile Quantity.Quantity)
codec = AgainstExiledPile.codec Quantity.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AgainstExiledPile" $ do
  Spec.it s "MkAgainstExiledPile" $
    Common.assertCodec
      s
      codec
      AgainstExiledPile.MkAgainstExiledPile {AgainstExiledPile.pile = ExiledPile.CraftMaterials, AgainstExiledPile.quantity = Quantity.Measure Measure.Power}
      " {\"pile\":{\"type\":\"CraftMaterials\"},\"quantity\":{\"type\":\"Measure\",\"value\":{\"type\":\"Power\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
