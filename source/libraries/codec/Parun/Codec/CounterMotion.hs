module Parun.Codec.CounterMotion where

import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CounterMotion as CounterMotion

codec :: Codec.Codec CounterMotion.CounterMotion
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Put" PlayerRelation.codec CounterMotion.Put (\x -> case x of CounterMotion.Put y -> Just y; _ -> Nothing),
      Arm.nullary "Removed" CounterMotion.Removed
    ]

tagOf :: CounterMotion.CounterMotion -> String
tagOf x = case x of
  CounterMotion.Put {} -> "Put"
  CounterMotion.Removed {} -> "Removed"
