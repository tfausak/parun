module Parun.Codec.TurnScope where

import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.TurnScope as TurnScope

codec :: Codec.Codec TurnScope.TurnScope
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "EachTurn" TurnScope.EachTurn,
      Arm.nullary "ControllersTurn" TurnScope.ControllersTurn,
      Arm.nullary "OpponentsTurn" TurnScope.OpponentsTurn,
      Arm.payload "PlayersTurn" PlayerRef.codec TurnScope.PlayersTurn (\x -> case x of TurnScope.PlayersTurn y -> Just y; _ -> Nothing)
    ]

tagOf :: TurnScope.TurnScope -> String
tagOf x = case x of
  TurnScope.EachTurn -> "EachTurn"
  TurnScope.ControllersTurn -> "ControllersTurn"
  TurnScope.OpponentsTurn -> "OpponentsTurn"
  TurnScope.PlayersTurn {} -> "PlayersTurn"
