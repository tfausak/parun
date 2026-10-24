module Parun.Codec.ControllerRelation where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.ControllerRelation as ControllerRelation

codec :: Codec.Codec ControllerRelation.ControllerRelation
codec =
  Arm.tagged
    tagOf
    ( PlayerRelation.arms ControllerRelation.Related
        <> [ Arm.nullary "EnchantedPlayers" ControllerRelation.EnchantedPlayers,
             Arm.payload "InSlot" SlotName.codec ControllerRelation.InSlot (\x -> case x of ControllerRelation.InSlot y -> Just y; _ -> Nothing),
             Arm.payload "Among" (Common.set PlayerId.codec) ControllerRelation.Among (\x -> case x of ControllerRelation.Among y -> Just y; _ -> Nothing)
           ]
    )

tagOf :: ControllerRelation.ControllerRelation -> String
tagOf x = case x of
  ControllerRelation.Related relation -> PlayerRelation.tag relation
  ControllerRelation.EnchantedPlayers {} -> "EnchantedPlayers"
  ControllerRelation.InSlot {} -> "InSlot"
  ControllerRelation.Among {} -> "Among"
