module Parun.Codec.AttackLimitScope where

import qualified Parun.Codec.PlayerScope as PlayerScope
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AttackLimitScope as AttackLimitScope

codec :: Codec.Codec AttackLimitScope.AttackLimitScope
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Players" PlayerScope.codec AttackLimitScope.Players (\x -> case x of AttackLimitScope.Players y -> Just y; _ -> Nothing),
      Arm.nullary "Source" AttackLimitScope.Source
    ]

tagOf :: AttackLimitScope.AttackLimitScope -> String
tagOf x = case x of
  AttackLimitScope.Players {} -> "Players"
  AttackLimitScope.Source -> "Source"
