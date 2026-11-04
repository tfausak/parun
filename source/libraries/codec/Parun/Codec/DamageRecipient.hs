module Parun.Codec.DamageRecipient where

import qualified Parun.Codec.CardType as CardType
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.DamageRecipient as DamageRecipient

codec :: Codec.Codec DamageRecipient.DamageRecipient
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Player" PlayerRelation.codec DamageRecipient.Player (\x -> case x of DamageRecipient.Player y -> Just y; _ -> Nothing),
      Arm.payload "Permanent" CardType.codec DamageRecipient.Permanent (\x -> case x of DamageRecipient.Permanent y -> Just y; _ -> Nothing)
    ]

tagOf :: DamageRecipient.DamageRecipient -> String
tagOf x = case x of
  DamageRecipient.Player {} -> "Player"
  DamageRecipient.Permanent {} -> "Permanent"
