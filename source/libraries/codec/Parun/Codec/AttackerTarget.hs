module Parun.Codec.AttackerTarget where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AttackerTarget as AttackerTarget

codec :: Codec.Codec AttackerTarget.AttackerTarget
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "AnyTarget" AttackerTarget.AnyTarget,
      Arm.payload "Defending" PlayerRelation.codec AttackerTarget.Defending (\x -> case x of AttackerTarget.Defending y -> Just y; _ -> Nothing),
      Arm.payload "Permanent" (Filter.codec Keyword.codec) AttackerTarget.Permanent (\x -> case x of AttackerTarget.Permanent y -> Just y; _ -> Nothing),
      Arm.nullary "PlayerWithMostLife" AttackerTarget.PlayerWithMostLife
    ]

tagOf :: AttackerTarget.AttackerTarget -> String
tagOf x = case x of
  AttackerTarget.AnyTarget -> "AnyTarget"
  AttackerTarget.Defending {} -> "Defending"
  AttackerTarget.Permanent {} -> "Permanent"
  AttackerTarget.PlayerWithMostLife -> "PlayerWithMostLife"
