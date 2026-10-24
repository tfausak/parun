module Parun.Codec.AttackedPlayer where

import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AttackedPlayer as AttackedPlayer

codec :: Codec.Codec AttackedPlayer.AttackedPlayer
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Related" PlayerRelation.codec AttackedPlayer.Related (\x -> case x of AttackedPlayer.Related y -> Just y; _ -> Nothing),
      Arm.nullary "Enchanted" AttackedPlayer.Enchanted
    ]

tagOf :: AttackedPlayer.AttackedPlayer -> String
tagOf x = case x of
  AttackedPlayer.Related {} -> "Related"
  AttackedPlayer.Enchanted -> "Enchanted"
