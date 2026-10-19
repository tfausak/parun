module Pawl.Codec.ExiledPileSpec where

import qualified Data.Text as Text
import qualified Pawl.Codec.ExiledPile as ExiledPile
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.AbilityName as AbilityName
import qualified Pawl.Types.ExiledPile as ExiledPile

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ExiledPile" $ do
  Spec.it s "OwnAbilities" $
    Common.assertCodec s ExiledPile.codec ExiledPile.OwnAbilities " {\"type\":\"OwnAbilities\"} "
  Spec.it s "OfAbility" $
    Common.assertCodec s ExiledPile.codec (ExiledPile.OfAbility (AbilityName.MkAbilityName (Text.pack "warden"))) " {\"type\":\"OfAbility\",\"value\":\"warden\"} "
  Spec.it s "AsItEntered" $
    Common.assertCodec s ExiledPile.codec ExiledPile.AsItEntered " {\"type\":\"AsItEntered\"} "
  Spec.it s "CraftMaterials" $
    Common.assertCodec s ExiledPile.codec ExiledPile.CraftMaterials " {\"type\":\"CraftMaterials\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ExiledPile.codec
