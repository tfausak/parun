module Pawl.Codec.ExiledCardAbilitiesSpec where

import qualified Pawl.Codec.ExiledCardAbilities as ExiledCardAbilities
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ActivationRestriction as ActivationRestriction
import qualified Pawl.Types.ExiledCardAbilities as ExiledCardAbilities
import qualified Pawl.Types.ExiledPile as ExiledPile

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ExiledCardAbilities" $ do
  Spec.it s "with restrictions" $
    Common.assertCodec
      s
      ExiledCardAbilities.codec
      ExiledCardAbilities.MkExiledCardAbilities {ExiledCardAbilities.pile = ExiledPile.CraftMaterials, ExiledCardAbilities.restrictions = [ActivationRestriction.OnlyOnceEachTurn]}
      " {\"pile\":{\"type\":\"CraftMaterials\"},\"restrictions\":[{\"type\":\"OnlyOnceEachTurn\"}]} "
  Spec.it s "restrictions default to none" $
    Common.assertCodec
      s
      ExiledCardAbilities.codec
      ExiledCardAbilities.MkExiledCardAbilities {ExiledCardAbilities.pile = ExiledPile.OwnAbilities, ExiledCardAbilities.restrictions = []}
      " {\"pile\":{\"type\":\"OwnAbilities\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ExiledCardAbilities.codec
