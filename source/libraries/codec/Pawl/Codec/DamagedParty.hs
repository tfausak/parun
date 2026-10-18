module Pawl.Codec.DamagedParty where

import qualified Pawl.Codec.PlayerRelation as PlayerRelation
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.DamagedParty as DamagedParty

codec :: Codec.Codec DamagedParty.DamagedParty
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Related" PlayerRelation.codec DamagedParty.Related (\x -> case x of DamagedParty.Related y -> Just y; _ -> Nothing),
      Arm.nullary "Source" DamagedParty.Source
    ]

tagOf :: DamagedParty.DamagedParty -> String
tagOf x = case x of
  DamagedParty.Related {} -> "Related"
  DamagedParty.Source -> "Source"
