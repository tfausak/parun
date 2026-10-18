module Pawl.Codec.CopyDomainSpec where

import qualified Pawl.Codec.CopyDomain as CopyDomain
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.CopyDomain as CopyDomain
import qualified Pawl.Types.ExiledPile as ExiledPile
import qualified Pawl.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.CopyDomain" $ do
  Spec.it s "InZone (Superior Spider-Man)" $
    Common.assertCodec s CopyDomain.codec (CopyDomain.InZone Zone.Graveyard) " {\"type\":\"InZone\",\"value\":{\"type\":\"Graveyard\"}} "
  Spec.it s "InPile (Dinosaur Headdress)" $
    Common.assertCodec s CopyDomain.codec (CopyDomain.InPile ExiledPile.CraftMaterials) " {\"type\":\"InPile\",\"value\":{\"type\":\"CraftMaterials\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CopyDomain.codec
