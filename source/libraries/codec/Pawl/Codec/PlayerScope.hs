module Pawl.Codec.PlayerScope where

import qualified Pawl.Codec.PlayerRelation as PlayerRelation
import qualified Pawl.Codec.Superlative as Superlative
import qualified Pawl.Codec.TurnRole as TurnRole
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.PlayerScope as PlayerScope

codec :: Codec.Codec PlayerScope.PlayerScope
codec =
  Arm.tagged
    tagOf
    ( PlayerRelation.arms PlayerScope.Related
        <> [ Arm.payload "Superlative" Superlative.codec PlayerScope.Superlative (\x -> case x of PlayerScope.Superlative y -> Just y; _ -> Nothing),
             Arm.payload "InRole" TurnRole.codec PlayerScope.InRole (\x -> case x of PlayerScope.InRole y -> Just y; _ -> Nothing)
           ]
    )

tagOf :: PlayerScope.PlayerScope -> String
tagOf x = case x of
  PlayerScope.Related relation -> PlayerRelation.tag relation
  PlayerScope.Superlative {} -> "Superlative"
  PlayerScope.InRole {} -> "InRole"
