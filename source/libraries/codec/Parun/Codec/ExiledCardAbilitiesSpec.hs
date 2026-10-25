module Parun.Codec.ExiledCardAbilitiesSpec where

import qualified Parun.Codec.ExiledCardAbilities as ExiledCardAbilities
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActivationRestriction as ActivationRestriction
import qualified Parun.Types.ExiledCardAbilities as ExiledCardAbilities
import qualified Parun.Types.ExiledPile as ExiledPile
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ExiledCardAbilities" $ do
  Spec.it s "with restrictions" $
    Common.assertCodec
      s
      ExiledCardAbilities.codec
      ExiledCardAbilities.MkExiledCardAbilities {ExiledCardAbilities.cards = Filter.IsExiledWithSource ExiledPile.CraftMaterials, ExiledCardAbilities.restrictions = [ActivationRestriction.TimesEachTurn 1]}
      " {\"cards\":{\"type\":\"IsExiledWithSource\",\"value\":{\"type\":\"CraftMaterials\"}},\"restrictions\":[{\"type\":\"TimesEachTurn\",\"value\":1}]} "
  Spec.it s "restrictions default to none" $
    Common.assertCodec
      s
      ExiledCardAbilities.codec
      ExiledCardAbilities.MkExiledCardAbilities {ExiledCardAbilities.cards = Filter.IsExiledWithSource ExiledPile.OwnAbilities, ExiledCardAbilities.restrictions = []}
      " {\"cards\":{\"type\":\"IsExiledWithSource\",\"value\":{\"type\":\"OwnAbilities\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ExiledCardAbilities.codec
