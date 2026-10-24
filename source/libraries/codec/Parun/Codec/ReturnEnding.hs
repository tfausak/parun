module Parun.Codec.ReturnEnding where

import qualified Parun.Codec.MonarchWatch as MonarchWatch
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ReturnEnding as ReturnEnding

codec :: Codec.Codec ReturnEnding.ReturnEnding
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "SourceLeaves" ObjectId.codec ReturnEnding.SourceLeaves (\x -> case x of ReturnEnding.SourceLeaves y -> Just y; _ -> Nothing),
      Arm.payload "OpponentCrowned" MonarchWatch.codec ReturnEnding.OpponentCrowned (\x -> case x of ReturnEnding.OpponentCrowned y -> Just y; _ -> Nothing)
    ]

tagOf :: ReturnEnding.ReturnEnding -> String
tagOf x = case x of
  ReturnEnding.SourceLeaves {} -> "SourceLeaves"
  ReturnEnding.OpponentCrowned {} -> "OpponentCrowned"
