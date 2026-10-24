module Parun.Codec.DamagedParty where

import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.DamagedParty as DamagedParty

codec :: Codec.Codec DamagedParty.DamagedParty
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Related" PlayerRelation.codec DamagedParty.Related (\x -> case x of DamagedParty.Related y -> Just y; _ -> Nothing),
      Arm.nullary "Source" DamagedParty.Source,
      Arm.payload "InSlot" SlotName.codec DamagedParty.InSlot (\x -> case x of DamagedParty.InSlot y -> Just y; _ -> Nothing)
    ]

tagOf :: DamagedParty.DamagedParty -> String
tagOf x = case x of
  DamagedParty.Related {} -> "Related"
  DamagedParty.Source -> "Source"
  DamagedParty.InSlot {} -> "InSlot"
