module Parun.Codec.PlayerScope where

import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.Superlative as Superlative
import qualified Parun.Codec.TurnRole as TurnRole
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PlayerScope as PlayerScope

codec :: Codec.Codec PlayerScope.PlayerScope
codec =
  Arm.tagged
    tagOf
    ( PlayerRelation.arms PlayerScope.Related
        <> [ Arm.payload "Superlative" Superlative.codec PlayerScope.Superlative (\x -> case x of PlayerScope.Superlative y -> Just y; _ -> Nothing),
             Arm.payload "InRole" TurnRole.codec PlayerScope.InRole (\x -> case x of PlayerScope.InRole y -> Just y; _ -> Nothing),
             Arm.nullary "ChosenPlayer" PlayerScope.ChosenPlayer
           ]
    )

tagOf :: PlayerScope.PlayerScope -> String
tagOf x = case x of
  PlayerScope.Related relation -> PlayerRelation.tag relation
  PlayerScope.Superlative {} -> "Superlative"
  PlayerScope.InRole {} -> "InRole"
  PlayerScope.ChosenPlayer {} -> "ChosenPlayer"
