module Parun.Codec.Facing where

import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.FaceDownState as FaceDownState
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Facing as Facing

codec :: Codec.Codec Facing.Facing
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "FaceUp" Facing.FaceUp,
      Arm.payload "FaceDown" (FaceDownState.codec (GrantedAbility.codec Card.codec)) Facing.FaceDown (\x -> case x of Facing.FaceDown y -> Just y; _ -> Nothing)
    ]

tagOf :: Facing.Facing -> String
tagOf x = case x of
  Facing.FaceUp {} -> "FaceUp"
  Facing.FaceDown {} -> "FaceDown"
