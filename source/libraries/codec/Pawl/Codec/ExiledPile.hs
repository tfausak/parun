module Pawl.Codec.ExiledPile where

import qualified Pawl.Codec.AbilityName as AbilityName
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.ExiledPile as ExiledPile

codec :: Codec.Codec ExiledPile.ExiledPile
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "OwnAbilities" ExiledPile.OwnAbilities,
      Arm.payload "OfAbility" AbilityName.codec ExiledPile.OfAbility (\x -> case x of ExiledPile.OfAbility y -> Just y; _ -> Nothing),
      Arm.nullary "AsItEntered" ExiledPile.AsItEntered,
      Arm.nullary "CraftMaterials" ExiledPile.CraftMaterials
    ]

tagOf :: ExiledPile.ExiledPile -> String
tagOf x = case x of
  ExiledPile.OwnAbilities -> "OwnAbilities"
  ExiledPile.OfAbility {} -> "OfAbility"
  ExiledPile.AsItEntered -> "AsItEntered"
  ExiledPile.CraftMaterials -> "CraftMaterials"
