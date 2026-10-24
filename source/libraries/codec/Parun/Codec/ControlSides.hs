module Parun.Codec.ControlSides where

import qualified Parun.Codec.ControlSlots as ControlSlots
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ControlSides as ControlSides

codec :: Codec.Codec ControlSides.ControlSides
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "WithinSlot" SlotName.codec ControlSides.WithinSlot (\x -> case x of ControlSides.WithinSlot y -> Just y; _ -> Nothing),
      Arm.payload "WithSource" SlotName.codec ControlSides.WithSource (\x -> case x of ControlSides.WithSource y -> Just y; _ -> Nothing),
      Arm.payload "BetweenSlots" ControlSlots.codec ControlSides.BetweenSlots (\x -> case x of ControlSides.BetweenSlots y -> Just y; _ -> Nothing)
    ]

tagOf :: ControlSides.ControlSides -> String
tagOf x = case x of
  ControlSides.WithinSlot {} -> "WithinSlot"
  ControlSides.WithSource {} -> "WithSource"
  ControlSides.BetweenSlots {} -> "BetweenSlots"
