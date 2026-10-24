module Parun.Codec.ZoneScope where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.PlayerScope as PlayerScope
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ZoneScope as ZoneScope

-- | Tagged, in the shape Parun.Codec.PlayerRef already uses for the same
-- readings: a nested PlayerScope, or a slot name. The two slot-named arms take
-- the same payload and are told apart by the tag alone, as PlayerRef's InSlot
-- and ControllerOfBound are. The wire format is unchanged by the conversion to a
-- bundle; what it adds is the schema.
codec :: Codec.Codec ZoneScope.ZoneScope
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Scoped" PlayerScope.codec ZoneScope.Scoped (\x -> case x of ZoneScope.Scoped y -> Just y; _ -> Nothing),
      Arm.payload "InSlot" SlotName.codec ZoneScope.InSlot (\x -> case x of ZoneScope.InSlot y -> Just y; _ -> Nothing),
      Arm.payload "ControllerOfBound" SlotName.codec ZoneScope.ControllerOfBound (\x -> case x of ZoneScope.ControllerOfBound y -> Just y; _ -> Nothing),
      Arm.payload "BoundPlayer" PlayerId.codec ZoneScope.BoundPlayer (\x -> case x of ZoneScope.BoundPlayer y -> Just y; _ -> Nothing)
    ]

tagOf :: ZoneScope.ZoneScope -> String
tagOf x = case x of
  ZoneScope.Scoped {} -> "Scoped"
  ZoneScope.InSlot {} -> "InSlot"
  ZoneScope.ControllerOfBound {} -> "ControllerOfBound"
  ZoneScope.BoundPlayer {} -> "BoundPlayer"
