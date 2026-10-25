module Parun.Codec.TargetChooser where

import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.TargetChooser as TargetChooser

-- | Every arm is spelled as Parun.Codec.PlayerRef spells its own of the same
-- name, so a card writes one wire shape for "a player named by relation or by
-- slot" wherever it appears.
codec :: Codec.Codec TargetChooser.TargetChooser
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Relative" PlayerRelation.codec TargetChooser.Relative (\x -> case x of TargetChooser.Relative y -> Just y; _ -> Nothing),
      Arm.payload "InSlot" SlotName.codec TargetChooser.InSlot (\x -> case x of TargetChooser.InSlot y -> Just y; _ -> Nothing),
      Arm.payload "ControllerOfBound" SlotName.codec TargetChooser.ControllerOfBound (\x -> case x of TargetChooser.ControllerOfBound y -> Just y; _ -> Nothing)
    ]

tagOf :: TargetChooser.TargetChooser -> String
tagOf x = case x of
  TargetChooser.Relative {} -> "Relative"
  TargetChooser.InSlot {} -> "InSlot"
  TargetChooser.ControllerOfBound {} -> "ControllerOfBound"
