module Parun.Codec.SlotCount where

import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.TargetCount as TargetCount
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.SlotCount as SlotCount

-- | Tagged, so that CR 601.2c's readings of a slot's count are told apart by
-- the same @type@ key every other union in a card is. The printed range keeps
-- Parun.Codec.TargetCount's own object as its payload.
codec :: Codec.Codec SlotCount.SlotCount
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Printed" TargetCount.codec SlotCount.Printed (\x -> case x of SlotCount.Printed y -> Just y; _ -> Nothing),
      Arm.nullary "AnnouncedX" SlotCount.AnnouncedX,
      Arm.nullary "UpToAnnouncedX" SlotCount.UpToAnnouncedX,
      Arm.payload "UpToComputed" Quantity.codec SlotCount.UpToComputed (\x -> case x of SlotCount.UpToComputed y -> Just y; _ -> Nothing)
    ]

tagOf :: SlotCount.SlotCount -> String
tagOf x = case x of
  SlotCount.Printed {} -> "Printed"
  SlotCount.AnnouncedX {} -> "AnnouncedX"
  SlotCount.UpToAnnouncedX {} -> "UpToAnnouncedX"
  SlotCount.UpToComputed {} -> "UpToComputed"
