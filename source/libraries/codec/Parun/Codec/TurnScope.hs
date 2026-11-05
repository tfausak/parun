module Parun.Codec.TurnScope where

import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.TurnScope as TurnScope

codec :: Codec.Codec TurnScope.TurnScope
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "PlayersTurn" PlayerRef.codec TurnScope.PlayersTurn (\(TurnScope.PlayersTurn y) -> Just y)
    ]

tagOf :: TurnScope.TurnScope -> String
tagOf x = case x of
  TurnScope.PlayersTurn {} -> "PlayersTurn"
