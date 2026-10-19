module Pawl.Codec.AgainstExiledPileSpec where

import qualified Pawl.Codec.AgainstExiledPile as AgainstExiledPile
import qualified Pawl.Codec.Quantity as Quantity
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.AgainstExiledPile as AgainstExiledPile
import qualified Pawl.Types.ExiledPile as ExiledPile
import qualified Pawl.Types.Measure as Measure
import qualified Pawl.Types.Quantity as Quantity

-- | Instantiated at 'Quantity.Quantity', the only concrete instantiation
-- anywhere: 'Pawl.Codec.Quantity' passes its own recursive codec in.
codec :: Codec.Codec (AgainstExiledPile.AgainstExiledPile Quantity.Quantity)
codec = AgainstExiledPile.codec Quantity.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.AgainstExiledPile" $ do
  Spec.it s "MkAgainstExiledPile" $
    Common.assertCodec
      s
      codec
      AgainstExiledPile.MkAgainstExiledPile {AgainstExiledPile.pile = ExiledPile.CraftMaterials, AgainstExiledPile.quantity = Quantity.Measure Measure.Power}
      " {\"pile\":{\"type\":\"CraftMaterials\"},\"quantity\":{\"type\":\"Measure\",\"value\":{\"type\":\"Power\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
