module Parun.Codec.Activator where

import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Activator as Activator

codec :: Codec.Codec Activator.Activator
codec =
  Arm.tagged
    tagOf
    (PlayerRelation.arms Activator.Related <> [Arm.nullary "Owner" Activator.Owner])

tagOf :: Activator.Activator -> String
tagOf x = case x of
  Activator.Related relation -> PlayerRelation.tag relation
  Activator.Owner {} -> "Owner"
