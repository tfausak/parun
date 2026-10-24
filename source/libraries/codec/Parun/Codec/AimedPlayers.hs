module Parun.Codec.AimedPlayers where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.PlayerScope as PlayerScope
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AimedPlayers as AimedPlayers

-- | Tagged, Parun.Codec.ZoneScope's shape: a nested PlayerScope, a slot name, or
-- the baked player.
codec :: Codec.Codec AimedPlayers.AimedPlayers
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Scoped" PlayerScope.codec AimedPlayers.Scoped (\x -> case x of AimedPlayers.Scoped y -> Just y; _ -> Nothing),
      Arm.payload "EachInSlot" SlotName.codec AimedPlayers.EachInSlot (\x -> case x of AimedPlayers.EachInSlot y -> Just y; _ -> Nothing),
      Arm.payload "BoundPlayer" PlayerId.codec AimedPlayers.BoundPlayer (\x -> case x of AimedPlayers.BoundPlayer y -> Just y; _ -> Nothing)
    ]

tagOf :: AimedPlayers.AimedPlayers -> String
tagOf x = case x of
  AimedPlayers.Scoped {} -> "Scoped"
  AimedPlayers.EachInSlot {} -> "EachInSlot"
  AimedPlayers.BoundPlayer {} -> "BoundPlayer"
