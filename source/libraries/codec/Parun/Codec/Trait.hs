module Parun.Codec.Trait where

import qualified Parun.Codec.CardType as CardType
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Trait as Trait

-- | A bare CardType compares every card type.
codec :: Codec.Codec Trait.Trait
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Color" Trait.Color,
      Arm.nullary "Name" Trait.Name,
      Arm.nullary "Owner" Trait.Owner,
      Arm.nullary "Controller" Trait.Controller,
      Arm.nullary "Sector" Trait.Sector,
      Arm.nullary "CreatureType" Trait.CreatureType,
      Arm.optionalPayload "CardType" (Common.set CardType.codec) Trait.CardType (\x -> case x of Trait.CardType among -> Just among; _ -> Nothing)
    ]

tagOf :: Trait.Trait -> String
tagOf x = case x of
  Trait.Color -> "Color"
  Trait.Name -> "Name"
  Trait.Owner -> "Owner"
  Trait.Controller -> "Controller"
  Trait.Sector -> "Sector"
  Trait.CreatureType -> "CreatureType"
  Trait.CardType {} -> "CardType"
