module Parun.Codec.MonarchTarget where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.MonarchTarget as MonarchTarget

-- | The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
codec :: Codec.Codec MonarchTarget.MonarchTarget
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "TheController" MonarchTarget.TheController,
      Arm.nullary "ControllerOfSource" MonarchTarget.ControllerOfSource,
      Arm.payload "InSlot" SlotName.codec MonarchTarget.InSlot (\x -> case x of MonarchTarget.InSlot y -> Just y; _ -> Nothing)
    ]

tagOf :: MonarchTarget.MonarchTarget -> String
tagOf x = case x of
  MonarchTarget.TheController {} -> "TheController"
  MonarchTarget.ControllerOfSource {} -> "ControllerOfSource"
  MonarchTarget.InSlot {} -> "InSlot"
